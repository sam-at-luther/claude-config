---
name: create-repo-skills
description: "Use this skill when the user wants to generate Claude Code skills for a repository. Analyzes the repo's structure, recent commits, CI/CD, and conventions, then generates a set of skills that encode the standard operating procedures covering 90% of routine work. Examples: '/create-repo-skills', 'generate skills for this repo', 'bootstrap claude skills', 'set up skills for new contributors'."
---

# Create Repo Skills

Analyze the current repository and generate a tailored set of Claude Code skills that encode its standard operating procedures. The goal: a new contributor (human or agent) can use these skills to make correct, convention-following changes without tribal knowledge.

## Philosophy

Skills should be:
- **Prescriptive, not descriptive** — exact commands in exact order, not explanations of concepts
- **Composable** — lower-level skills are referenced by higher-level ones (`implement` → `verify` → `pr`)
- **Complete** — include every step a senior contributor would follow, including the ones "everyone just knows"
- **Minimal** — one SKILL.md per skill, no supporting code unless truly necessary

## Step 1: Gather Repository Intelligence

Run ALL of the following in parallel using subagents or parallel tool calls. Collect the raw data — analysis happens in Step 2.

### 1a. Structure & Build System

```bash
# Repo identity
gh repo view --json nameWithOwner,defaultBranchRef,description --jq '.'

# Top-level structure
ls -la
find . -maxdepth 2 -name 'Makefile' -o -name 'package.json' -o -name 'Cargo.toml' \
  -o -name 'go.mod' -o -name 'pyproject.toml' -o -name 'build.gradle' \
  -o -name 'CMakeLists.txt' -o -name 'Dockerfile' -o -name 'docker-compose*.yml' \
  -o -name 'Taskfile.yml' -o -name 'justfile' 2>/dev/null

# Build targets (if Makefile exists)
make -pqr 2>/dev/null | grep -E '^[a-zA-Z].*:' | grep -v '^\.' | head -40
```

Read the primary build file (Makefile, package.json scripts, etc.) to understand the build commands.

### 1b. Recent Commit Patterns

```bash
# Last 100 commit subjects — reveals what kinds of changes are routine
git log --oneline -100 --format='%s'

# Commit frequency by file path prefix — reveals which areas get the most churn
git log --oneline -200 --name-only --format='' | sort | uniq -c | sort -rn | head -30

# Branch naming conventions
git branch -r --format='%(refname:short)' | head -30

# PR titles (last 30) — reveals the team's vocabulary and change categories
gh pr list --state merged --limit 30 --json title --jq '.[].title'
```

### 1c. CI/CD & Quality Gates

```bash
# GitHub Actions workflows
ls .github/workflows/ 2>/dev/null

# Read each workflow file to understand what CI checks
# Look for: test commands, lint commands, build commands, deploy triggers
```

Read every workflow YAML file. Extract the exact test, lint, build, and deploy commands.

### 1d. Existing Documentation & Skills

```bash
# Existing Claude Code configuration
cat CLAUDE.md 2>/dev/null
ls .claude/skills/ 2>/dev/null
cat .claude/settings.json 2>/dev/null
```

Read CLAUDE.md, README.md, CONTRIBUTING.md, and any existing skills.

### 1e. Test & Lint Infrastructure

```bash
# Test configuration
find . -maxdepth 3 -name '*.test.*' -o -name '*_test.*' -o -name 'test_*' \
  -o -name 'conftest.py' -o -name 'jest.config*' -o -name 'vitest.config*' \
  -o -name '.eslintrc*' -o -name 'eslint.config*' -o -name '.prettierrc*' \
  -o -name 'golangci-lint*' -o -name '.golangci.yml' -o -name 'rustfmt.toml' \
  -o -name 'clippy.toml' -o -name 'ruff.toml' -o -name 'mypy.ini' \
  -o -name 'tox.ini' -o -name 'setup.cfg' 2>/dev/null | head -20

# Test commands from package manager
# (already captured in build system step)
```

### 1f. Release & Deploy Process

```bash
# Tags and versioning scheme
git tag --sort=-v:refname | head -10

# Release assets / changelog
ls CHANGELOG* CHANGES* RELEASES* 2>/dev/null
gh release list --limit 5 2>/dev/null
```

## Step 2: Analyze & Identify SOPs

With the gathered data, identify the following. Think carefully — these become skills.

### Core Development Loop

Every repo has a variant of: **edit → format → lint → build → test**. Identify each step's exact commands. This becomes the `implement` skill.

Questions to answer:
- What's the build command? (`make`, `npm run build`, `cargo build`, `go build ./...`)
- What's the test command? Scoped vs full suite?
- What's the lint/format command? Is formatting enforced?
- Are there generated files that need regeneration after edits? (`make generate`, `go generate`, `npm run codegen`)
- What are the common pitfalls that break builds? (captured from CI failures, CLAUDE.md warnings)

