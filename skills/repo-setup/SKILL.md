---
name: repo-setup
description: "Use this skill to fully onboard a repository for Claude Code. Does a deep scan of the repo's code, docs, issues, PRs, wiki, and CI — then generates a CLAUDE.md and a full set of skills. Run this once when you first start working with a repo. Examples: '/repo-setup', 'set up this repo for claude', 'onboard this repo', 'bootstrap this project'."
---

# Repository Setup

Full onboarding for a repository. Builds deep understanding of the project, generates a CLAUDE.md, and creates tailored skills — everything a new contributor (human or agent) needs to start making correct changes immediately.

Run this once per repo. It is intentionally thorough.

## Step 1: Deep Repository Scan

Before generating anything, build a comprehensive mental model of the project. Run all of the following in parallel using subagents.

### 1a. Codebase Structure (subagent: Explore)

Launch an Explore subagent to map the repo:

- Top-level directory layout and what each directory is for
- Languages and frameworks used (detect from file extensions, configs, imports)
- Build system (Make, npm, cargo, go, gradle, etc.) — read the build files
- Entry points (main files, index files, cmd/ directories, handlers)
- Config files (env, yaml, toml, json) — what's configurable
- Generated vs hand-written code (build/ directories, codegen markers)
- Monorepo structure if applicable (workspaces, packages, modules)

### 1b. Documentation Deep Dive (subagent: general-purpose)

Read ALL available documentation:

```bash
# In-repo docs
find . -maxdepth 3 \( -name 'README*' -o -name 'CONTRIBUTING*' -o -name 'ARCHITECTURE*' \
  -o -name 'DESIGN*' -o -name 'DEVELOPMENT*' -o -name 'SETUP*' -o -name 'INSTALL*' \
  -o -name 'CHANGELOG*' -o -name 'ADR-*' -o -name '*.md' -path '*/docs/*' \
  -o -name '*.md' -path '*/doc/*' \) 2>/dev/null
```

Read each file. Extract:
- Project purpose and domain
- Architecture decisions and rationale (especially ADRs)
- Development setup instructions
- Conventions documented anywhere
- Glossary of domain terms

Also check for a GitHub wiki:
```bash
gh api repos/{owner}/{repo}/pages 2>/dev/null
# Wiki pages (if wiki is enabled)
gh api repos/{owner}/{repo} --jq '.has_wiki'
```

### 1c. Issue & PR Archaeology (subagent: general-purpose)

Analyze the project's issue and PR history to understand what work looks like:

```bash
# Open issues — what's on the backlog?
gh issue list --state open --limit 50 --json number,title,labels,body --jq '.[] | {number, title, labels: [.labels[].name]}'

# Recently closed issues — what gets done?
gh issue list --state closed --limit 30 --json number,title,labels --jq '.[] | {number, title, labels: [.labels[].name]}'

# Recently merged PRs — what do changes look like?
gh pr list --state merged --limit 30 --json number,title,labels,body --jq '.[] | {number, title, labels: [.labels[].name]}'

# Open PRs — what's in flight?
gh pr list --state open --limit 20 --json number,title,labels,headRefName --jq '.[] | {number, title, branch: .headRefName, labels: [.labels[].name]}'

# Labels in use — reveals the team's workflow categories
gh label list --json name,description,color --jq '.[] | {name, description}'

# PR review patterns
gh pr list --state merged --limit 10 --json number,reviews --jq '.[] | {number, reviewers: [.reviews[].author.login]}'
```

Synthesize:
- What categories of work happen most often? (features, bugs, deps, docs, infra)
- What labels does the team use and what do they mean?
- What branch naming conventions are in use?
- What does a typical PR look like? (size, scope, description style)
- Who are the main contributors / reviewers?
- Are there recurring issue patterns that could become skill templates?

### 1d. CI/CD & Quality Infrastructure (subagent: general-purpose)

```bash
# GitHub Actions workflows
ls .github/workflows/ 2>/dev/null

# Read every workflow file
# Also check for:
ls .github/PULL_REQUEST_TEMPLATE* .github/ISSUE_TEMPLATE* .github/CODEOWNERS 2>/dev/null

# Branch protection rules (if you have admin access)
gh api repos/{owner}/{repo}/branches/main/protection 2>/dev/null
```

For each workflow, extract:
- Trigger events (push, PR, schedule, manual)
- What jobs run (build, test, lint, deploy, release)
- Exact test/lint/build commands used
- Required status checks for PRs
- Deploy targets and conditions
- Secrets and environment variables referenced

Also read PR templates and issue templates — these encode the team's expectations.

### 1e. Git History & Conventions (subagent: general-purpose)

