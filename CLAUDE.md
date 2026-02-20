# Global Claude Code Instructions

## Workflow Orchestration

- Enter plan mode for any non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use subagents liberally for research, exploration, and parallel analysis
- One task per subagent for focused execution
- Break work into small, digestible components/tasks with corresponding tests

## Git Workflow

- **NEVER** push directly to the main/production branch
- Always create a feature branch off the main branch before starting work
- Use descriptive branch names: `feature/`, `fix/`, `refactor/` prefixes
- Create a PR targeting the main branch when work is complete
- Before creating a PR, check that all GitHub Actions CI checks pass (`gh pr checks` or `gh run list`)
- If CI checks fail, fix the failures before requesting review
- Keep PRs focused — one logical change per PR

## Test-Driven Approach

- When possible, write a small unit test first that captures the expected behavior
- Confirm the code passes the test before moving on
- Run the full test suite before considering work complete
- If a bug is reported, write a failing test that reproduces it, then fix the code

## Verification

- Never mark a task complete without proving it works
- Run tests, check logs, demonstrate correctness
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"

## Code Quality

- For non-trivial changes, pause and ask "is there a more elegant way?"
- If a fix feels hacky, implement the elegant solution
- Skip this for simple, obvious fixes — don't over-engineer
- Find root causes. No temporary fixes. Senior developer standards.
- Changes should only touch what's necessary. Avoid introducing bugs.

## Temporary Files

When you need scratch space for temporary files, create a `.tmp/` directory in the project root and use that. Add `.tmp/` to the project's `.gitignore` if it isn't already.

## Self-Improvement Loop

- After ANY correction from the user, update `tasks/lessons.md` in the project root with the pattern
- Write rules for yourself that prevent the same mistake from recurring
- Review lessons at session start for the relevant project
- Periodically assess whether a lesson should be promoted into the project's `CLAUDE.md` or into a skill
- Format each lesson as: `**[date] Category:** What went wrong → What to do instead`

## Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding.
- Point at logs, errors, failing tests — then resolve them
- Go fix failing CI tests without being told how
- Zero context switching required from the user

## Skills

The following skills are bundled in this config and installed globally via `setup.sh`:

| Skill | Purpose |
|-------|---------|
| `create-repo-skills` | Generate Claude Code skills for any repository from its structure, CI, and conventions. |
| `email` | View, draft, and send emails using the `zele` CLI (Gmail). |
| `firecrawl` | Web scraping, search, and research via Firecrawl CLI. Use for any web/URL task. |
| `find-skills` | Discover and install new agent skills from the open ecosystem (`npx skills find`). |
| `golang-guidance` | Load Go best practices for idiomatic types, errors, generics, and testing. |
| `grind` | Automatically process `agent-ready` GitHub issues: claim → implement → PR. Loops for a duration. |
| `mars` | Luther infrastructure tool wrapping Terraform, Ansible, and Packer with environment management. |
| `pr` | Create PR with local tests, security review, and QA professor on test quality. |
| `release` | Deploy to production via Vercel/MCP server. Tags, monitors, verifies health. |
| `repo-setup` | Full repository onboarding: deep scan → CLAUDE.md → tailored skills. Run once per repo. |

**Also bundled:**
- `agents/qa-professor.md` — QA professor agent for test quality review
- `commands/dailire-mode-analysis.md` — Run 7 parallel failure mode analyses
- `golang-guidance.md` — Standalone Go best practices reference (18KB)
- `settings.json` — Default permissions, plugins, and status line config

**Project-specific skills** (not bundled here — live in their own repos):
- `reddit` — Daily Reddit engagement workflow (lives in `iamsamwood/bd`)

## Luther Dev Tooling

These tools are required for working with Luther infrastructure. See [SETUP_ENV.md](SETUP_ENV.md) for full install instructions.

| Tool | Install | Purpose |
|------|---------|---------|
| `speculate` | `go install github.com/akerl/speculate/v2@latest` | AWS role assumption with MFA |
| `aws-cred-setup` | `luthersystems/aws-cred-setup` | Configure AWS MFA credentials |
| `luther-shell-helpers` | `luthersystems/luther-shell-helpers` | `aws_login`, `aws_jump`, `credcopy/credpaste`, `kns` |
| `mars` | `luthersystems/mars` | Terraform/Ansible/Packer in Docker |
| `switch_accounts.sh` | `luthersystems/shell-scripts` | GitHub account switching (`luther`/`toko`) |
| `firecrawl` | `npm install -g firecrawl-cli` | Web scraping and search |
| `mosh` + `tmux` | brew/apt | Persistent VPN shell sessions |
| `tailscale` | tailscale.com | VPN mesh network (`vpn` alias) |

**Key shell functions** (from `luther-shell-helpers`):
- `aws_login <role>` — MFA-secured AWS session (default role: `dev`)
- `aws_jump <account> <role>` — Assume role in another account (uses `~/.aws/accounts` map)
- `aws_console <account>` — Open AWS console in browser for an account
- `credcopy` / `credpaste` — Copy/paste AWS creds via clipboard
- `credhop` / `creddrop` — Stack-based role switching
- `kns` / `setkns` — Kubectl with namespace management
- `vpn` — `mosh luther-vpn -- tmux new-session -A -s main`

## CLI Tools Available

Modern Rust/Go replacements are installed. Prefer these over legacy equivalents:

| Use this | Instead of | Notes |
|----------|-----------|-------|
| `rg` (ripgrep) | `grep` | 10-100x faster, respects `.gitignore` |
| `fd` | `find` | Simpler syntax: `fd '\.go$'` |
| `bat` | `cat` | Syntax highlighting, line numbers |
| `eza` | `ls` | Git status, tree view (`eza --tree`) |
| `delta` | `diff` | Syntax-highlighted git diffs (configured as git pager) |
| `sd` | `sed` | Simpler: `sd 'from' 'to' file` |
| `dust` | `du` | Visual disk usage tree |
| `fzf` | — | Fuzzy finder (`Ctrl+R` history, `Ctrl+T` files) |
| `zoxide` | `cd` | Frecency-based: `z proj` jumps to project dir |
| `lazygit` | — | Terminal UI for git |
| `lazydocker` | — | Terminal UI for Docker |
| `jq` / `yq` | — | JSON / YAML processing |
| `tree` | — | Directory tree view |

**Kubernetes helpers** (from `luther-shell-helpers`):
- `setkns <namespace>` — Set default kubectl namespace
- `kns` — Show current namespace
- `kns <command>` — Run kubectl with namespace preset (e.g., `kns get pods`)

## Agent Compatibility (agent.md / CLAUDE.md)

- When a project uses `agent.md` (e.g., for Kiro, Cursor, Windsurf, or other AI tools), symlink it to `CLAUDE.md` so all agents share the same instructions: `ln -sf CLAUDE.md agent.md` (or vice versa)
- If a project already has an `agent.md` but no `CLAUDE.md`, create the symlink: `ln -sf agent.md CLAUDE.md`
- If a project already has a `CLAUDE.md` but no `agent.md`, create the symlink: `ln -sf CLAUDE.md agent.md`
- Keep one canonical file and symlink the other — never maintain two copies
- Prefer `CLAUDE.md` as the canonical file when starting fresh
