# claude-config

Common Claude Code configuration, skills, and guidance for use across all projects.

## What's Here

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Global instructions — symlink to `~/.claude/CLAUDE.md` |
| `skills/firecrawl/` | Web scraping, search, and research via Firecrawl CLI |
| `skills/find-skills/` | Discover and install skills from the open ecosystem |
| `skills/mars/` | Luther infrastructure tool (Terraform/Ansible/Packer) |
| `SETUP_ENV.md` | Full environment reconstitution guide |
| `setup.sh` | One-command install script |

## Quick Setup

```bash
git clone git@github.com:sam-at-luther/claude-config.git
cd claude-config
./setup.sh
```

This will:
1. Symlink `CLAUDE.md` → `~/.claude/CLAUDE.md` (global Claude Code instructions)
2. Symlink any skills in `skills/` → `~/.claude/skills/`

## Manual Setup

```bash
# Symlink global instructions
ln -sf "$(pwd)/CLAUDE.md" ~/.claude/CLAUDE.md

# Symlink individual skills
ln -sf "$(pwd)/skills/my-skill" ~/.claude/skills/my-skill
```

## Agent Compatibility

This config uses `CLAUDE.md` as the canonical instruction file. For projects that use
other AI agents (Kiro, Cursor, Windsurf), symlink `agent.md` to share the same instructions:

```bash
# In any project repo
ln -sf CLAUDE.md agent.md
```

## Updating

Pull the latest and your symlinks pick up changes automatically:

```bash
cd claude-config && git pull
```

## Lessons

Each project maintains a `tasks/lessons.md` file where Claude records corrections and
patterns. When a lesson proves stable and universal, promote it into this repo's `CLAUDE.md`
so it applies everywhere.
