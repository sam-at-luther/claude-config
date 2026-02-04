# Environment Setup

Steps to reconstitute a full Luther dev environment on a new machine (macOS, Linux VPS, or VM).

## 1. Prerequisites

```bash
# macOS
brew install go node nvm jq mosh docker git gh tailscale

# Linux (Debian/Ubuntu)
sudo apt-get install -y jq mosh tmux git docker.io
# Install go, node/nvm, gh CLI separately per their docs
```

## 2. Directory Structure

```bash
mkdir -p ~/work/src/github.com/luthersystems
mkdir -p ~/work/src/github.com/iamsamwood
mkdir -p ~/work/src/github.com/sam-at-luther
```

## 3. Clone Core Repos

```bash
cd ~/work/src/github.com/luthersystems

# Shell helpers (provides aws_login, aws_jump, credhop, creddrop, credcopy, credpaste, kns)
git clone git@github.com:luthersystems/luther-shell-helpers.git

# AWS credential setup (MFA configuration)
git clone git@github.com:luthersystems/aws-cred-setup.git

# Shell scripts (GitHub account switching: luther/toko)
git clone git@github.com:luthersystems/shell-scripts.git

cd ~/work/src/github.com/sam-at-luther

# This repo — Claude config, skills, and this guide
git clone git@github.com:sam-at-luther/claude-config.git
```

## 4. Install Go Tools

```bash
# speculate — AWS role assumption with MFA
go install github.com/akerl/speculate/v2@latest

# aws-cred-setup — MFA credential configuration
cd ~/work/src/github.com/luthersystems/aws-cred-setup
go install .
```

## 5. AWS Configuration

### Account Map

Create `~/.aws/accounts` with Luther AWS account aliases:

```
# ALIAS           ACCOUNT_ID
billing           <REPLACE>
root              <REPLACE>
platform-prod     <REPLACE>
platform-test     <REPLACE>
```

### MFA Setup

```bash
# Follow aws-cred-setup instructions
aws-cred-setup
```

This configures `~/.aws/credentials` and `~/.aws/config` with MFA-enabled profiles.

### Usage

```bash
aws_login admin        # Login with MFA, assume admin role
aws_jump <account> admin  # Jump to another account
aws_console <account>  # Open account in browser
credcopy               # Copy AWS creds to clipboard (macOS)
credpaste              # Paste AWS creds from clipboard
creddrop               # Return to previous session (stack-based)
```

## 6. Shell Configuration

Add to `~/.zshrc` (or `~/.bashrc`):

```bash
# PATH
typeset -Ux path
path=(~/bin ~/go/bin /usr/local/sbin $path[@])

# Luther shell helpers (aws_login, aws_jump, kns, etc.)
source ~/work/src/github.com/luthersystems/luther-shell-helpers/all.sh

# GitHub account switching (luther/toko functions)
source ~/work/src/github.com/luthersystems/shell-scripts/gh/switch_accounts.sh

# VPN to dev box
alias vpn='mosh luther-vpn -- tmux new-session -A -s main'
alias vpn-ssh='tailscale ssh ec2-user@luther-vpn -t "tmux new-session -A -s main"'

# AWS shortcuts
alias aws_admin='aws_login admin'

# Go private modules
export GOPRIVATE="github.com/luthersystems/chainidentifier,github.com/luthersystems/license"

# 1Password SSH agent (macOS)
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# Docker helpers
function killall-docker() {
  docker ps | egrep -v gomodfix | tail -n +2 | egrep -o '^[0-9a-f]+' | xargs docker kill
  docker volume rm $(docker volume ls -q)
}

# Misc
alias strip_colors="gsed 's/\x1b\[[0-9;]*m//g'"
```

### VPN Details

- `vpn` — Uses `mosh` for persistent connection to `luther-vpn` (Tailscale hostname), attaches to tmux session `main`
- `vpn-ssh` — Fallback using `tailscale ssh` directly (no mosh)
- Requires Tailscale to be configured and `luther-vpn` to be reachable

### GitHub Account Switching

```bash
luther    # Switch to sam-at-luther (luthersystems)
toko      # Switch to sam-at-toko (toko.network)
```

This sets `git config --global user.name/email` and `GH_CONFIG_DIR` for the correct `gh` CLI auth.

## 7. Claude Code Setup

```bash
cd ~/work/src/github.com/sam-at-luther/claude-config
./setup.sh
```

This symlinks:
- `~/.claude/CLAUDE.md` → global instructions
- `~/.claude/skills/firecrawl` → web scraping/search skill
- `~/.claude/skills/find-skills` → skill discovery
- `~/.claude/skills/mars` → infrastructure tool skill

### Install Firecrawl CLI

```bash
npm install -g firecrawl-cli
firecrawl login --browser
```

### Install Mars

Mars is used from within Luther infrastructure repos. See the [mars repo](https://github.com/luthersystems/mars) for Docker-based setup.

## 8. Kubernetes Helpers

From `luther-shell-helpers`, you get:

```bash
setkns <namespace>   # Set default kubectl namespace
kns                  # Show current namespace
kns get pods         # kubectl with namespace preset
```

## 9. Oh My Zsh (Optional)

```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Theme: `robbyrussell`, plugins: `(git)`

## Summary: Tool Chain

| Tool | Source | Purpose |
|------|--------|---------|
| `speculate` | `go install github.com/akerl/speculate/v2@latest` | AWS role assumption with MFA |
| `aws-cred-setup` | `luthersystems/aws-cred-setup` | Configure AWS MFA credentials |
| `luther-shell-helpers` | `luthersystems/luther-shell-helpers` | `aws_login`, `aws_jump`, `credcopy`, `kns`, etc. |
| `switch_accounts.sh` | `luthersystems/shell-scripts` | GitHub account switching (`luther`/`toko`) |
| `mars` | `luthersystems/mars` | Terraform/Ansible/Packer wrapper |
| `firecrawl` | `npm install -g firecrawl-cli` | Web scraping and search |
| `mosh` + `tmux` | brew/apt | Persistent VPN shell sessions |
| `tailscale` | tailscale.com | VPN mesh network |