```bash
# Commit message style
git log --oneline -50 --format='%s'

# Commit frequency and contributors
git shortlog -sn --no-merges -50

# Tags and versioning scheme
git tag --sort=-v:refname | head -15

# Recent branch activity
git branch -r --sort=-committerdate --format='%(refname:short) %(committerdate:relative)' | head -20

# File churn — what changes most?
git log --oneline -200 --name-only --format='' | sort | uniq -c | sort -rn | head -30
```

Identify:
- Commit message conventions (conventional commits? imperative? prefixes?)
- Release cadence and versioning scheme
- Most active areas of the codebase
- Team size and contribution patterns

### 1f. Existing Claude Code Config (subagent: Explore)

```bash
# Check what already exists
cat CLAUDE.md 2>/dev/null
cat .claude/settings.json 2>/dev/null
ls .claude/skills/ 2>/dev/null
cat .claude/settings.local.json 2>/dev/null
```

Note what's already configured so we don't overwrite or duplicate.

## Step 2: Generate CLAUDE.md

With all the intelligence gathered, run `/init` to generate the initial CLAUDE.md.

**IMPORTANT:** After `/init` creates the file, **enhance it** with the deeper context gathered in Step 1 that `/init` wouldn't know about. Specifically, add or enrich these sections:

### Sections to ensure exist in CLAUDE.md:

**Overview** — One paragraph: what the project is, its domain, and its purpose. Not generic — mention the specific tech, the specific problem it solves.

**Repository Layout** — Every top-level directory and what it contains. For monorepos, describe each package/module.

**Build & Test Commands** — The exact commands, copied from the Makefile / CI workflows. Include:
- Full build
- Run all tests
- Run a single test
- Lint / format
- Generate / codegen steps
- Local dev server (if applicable)

**Architecture** — Key architectural patterns, data flow, important abstractions. Reference ADRs if they exist.

**Conventions** — Everything from commit message style to branch naming to PR size expectations. Source this from the git history analysis, not guesswork.

**Domain Glossary** — If the project has domain-specific terms (found in docs, issue titles, code), list them with one-line definitions. This prevents agents from misunderstanding requirements.

**Common Pitfalls** — Things that break non-obviously. Source from CI configs (what checks catch), CONTRIBUTING.md warnings, and issue patterns (recurring bug categories).

**Skills** — Table mapping each skill to its purpose (populated after Step 3).

## Step 3: Generate Skills

Invoke the `/create-repo-skills` skill. This will:
- Analyze the repo (it will re-read some things — that's fine, it needs its own context)
- Generate `implement`, `verify`, `pr`, and domain-specific skills
- Update CLAUDE.md with the skills table

After `/create-repo-skills` completes, review the generated skills for consistency with the deeper intelligence from Step 1. Enrich them if the Step 1 analysis revealed important conventions or pitfalls that the skill generation missed.

### Additional skills to consider generating (beyond what create-repo-skills produces):

**If the repo has issue templates** → generate a `triage` skill that reads a new issue and applies appropriate labels / priority.

**If the repo has a deploy process** → generate a `deploy` skill with the exact steps.

**If the repo has complex local setup** → generate a `dev-setup` skill with environment bootstrapping.

**If the repo uses feature flags** → generate a `feature-flag` skill for adding/removing flags.

## Step 4: Commit the Configuration

Stage and present the changes for the user to review:

```bash
git add CLAUDE.md .claude/
git status
git diff --cached --stat
```

Print a summary of everything generated and ask the user if they want to commit:

```
--- Repo Setup Complete ---
Repository: <owner/repo>

Generated CLAUDE.md:
  - Overview, layout, build commands, architecture, conventions
  - Domain glossary with <N> terms
  - <N> common pitfalls documented

Generated Skills:
  .claude/skills/implement/SKILL.md   — Core dev loop
  .claude/skills/verify/SKILL.md      — Local CI mirror
  .claude/skills/pr/SKILL.md          — PR workflow
  .claude/skills/<domain>/SKILL.md    — <description>
  ...

Ready to commit. Share these with the team by pushing to the repo.
---
```

## Important Notes

- **Run once per repo.** This is an onboarding operation, not something you repeat. Once the CLAUDE.md and skills exist, they should be maintained incrementally.
- **Don't overwrite existing work.** If CLAUDE.md already exists, read it first and merge — don't replace. If skills already exist, skip or ask the user.
- **Parallel subagents are critical.** Steps 1a-1f should all run as parallel subagents. The repo scan is the slowest part — parallelism cuts it from ~5 minutes to ~1 minute.
- **Quality over speed.** Read the actual files. Don't guess build commands — find them in the Makefile/CI. Don't guess conventions — derive them from the git history.
- **The CLAUDE.md is the source of truth.** Skills reference it. New agents read it first. Invest the most effort here.
- **Commit message conventions matter.** If the repo uses conventional commits, note that in CLAUDE.md so all future agent commits follow the pattern.
