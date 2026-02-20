---
name: release
description: "Deploy changes to production via Vercel and/or MCP server. Creates git tags, monitors deployments, verifies health. Examples: 'cut a release', 'deploy to prod', 'release to production', 'tag a new version'."
---

# Release / Deploy to Production

Deploy changes to production via Vercel.

## Architecture

| Branch | Deploys To | Vercel Environment |
|--------|------------|-------------------|
| `main` (push) | `reliable.luthersystemsapp.com` | Staging (Vercel Preview) |
| `v*` (tag) | `insideout.luthersystemsapp.com` | Production (Vercel Production) |

Push to `main` auto-deploys to staging. Tag a release to deploy to production.

## Pre-Release Checklist

### 1. Verify CI Passes
```bash
gh pr checks <pr-number>
```
Or check the GitHub Actions status on the PR.

### 2. Review Pending Changes
```bash
gh pr view <pr-number> --json title,body,files
```

### 3. Check for Migrations
If the PR includes database migrations:
- Migrations run automatically during Vercel build via `npm run migrate:ci`
- For manual migration (if auto fails):
  ```bash
  ENV_FILE=.env.prod-raspy-bird npx tsx scripts/migrate.ts
  ```
- **NEVER** run production migrations without explicit user approval

### 4. Verify the Deploy
After merge and deploy:
```bash
curl -s https://insideout.luthersystemsapp.com/agent-api/health | jq .
```
Check:
- `status` is `"ok"`
- `db_host` starts with `ep-raspy-bird` (V2 production database)

### 5. MCP Server (Auto-Deploy to Test)
If the change touches MCP server paths (`mcp-server/`, `internal/chatv2/`, `internal/models/`, `internal/reliabletf/`):
- The `mcp-server-release.yaml` workflow auto-builds and publishes to DockerHub on merge to `main`
- Image: `luthersystems/insideout-mcp:latest`
- Also tagged with the git ref name
- This deploys to **test** only — prod requires a tag push (see below)
- **Use the `wait-mcp-deploy` sub-skill** with `env=test` to monitor both workflows (reliable + ui-infrastructure) and verify the test healthz endpoint. See `.claude/skills/wait-mcp-deploy.md`.

---

## MCP Server: Release to Prod

Deploying the MCP server to **prod** requires pushing a git tag. Tags trigger the same `mcp-server-release.yaml` workflow but target `prod` instead of `test`.

### Tag Format

Use semver: `v0.X.Y`. Auto-increment patch from the latest tag:
```bash
# Find the latest tag
git tag -l 'v*' --sort=-v:refname | head -1

# If no tags exist yet, start with v0.1.0
```

### Steps

#### 1. Verify Test Deployment

Use the `wait-mcp-deploy` sub-skill to confirm the change is deployed to test and healthy:

```
Run the wait-mcp-deploy sub-skill with env=test and the expected commit SHA.
See .claude/skills/wait-mcp-deploy.md for the full procedure.
```

This monitors both the `reliable` and `ui-infrastructure` workflows, then verifies the test healthz endpoint returns the expected `git_commit`.

If the test deploy was already verified after merging (step 5 above), you can skip the workflow monitoring and just confirm healthz:
```bash
curl -s https://app.platform-test.luthersystemsapp.com/insideout-mcp/healthz | jq .
```

#### 2. Verify CI Passed on `main`

```bash
gh run list --branch main --workflow=mcp-server-release.yaml --limit 3
```
Confirm the latest run succeeded.

#### 3. Determine the Next Version

```bash
# Get the latest semver tag
LATEST=$(git tag -l 'v*' --sort=-v:refname | head -1)
echo "Latest tag: ${LATEST:-none}"

# If no tags: next is v0.1.0
# Otherwise: bump patch (e.g., v0.1.0 → v0.1.1)
```

#### 4. Create and Push an Annotated Tag

**IMPORTANT**: Always ask the user for confirmation before pushing a tag.

```bash
git fetch origin main
git tag -a v0.X.Y origin/main -m "MCP server release v0.X.Y"
git push origin v0.X.Y
```

#### 5. Monitor Deploy and Verify Prod

Use the `wait-mcp-deploy` sub-skill to monitor the full pipeline and verify prod:

```
Run the wait-mcp-deploy sub-skill with env=prod and the expected commit SHA (from the tag).
See .claude/skills/wait-mcp-deploy.md for the full procedure.
```

This will:
1. Watch the `Release MCP Server` workflow in `reliable` (triggered by the tag push)
2. Watch the `Deploy` workflow in `ui-infrastructure` (triggered by the version bump)
3. Verify `https://app.platform.luthersystemsapp.com/insideout-mcp/healthz` returns the expected `git_commit`

**Use a background Task subagent** so the main conversation isn't blocked while waiting.

### Verification Endpoints

| Environment | Health Check |
|-------------|-------------|
| **Test** | `https://app.platform-test.luthersystemsapp.com/insideout-mcp/healthz` |
| **Prod** | `https://app.platform.luthersystemsapp.com/insideout-mcp/healthz` |

### Rollback

To roll back prod, push a new tag pointing to the previous known-good commit:
```bash
git tag -a v0.X.Y <known-good-commit-sha> -m "Rollback MCP server to <previous-version>"
git push origin v0.X.Y
```

### Rules

- NEVER push a tag without verifying the change works on test first.
- NEVER push a tag without explicit user confirmation.
- Always use annotated tags (`git tag -a`) with a descriptive message.
- Tags trigger prod deploy regardless of path filters — only tag commits that include MCP changes.

## Vercel Environment Vars

When adding secrets to Vercel:
```bash
# CORRECT -- no trailing newline
printf '%s' 'my-secret-value' | vercel env add MY_VAR preview

# WRONG -- trailing newline breaks auth
echo "my-secret-value" | vercel env add MY_VAR preview
```

## Rollback

If a deploy causes issues:
1. Check the Vercel dashboard for the previous successful deployment
2. Use Vercel's "Promote to Production" on the previous deployment
3. Or revert the commit and push to `main`

## Rules

- NEVER push directly to `main`. Always go through a PR.
- NEVER merge PRs yourself. Wait for human review and approval.
- NEVER run production database migrations without explicit approval.