### Quality Verification

What does CI run? This becomes the `verify` skill — a local mirror of CI so you never push broken code.

### Shipping Flow

How do changes get from branch to merged PR? This becomes the `pr` skill. Capture:
- Branch naming convention (from `git branch -r` data)
- PR title convention (from merged PR titles)
- Required checks before push
- PR template if one exists (`.github/PULL_REQUEST_TEMPLATE.md`)

### Issue-to-PR Lifecycle

If the repo uses GitHub issues, generate a `pickup-issue` skill that chains: read issue → branch → implement → verify → PR.

### Domain-Specific Workflows

From the commit history and repo structure, identify 1-3 specialized workflows that cover the most common types of changes. Examples:
- A data pipeline repo might need a `add-pipeline` skill
- A web app might need a `add-component` or `add-api-endpoint` skill
- A Terraform repo might need a `add-module` skill
- A library might need a `add-feature` + `release` skill
- A monorepo might need per-package skills

Look at the commit subjects for the most frequent verbs/patterns to identify these.

### Release Process

If the repo has tags/releases, generate a `release` skill documenting the exact process.

## Step 3: Generate the Skills

Create skills in `.claude/skills/` in the current repository. Follow this standard set, skipping any that don't apply:

### Always Generate (Core Three)

| Skill | Purpose | Key Content |
|-------|---------|-------------|
| `implement` | Foundation for any code change | Edit → format → lint → build → test loop with exact commands |
| `verify` | Local CI mirror | Every check CI runs, in order, with exact commands |
| `pr` | Ship changes | Verify → push → create PR with repo's conventions |

### Generate If Applicable

| Skill | When | Purpose |
|-------|------|---------|
| `pickup-issue` | Repo uses GitHub issues | Full lifecycle: issue → branch → implement → verify → PR |
| `release` | Repo has tags/releases | Tag, push, monitor pipeline |
| `audit` | Repo has security-sensitive code or complex codebase | Structured multi-category review |
| 1-3 domain skills | Identified from commit patterns | Specialized workflows for the repo's most common change types |

### Skill Template

Each generated SKILL.md should follow this structure:

```markdown
---
name: <skill-name>
description: "<When to use this skill. Include trigger phrases and examples.>"
---

# <Skill Title>

<One-line purpose statement.>

## Workflow

### 1. <Step Name>
<Exact commands with inline comments explaining project-specific nuances.>

### 2. <Step Name>
...

## Key Reminders
- <Project-specific pitfall or convention that isn't obvious>
- <Another one>

## Checklist
- [ ] <Verification item>
- [ ] <Another>
```

### Writing Guidelines

- **Use exact commands** from the repo's actual build system — never generic placeholders
- **Include project-specific pitfalls** discovered from CLAUDE.md, CI configs, and commit messages
- **Reference other skills by name** when composing workflows ("Run the `verify` skill first")
- **Include the specific test scoping syntax** for the project (e.g., `go test ./path/...`, `npm test -- --testPathPattern`)
- **Capture generated file requirements** — these are the #1 source of "it works locally but CI fails"
- **Note any required environment setup** (env vars, Docker, local services)
- **Keep each skill under 200 lines** — concise and actionable, not documentation

## Step 4: Update CLAUDE.md

After generating skills, update the project's `CLAUDE.md` to include a skills table (like the substrate repo pattern):

```markdown
## Skills

| Skill | Purpose |
|-------|---------|
| `implement` | Foundation for any code change — edit, lint, build, test |
| `verify` | Local CI gate — run all checks before pushing |
| `pr` | Ship changes — verify, push, create PR |
| ... | ... |
```

If CLAUDE.md doesn't exist yet, create a minimal one with the skills table plus basic project context. If it already exists, append the skills table to the existing content.

## Step 5: Summary

Print a summary of what was generated:

```
--- Skills Generated ---
Repository: <owner/repo>

Created:
  .claude/skills/implement/SKILL.md    — Core dev loop
  .claude/skills/verify/SKILL.md       — Local CI mirror
  .claude/skills/pr/SKILL.md           — PR workflow
  .claude/skills/<domain>/SKILL.md     — <description>
  ...

Updated:
  CLAUDE.md — Added skills table

Commit these files to share skills with the team.
---
```

## Important Notes

- **Do NOT overwrite existing skills.** If `.claude/skills/<name>/SKILL.md` already exists, read it first and either skip or ask the user if they want to regenerate it.
- **Do NOT generate generic skills.** Every command in every skill must be verified against the actual repo. If you can't determine the exact command, leave a `TODO: verify` comment.
- **Composability is key.** Higher-level skills should reference lower-level ones, not duplicate their steps.
- **Test the commands.** After generating skills, run a quick sanity check — do the build and test commands actually work? If not, fix the skills before finishing.
- **Respect existing CLAUDE.md.** Merge into it, don't replace it.
