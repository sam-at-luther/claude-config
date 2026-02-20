# Best Practice Guidelines for Types in Go

This guide outlines the community-accepted best practices for defining, organizing, and using types in Go projects. It focuses on writing idiomatic code that is maintainable, readable, and leverages Go's type system effectively.

## 1. Core Philosophy: Data vs. Behavior

The fundamental rule of Go type design is strictly separating data from behavior.

### Structs are for Data

Structs should hold your data state. They are concrete and rigid.

- **Best Practice:** Keep structs simple. Avoid deep inheritance-like embedding hierarchies.
- **Best Practice:** Struct fields should generally be unrelated to the logic that processes them (logic belongs in methods or functions).

### Embedding (Composition, not Inheritance)

Go uses embedding for composition. It is not inheritance — the outer type does not "become" the inner type.

- **Good uses of embedding:**
  - Composing interfaces: `type ReadWriter interface { io.Reader; io.Writer }`
  - Delegating methods to an inner struct without boilerplate forwarding.
  - Mixing in behavior like `sync.Mutex` for a self-locking struct.
- **Avoid:** Embedding just to access inner fields directly. If you're embedding `*sql.DB` into your service struct so callers can call `.Query()` directly, you're leaking implementation details. Wrap it instead.
- **Rule of thumb:** Embed when the outer type genuinely *is a* specialization. Wrap when it merely *uses* the inner type.

```go
// Good: UserCache IS a cache with extra user-specific methods
type UserCache struct {
    sync.RWMutex
    users map[string]*User
}

// Bad: UserService is NOT a database — it uses one
type UserService struct {
    *sql.DB  // leaks all of sql.DB's methods
}
```

### Interfaces are for Behavior

Interfaces describe what something can do, not what it is.

**The Golden Rule:** "Accept interfaces, return structs."

- **Accept Interfaces:** Functions should ask for the smallest possible interface (behavior) they need. This makes them easy to mock and test.
- **Return Structs:** Functions (especially constructors) should return concrete types (structs or pointers to structs). This allows the consumer to choose how to use the returned value (e.g., wrap it in a different interface).
- **Keep Interfaces Small:** Prefer 1-2 method interfaces. The smaller the interface, the more useful it is. `io.Reader` (one method) is used everywhere; a 10-method interface is almost never satisfied by anything other than the original struct. If you need a larger interface, compose it from smaller ones (e.g., `io.ReadWriter = io.Reader + io.Writer`).
- **Define Interfaces at the Consumer:** Interfaces belong in the package that *uses* them, not the package that *implements* them. The consumer knows what behavior it needs; the implementor just provides methods on a struct.

**Example:**

```go
// Bad: Accepting a concrete type limits flexibility
func SaveUser(u *FileStore, user User) error { ... }

// Good: Accepting an interface allows any storage mechanism (DB, Memory, File)
type Saver interface {
    Save(User) error
}

func SaveUser(s Saver, user User) error { ... }
```

## 2. Project Structure & Organization

### Where to Define Types

- **Co-location:** Define types as close as possible to where they are used.
  - If a struct is used only by a specific handler, define it in that handler's file.
  - If a struct is the core domain model (e.g., User), it belongs in the domain package (often the root or a dedicated internal/domain package).
- **Avoid a types Package:** Never create a package named types, structs, or models just to dump all your structs in one place. This leads to circular dependencies and weak cohesion. Group types by domain responsibility (e.g., package user, package order), not by "kind of code."

### Visibility (Exported vs. Unexported)

- **Export sparingly:** Only export types (UpperCamelCase) that consumers of your package must see.
- **Internal details:** Keep implementation details unexported (lowerCamelCase).
- **Opaque Types:** Sometimes it is useful to export a struct but keep its fields unexported. This forces users to use your constructor or methods, preventing them from putting the object into an invalid state.

## 3. Naming Conventions

- **Short & Concise:** Go favors shorter names. Scanner is better than InputScanner.
- **Interface Naming:**
  - Single method interfaces: Method Name + er (e.g., Reader, Writer, Formatter).
  - Behavioral names: Storer, Recoverer.
- **Getter Methods:** Go does not use get prefixes.
  - Field: `owner` (unexported)
  - Getter: `Owner()` (exported)
  - Setter: `SetOwner()`
