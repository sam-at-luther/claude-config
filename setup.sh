#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Setting up claude-config..."

# Ensure ~/.claude directory exists
mkdir -p "$CLAUDE_DIR/skills"

# Helper: symlink a file, backing up if it exists as a regular file
link_file() {
    local src="$1" target="$2" label="$3"
    if [ -L "$target" ]; then
        echo "Updating symlink: $label"
        ln -sf "$src" "$target"
    elif [ -f "$target" ]; then
        echo "WARNING: $label exists as a regular file. Backing up to ${target}.bak"
        cp "$target" "${target}.bak"
        ln -sf "$src" "$target"
    else
        echo "Linking: $label"
        ln -sf "$src" "$target"
    fi
}

# Helper: symlink a directory, backing up if it exists as a regular dir
link_dir() {
    local src="$1" target="$2" label="$3"
    if [ -L "$target" ]; then
        echo "Updating symlink: $label"
        ln -sfn "$src" "$target"
    elif [ -d "$target" ]; then
        echo "WARNING: $label exists as a directory. Backing up to ${target}.bak"
        mv "$target" "${target}.bak"
        ln -sfn "$src" "$target"
    else
        echo "Linking: $label"
        ln -sfn "$src" "$target"
    fi
}

# Symlink global files
link_file "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "~/.claude/CLAUDE.md"
link_file "$SCRIPT_DIR/golang-guidance.md" "$CLAUDE_DIR/golang-guidance.md" "~/.claude/golang-guidance.md"
link_file "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json" "~/.claude/settings.json"

# Symlink agents and commands directories
link_dir "$SCRIPT_DIR/agents" "$CLAUDE_DIR/agents" "~/.claude/agents"
link_dir "$SCRIPT_DIR/commands" "$CLAUDE_DIR/commands" "~/.claude/commands"

# Symlink skills (force-update to point at this repo)
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    link_dir "$skill_dir" "$CLAUDE_DIR/skills/$skill_name" "skills/$skill_name"
done

echo ""
echo "Done. Global config, skills, agents, and commands are now linked."
echo "Run 'git pull' in this repo anytime to pick up updates."
