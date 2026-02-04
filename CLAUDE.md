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
| `firecrawl` | Web scraping, search, and research via Firecrawl CLI. Use for any web/URL task. Replaces WebFetch/WebSearch. |
| `find-skills` | Discover and install new agent skills from the open ecosystem (`npx skills find`). |
| `mars` | Luther infrastructure tool wrapping Terraform, Ansible, and Packer with environment management. |

**Project-specific skills** (not bundled here — live in their own repos):
- `reddit` — Daily Reddit engagement workflow (lives in `iamsamwood/bd`)

## Agent Compatibility (agent.md / CLAUDE.md)

- When a project uses `agent.md` (e.g., for Kiro, Cursor, Windsurf, or other AI tools), symlink it to `CLAUDE.md` so all agents share the same instructions: `ln -sf CLAUDE.md agent.md` (or vice versa)
- If a project already has an `agent.md` but no `CLAUDE.md`, create the symlink: `ln -sf agent.md CLAUDE.md`
- If a project already has a `CLAUDE.md` but no `agent.md`, create the symlink: `ln -sf CLAUDE.md agent.md`
- Keep one canonical file and symlink the other — never maintain two copies
- Prefer `CLAUDE.md` as the canonical file when starting fresh