- **Package vs. Type Stutter:** Avoid repeating the package name in the type.
  - Bad: `user.UserConfig` (usage: `user.UserConfig`)
  - Good: `user.Config` (usage: `user.Config`)
- **Constructors:** Use `New<Type>()` for the primary constructor. If the package has only one main type, `New()` alone is fine (e.g., `ring.New()`). For multiple constructors, use `New<Type>With<Variant>()` or the functional options pattern.
- **Context Parameter:** Always pass `context.Context` as the first parameter, never store it in a struct. Name it `ctx`.

```go
// Good
func (s *Store) GetUser(ctx context.Context, id string) (*User, error) { ... }

// Bad: context stored in struct
type Store struct {
    ctx context.Context  // never do this
}
```

## 4. Modern Patterns

### Functional Options Pattern

Use this for constructors with many optional parameters. It is superior to "Config structs" because it allows for defaults, validation, and future expansion without breaking the API.

```go
type Server struct {
    port int
    host string
}

// Option defines a function type that modifies the Server
type Option func(*Server)

// WithPort is a closure that returns an Option
func WithPort(port int) Option {
    return func(s *Server) {
        s.port = port
    }
}

func NewServer(opts ...Option) *Server {
    // 1. Set Defaults
    s := &Server{
        port: 8080,
        host: "localhost",
    }

    // 2. Apply Options
    for _, opt := range opts {
        opt(s)
    }

    return s
}

// Usage:
srv := NewServer(WithPort(9000))
```

### Type Alias vs. Type Definition

Know the difference between creating a new type and an alias.

- **Type Definition** (`type MyInt int`): Creates a brand new type. It does not inherit methods of the underlying type. Useful for adding type safety or methods to primitives.
- **Type Alias** (`type MyInt = int`): (Go 1.9+) Just a new name for the same type. Useful only for refactoring (moving types between packages) to maintain compatibility. Avoid using aliases for general logic.

## 5. Safety & "Magic" Tricks

### Compile-Time Interface Check

If you want to ensure a struct implements an interface at compile time (rather than discovering it at runtime), use a blank identifier check.

```go
type Handler interface {
    Handle()
}

type MyHandler struct{}

func (m MyHandler) Handle() {}

// This line fails to compile if MyHandler does not implement Handler.
// It effectively says: "Assign a nil pointer of MyHandler to a variable of type Handler"
var _ Handler = (*MyHandler)(nil)
```

### Make Zero Values Useful

Design your structs so they are ready to use without explicit initialization. This is a core Go philosophy (e.g., sync.Mutex, bytes.Buffer).

- **Bad:** requiring a user to call Init() before using the struct.
- **Good:** Checks inside methods handle the zero state.

```go
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Inc() {
    // sync.Mutex is ready to use immediately (unlocked state is 0)
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++
}
```

## 6. Receivers: Value vs. Pointer

When defining methods on your types, choose the receiver carefully.

| Scenario | Recommendation | Reason |
|----------|---------------|--------|
| Modifying state | Pointer (`s *MyStruct`) | Essential to mutate the original struct. |
| Large Structs | Pointer (`s *MyStruct`) | Avoids copying large amounts of memory. |
| Small Structs (primitive-like) | Value (`s MyStruct`) | Safer, immutable semantics. |
| Concurrency/Sync | Pointer (`s *MyStruct`) | CRITICAL: Never copy a struct containing a Mutex. |
| Consistency | Mixed | Try not to mix receiver types on a single struct. If one method needs a pointer, use pointers for all. |

## 7. Anti-Patterns to Avoid

- **Interface Pollution:** Don't define interfaces before you need them. Defining an interface for every struct "just in case" leads to unnecessary abstraction.
- **Exported Fields in Unexported Structs:** This is confusing. If the struct is private (type config struct), its fields generally shouldn't be exported unless used for something like JSON unmarshaling where the struct is passed to a public function.
- **Returning Interfaces:** As mentioned in section 1, avoid returning interfaces from functions. It forces the user to use that specific abstraction and hides the underlying data structure, making it harder to extend later.

## 8. Named vs. Anonymous Types

Go allows you to use anonymous types (like `map[string]int`, `[]string`, or `struct{ Name string }`) or define named types (type `UserMap map[string]int`).

