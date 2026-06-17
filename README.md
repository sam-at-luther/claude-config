# claude-config

Common Claude Code configuration, skills, and guidance for use across all projects.

## What's Here

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Global instructions — symlink to `~/.claude/CLAUDE.md` |
| `golang-guidance.md` | Go best practices reference (types, errors, generics, testing) |
| `settings.json` | Default permissions, plugins, and status line config |
| `agents/qa-professor.md` | QA professor agent for test quality review |
| `skills/create-repo-skills/` | Generate Claude Code skills for any repository |
| `skills/golang-guidance/` | Load Go best practices into a session |
| `skills/mars/` | Luther infrastructure tool (Terraform/Ansible/Packer) |
| `skills/pr/` | Create PR with tests, security review, and QA professor |
| `skills/release/` | Deploy to production (Vercel + MCP server) |
| `skills/repo-setup/` | Full repo onboarding: scan → CLAUDE.md → skills |
| `SETUP_ENV.md` | Full environment reconstitution guide |
| `setup.sh` | One-command install script |

## Use as a plugin (Claude Code on the web)

This repo is also a Claude Code **plugin marketplace** (`.claude-plugin/`), so the same
skills/agents work in cloud sessions where local symlinks don't reach. A consuming repo
enables it in its `.claude/settings.json`:

```jsonc
"extraKnownMarketplaces": {
  "claude-config": { "source": { "source": "github", "repo": "sam-at-luther/claude-config" } }
},
"enabledPlugins": { "claude-config@claude-config": true }
```

Because this repo is **private**, Claude Code on the web needs a read-only GitHub token to
fetch it — set a fine-grained PAT scoped to `sam-at-luther/claude-config` (contents: read)
as a `GH_TOKEN` environment variable in the cloud environment. Locally you keep using the
symlinks below; the plugin namespaces its skills (`claude-config:pr`) so they coexist.

## Quick Setup

```bash
git clone git@github.com:sam-at-luther/claude-config.git
cd claude-config
./setup.sh
```

This will:
1. Symlink `CLAUDE.md` → `~/.claude/CLAUDE.md` (global Claude Code instructions)
2. Symlink `golang-guidance.md` → `~/.claude/golang-guidance.md`
3. Symlink `settings.json` → `~/.claude/settings.json`
4. Symlink `agents/` → `~/.claude/agents/`
5. Symlink `commands/` → `~/.claude/commands/`
6. Symlink all skills in `skills/` → `~/.claude/skills/`

## Manual Setup

```bash
# Symlink global instructions
ln -sf "$(pwd)/CLAUDE.md" ~/.claude/CLAUDE.md

# Symlink standalone files
ln -sf "$(pwd)/golang-guidance.md" ~/.claude/golang-guidance.md
ln -sf "$(pwd)/settings.json" ~/.claude/settings.json

# Symlink agents and commands
ln -sfn "$(pwd)/agents" ~/.claude/agents
ln -sfn "$(pwd)/commands" ~/.claude/commands

# Symlink individual skills
ln -sfn "$(pwd)/skills/my-skill" ~/.claude/skills/my-skill
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
