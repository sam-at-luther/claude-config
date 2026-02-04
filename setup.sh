#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Setting up claude-config..."

# Ensure ~/.claude directory exists
mkdir -p "$CLAUDE_DIR/skills"

# Symlink global CLAUDE.md
if [ -L "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo "Updating existing symlink: ~/.claude/CLAUDE.md"
    ln -sf "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
elif [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo "WARNING: ~/.claude/CLAUDE.md already exists as a regular file."
    echo "  Backing up to ~/.claude/CLAUDE.md.bak"
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
    ln -sf "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
else
    echo "Creating symlink: ~/.claude/CLAUDE.md"
    ln -sf "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
fi

# Symlink skills (force-update to point at this repo)
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    target="$CLAUDE_DIR/skills/$skill_name"
    if [ -L "$target" ]; then
        echo "Updating skill symlink: $skill_name"
        ln -sfn "$skill_dir" "$target"
    elif [ -d "$target" ]; then
        echo "WARNING: $skill_name exists as a directory, backing up to ${target}.bak"
        mv "$target" "${target}.bak"
        ln -sfn "$skill_dir" "$target"
    else
        echo "Linking skill: $skill_name"
        ln -sfn "$skill_dir" "$target"
    fi
done

echo ""
echo "Done. Global CLAUDE.md and skills are now linked."
echo "Run 'git pull' in this repo anytime to pick up updates."