### When to Use Named Types

- **Public APIs:** Always use named types for function signatures in your public API. It makes documentation clearer and allows you to add documentation comments to the type itself.
- **Attaching Methods:** You can only attach methods to named types. If you need a helper function like `func (m UserMap) Merge(other UserMap)`, you must name the type.
- **Domain Clarity:** If `map[string]int` actually represents a "Inventory", name it `type Inventory map[string]int`. It adds semantic meaning to your code.

### When to Use Anonymous Types

- **Simple Collections:** If a map or slice is just a generic container (e.g., a simple counter inside a function), `map[string]int` is perfectly idiomatic and preferred over creating a new type.
- **Table-Driven Tests:** Anonymous structs are the standard for table-driven tests.

```go
tests := []struct {
    name  string
    input int
    want  int
}{ ... }
```

- **One-off JSON Parsing:** If you only need to read a small part of a JSON response and never use the structure again, define it inline.

```go
var data struct {
    Token string `json:"token"`
}
json.Unmarshal(bytes, &data)
```

## 9. Error Handling

Errors are values in Go. The `error` type is a one-method interface (`Error() string`), and idiomatic error handling is central to writing good Go.

### Always Check Errors

Every function that returns an error must have that error checked. Never silently discard errors.

```go
// Good: error is checked
f, err := os.Open(path)
if err != nil {
    return fmt.Errorf("opening %s: %w", path, err)
}

// Bad: error is silently discarded
f, _ := os.Open(path)
```

The only acceptable exception is when a function's error is truly inconsequential (e.g., `fmt.Fprintf` to an `http.ResponseWriter` during cleanup where the connection is already closing). In those cases, assign to `_` and add a comment explaining why.

### Wrapping Errors

Use `fmt.Errorf` with `%w` to add context while preserving the original error for inspection.

```go
// Good: wraps with context, caller can unwrap
if err := db.Query(q); err != nil {
    return fmt.Errorf("fetching user %s: %w", id, err)
}

// Bad: destroys the original error
return fmt.Errorf("fetching user %s: %s", id, err.Error())
```

### Checking Errors: Use `errors.Is` and `errors.As`, Never String Matching

Always use `errors.Is` and `errors.As` to inspect errors. **Never** check errors by matching against their `.Error()` string — error messages are not part of the API contract, can change without notice, and break with wrapping.

```go
// Good: uses errors.Is for sentinel errors
if errors.Is(err, os.ErrNotExist) {
    // handle missing file
}

// Good: uses errors.As for typed errors
var ve *ValidationError
if errors.As(err, &ve) {
    log.Printf("bad field: %s", ve.Field)
}

// Bad: fragile string matching — breaks if message changes or error is wrapped
if strings.Contains(err.Error(), "not found") {
    // this is wrong
}

// Bad: direct equality on error message
if err.Error() == "connection refused" {
    // this is wrong
}
```

### Sentinel Errors vs. Error Types

- **Sentinel errors** (`var ErrNotFound = errors.New("not found")`): Use for simple, fixed conditions callers need to check. Check with `errors.Is(err, ErrNotFound)`.
- **Custom error types** (`type ValidationError struct{...}`): Use when callers need to extract structured data from the error. Check with `errors.As(err, &target)`.
- **Prefer sentinel errors** for most cases. Only create a custom type when you need to carry extra data (field name, code, etc.).

```go
// Sentinel — simple condition
var ErrNotFound = errors.New("not found")

// Custom type — carries structured data
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed on %s: %s", e.Field, e.Message)
}

// Checking
if errors.Is(err, ErrNotFound) { ... }

var ve *ValidationError
if errors.As(err, &ve) {
    log.Printf("bad field: %s", ve.Field)
}
```

### Error Naming

- Sentinel errors: `Err` prefix (`ErrNotFound`, `ErrTimeout`).
- Error types: `Error` suffix (`ValidationError`, `TimeoutError`).
- Never name an error variable `err` at package scope — `err` is reserved for local use.

## 10. Enums with `const` + `iota`

Go has no enum keyword. Use typed constants with `iota` for type-safe enumerations.

```go
type Status int

const (
    StatusPending  Status = iota // 0
    StatusActive                 // 1
    StatusInactive               // 2
)
```

- **Always use a named type** (not bare `int`) so the compiler catches misuse.
- **Implement `String()`** for human-readable output. Use `go generate` with `stringer` for large enums.
- **Start iota at 0** unless there's a reason not to. If zero is "unknown/invalid", make that explicit:

```go
const (
    StatusUnknown Status = iota // zero value = unknown, catches uninitialized vars
    StatusPending
    StatusActive
)
```

- **String enums** — when you need string values (e.g., for JSON, DB), use typed string constants instead of iota:

```go
type Role string

const (
    RoleAdmin  Role = "admin"
    RoleEditor Role = "editor"
    RoleViewer Role = "viewer"
)
```

## 11. Generics (Go 1.18+)

Use generics to eliminate duplicated logic across types, not as a replacement for interfaces.

### When to Use Generics

- **Data structures:** Slices, maps, trees, queues that work with any type.
- **Utility functions:** `Map`, `Filter`, `Contains`, `Keys` that operate on generic collections.
- **Type-safe results:** `Result[T]`, `Optional[T]` wrappers.

### When NOT to Use Generics

- **When an interface works fine:** If the behavior is what matters (not the specific type), use an interface. `io.Reader` does not need generics.
- **When there's only one type:** Don't add a type parameter for hypothetical future types. Wait until you actually need it.

```go
// Good use: generic utility that eliminates duplication
func Map[T, U any](s []T, f func(T) U) []U {
    result := make([]U, len(s))
    for i, v := range s {
        result[i] = f(v)
    }
    return result
}

// Bad use: generic for no reason (only ever used with string)
func ParseName[T ~string](input T) T { ... }  // just use string
```

### Constraints

- Use `any` for unconstrained type parameters.
- Use `comparable` when you need `==` / map keys.
- Define custom constraints for numeric or other type sets:

```go
type Number interface {
    ~int | ~int64 | ~float64
}

func Sum[T Number](values []T) T {
    var total T
    for _, v := range values {
        total += v
    }
    return total
}
```

## 12. Testing with Testify

Use the `github.com/stretchr/testify` package to simplify test assertions and reduce boilerplate. Testify provides clear failure messages, reduces `if`/`t.Errorf` noise, and makes test intent more obvious.

### Core Packages

- **`assert`** — non-fatal assertions (test continues on failure, like `t.Errorf`)
- **`require`** — fatal assertions (test stops on failure, like `t.Fatalf`)
- Use `require` for preconditions and setup validation. Use `assert` for the assertions under test.

### Common Assertions

```go
import (
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestExample(t *testing.T) {
    // Equality
    assert.Equal(t, expected, actual)
    assert.NotEqual(t, a, b)

    // Nil / not nil
    assert.Nil(t, err)
    assert.NotNil(t, result)

    // Errors
    require.NoError(t, err)                      // fatal if err != nil
    assert.Error(t, err)                          // asserts err != nil
    assert.ErrorIs(t, err, os.ErrNotExist)        // wraps errors.Is
    assert.ErrorAs(t, err, &target)               // wraps errors.As
    assert.ErrorContains(t, err, "partial msg")   // for substring checks on error messages

    // Boolean
    assert.True(t, condition)
    assert.False(t, condition)

    // Collections
    assert.Len(t, slice, 5)
    assert.Contains(t, slice, element)
    assert.Empty(t, slice)
    assert.ElementsMatch(t, expected, actual)     // order-independent

    // Strings
    assert.Contains(t, str, "substring")
    assert.Regexp(t, `pattern`, str)

    // Panics
    assert.Panics(t, func() { riskyCode() })
    assert.NotPanics(t, func() { safeCode() })
}
```

### When to Use Testify vs. Plain Go

- **Use Testify** for most assertions — it produces clearer diffs and failure messages than manual `if`/`t.Errorf`.
- **Use plain Go** for complex conditional logic in tests where an assertion helper would obscure intent, or in packages that must avoid external dependencies (e.g., stdlib-style libraries).
- **Table-driven tests** pair well with Testify — use `assert` inside the loop body for concise, readable assertions.

```go
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        got, err := Process(tt.input)
        require.NoError(t, err)
        assert.Equal(t, tt.want, got)
    })
}
```
