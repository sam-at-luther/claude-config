---
name: grind
description: "Use this skill when the user wants to automatically process GitHub issues. Picks up issues labeled 'agent-ready', claims them, implements the fix/feature, and opens a PR. Loops for a specified duration. Examples: '/grind 1h', '/grind 30m', 'grind through my issues', 'process the issue backlog'."
---

# Automated GitHub Issue Processing

This skill continuously processes GitHub issues labeled `agent-ready`. It claims issues with a race-safe protocol, implements the changes via subagents, and opens PRs — looping until the time budget expires.

## 1. Parse Duration

Parse the argument as a duration. Supported formats: `Nm` (minutes), `Nh` (hours), bare number (minutes). Default: `1h` (60 minutes).

```bash
# Examples:
# /grind 1h   → 60 minutes
# /grind 30m  → 30 minutes
# /grind 90   → 90 minutes
# /grind      → 60 minutes (default)
```

Calculate the deadline as: `DEADLINE = $(date +%s) + (duration in seconds)`.

## 2. Initialize Session

```bash
SESSION_ID=$(uuidgen)
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
```

Print a startup banner:

```
Grind session $SESSION_ID started
Repository: $REPO
Duration: <parsed duration>
Deadline: <human-readable deadline>
```

Track counters: `PROCESSED=0`, `SUCCEEDED=0`, `FAILED=0`, `SKIPPED=0`.

## 3. Ensure Labels Exist

Check for and create each required label if missing:

```bash
for label_args in \
  "agent-ready --color 0E8A16 --description 'Issue triaged and ready for an agent'" \
  "agent-claimed --color E4E669 --description 'An agent has claimed this issue'" \
  "agent-in-progress --color F9A825 --description 'Agent implementation underway'" \
  "agent-completed --color 1D76DB --description 'PR created successfully'" \
  "agent-failed --color D93F0B --description 'Agent failed, needs human review'"; do
  gh label create $label_args 2>/dev/null || true
done
```

## 4. Release Stale Claims

Before entering the main loop, check for stale `agent-claimed` issues — issues where the most recent comment is older than 2 hours. Release them back to `agent-ready`:

```bash
# List all agent-claimed issues
gh issue list --label agent-claimed --json number,updatedAt --jq '.[]'
```

For each issue, check if `updatedAt` is older than 2 hours from now. If so:

```bash
gh issue edit <N> --remove-label agent-claimed --add-label agent-ready
gh issue comment <N> --body "Releasing stale claim — no agent completed this within 2 hours."
```

Report how many stale claims were released.

## 5. Main Loop

Loop while `$(date +%s) < $DEADLINE`:

### 5a. Find Oldest `agent-ready` Issue

```bash
ISSUE_JSON=$(gh issue list --label agent-ready --sort created --json number,title --jq '.[0]')
```

If no issue found, enter **backoff polling**:
- Sleep intervals: 30s, 60s, 120s, 300s (max)
- Double the interval each time no issue is found
- Reset to 30s when an issue is found
- Before each sleep, check the deadline — if sleeping would exceed it, exit the loop
- Print: `No agent-ready issues. Polling again in <N>s...`
- Use `sleep` via Bash between polls — do NOT burn tokens polling

If an issue is found, reset backoff to 30s and proceed.

### 5b. Claim the Issue (Race-Safe)

```bash
ISSUE_NUM=<number from JSON>
ISSUE_TITLE=<title from JSON>

# Atomically swap labels and post claim comment
gh issue edit $ISSUE_NUM --remove-label agent-ready --add-label agent-claimed
gh issue comment $ISSUE_NUM --body "Claimed by agent session $SESSION_ID"
```

**Verify the claim:** Re-read the issue comments and check that the most recent comment contains our `$SESSION_ID`. If another agent's comment appears after ours, we lost the race:

```bash
LAST_COMMENT=$(gh issue view $ISSUE_NUM --json comments --jq '.comments[-1].body')
```

If `$LAST_COMMENT` does not contain `$SESSION_ID`:
- Increment `SKIPPED`
- Print: `Lost race for #<N>, skipping`
- Continue to next iteration

### 5c. Process the Issue via Subagent

Update the label to `agent-in-progress`:

```bash
gh issue edit $ISSUE_NUM --remove-label agent-claimed --add-label agent-in-progress
```

Launch a **Task subagent** (subagent_type: `general-purpose`) with this prompt:

```
You are processing GitHub issue #<ISSUE_NUM> in repository <REPO>.

## Issue Details
<paste full output of: gh issue view <ISSUE_NUM>>

## Instructions

1. Read the full issue body and all comments to understand the requirements.

2. Make sure you are on the default branch and it is up to date:
   git checkout <DEFAULT_BRANCH>
   git pull origin <DEFAULT_BRANCH>

3. Create a feature branch:
   git checkout -b agent/issue-<ISSUE_NUM>-<slugified-title>

4. Enter plan mode. Explore the codebase, understand the architecture, and design your implementation. Exit plan mode when your plan is ready.

5. Implement the changes following the plan. Write tests where appropriate.

6. Run the relevant test suite to verify your changes pass.

7. Create a PR using the /pr skill. The PR title should reference the issue: "Fix #<ISSUE_NUM>: <brief description>". The PR body should include "Closes #<ISSUE_NUM>" to auto-close the issue on merge.

8. Return the PR URL as your final output. If you could not complete the task, return "FAILED: <reason>" instead.
```

### 5d. Handle Result

**On subagent failure** (subagent returns FAILED or errors out):

- Increment `FAILED` and `PROCESSED`

```bash
gh issue edit $ISSUE_NUM --remove-label agent-in-progress --add-label agent-failed
gh issue comment $ISSUE_NUM --body "Agent failed to complete this issue.\n\nError: <error summary>\n\nSession: $SESSION_ID"
```

- Print: `#<N> failed — <error summary>`
- Continue to step 5f.

**On subagent success** (subagent returns a PR URL):

- Print: `#<N> PR created — <PR_URL>. Waiting for CI checks...`
- Proceed to step 5e to wait for CI.

### 5e. Wait for CI Checks to Pass

After the subagent creates a PR, wait for all CI checks to go green before moving on. This ensures we don't pile up broken PRs.

**Poll CI status with backoff:**

```bash
# Extract PR number from URL
PR_NUM=$(echo "$PR_URL" | grep -oE '[0-9]+$')

# Check status — returns "pass", "fail", or "pending"
gh pr checks $PR_NUM --json name,state --jq '
  if [length == 0] then "pending"
  elif any(.[]; .state == "FAILURE") then "fail"
  elif all(.[]; .state == "SUCCESS") then "pass"
  else "pending"
  end
'
```

**Polling loop:**
- Wait 30s before the first check (CI takes time to start)
- Then poll every 60s
- Before each sleep, check the deadline — if waiting would exceed it, print a warning and move on (don't block the session exit)
- Maximum wait: 15 minutes. If checks are still pending after 15 minutes, treat as a timeout.

**On CI pass:**
- Increment `SUCCEEDED` and `PROCESSED`

```bash
gh issue edit $ISSUE_NUM --remove-label agent-in-progress --add-label agent-completed
gh issue comment $ISSUE_NUM --body "PR created and CI passing: <PR_URL>"
```

- Print: `#<N> completed — CI green — <PR_URL>`

**On CI failure:**

Do NOT just label it failed and move on. Attempt to fix it:

1. Print: `#<N> CI failed — attempting fix...`
2. Read the failing check logs:
   ```bash
   gh pr checks $PR_NUM --json name,state,detailsUrl --jq '.[] | select(.state == "FAILURE")'
   ```
3. Launch a **fix subagent** (subagent_type: `general-purpose`) with this prompt:
   ```
   CI checks are failing on PR <PR_URL> for issue #<ISSUE_NUM> in repository <REPO>.

   ## Failing Checks
   <paste failing check names and detail URLs>

   ## Instructions

   1. Check out the PR branch:
      git checkout <branch-name>

   2. Read the CI failure logs. Use `gh run view <run-id> --log-failed` to get the
      failure output if available, or fetch the details URL to understand what failed.

   3. Fix the failing code. Run the relevant tests locally to confirm the fix.

   4. Commit and push the fix to the same branch:
      git add <files> && git commit -m "fix: address CI failures" && git push

   5. Return "FIXED" if you pushed a fix, or "FAILED: <reason>" if you cannot resolve it.
   ```
4. If the fix subagent returns "FIXED":
   - Go back to the CI polling loop (reset the 15-minute timeout)
   - Allow up to **2 fix attempts** total per issue
5. If the fix subagent fails, or if this was the 2nd fix attempt:
   - Increment `FAILED` and `PROCESSED`
   ```bash
   gh issue edit $ISSUE_NUM --remove-label agent-in-progress --add-label agent-failed
   gh issue comment $ISSUE_NUM --body "PR created but CI checks are failing after fix attempts. Needs human review.\n\nPR: <PR_URL>\n\nSession: $SESSION_ID"
   ```
   - Print: `#<N> failed — CI checks not passing after fix attempts`

**On CI timeout (15 min):**
- Increment `SUCCEEDED` and `PROCESSED` (PR exists, checks just haven't finished)

```bash
gh issue edit $ISSUE_NUM --remove-label agent-in-progress --add-label agent-completed
gh issue comment $ISSUE_NUM --body "PR created: <PR_URL>\n\nNote: CI checks were still running when the agent moved on. Please verify manually."
```

- Print: `#<N> PR created — CI still pending after 15m, moving on — <PR_URL>`

### 5f. Check Deadline

After processing each issue (including CI wait), check if `$(date +%s) >= $DEADLINE`. If so, break out of the loop.

## 6. Print Summary

When the loop exits (deadline reached or interrupted), print:

```
--- Grind Session Summary ---
Session:    $SESSION_ID
Repository: $REPO
Duration:   <actual elapsed time>

Processed:  $PROCESSED issues
Succeeded:  $SUCCEEDED (PRs created)
Failed:     $FAILED (needs human review)
Skipped:    $SKIPPED (lost race)
---
```

## Important Notes

- **Token efficiency:** The outer loop only runs `gh` CLI commands. All heavy implementation work happens inside subagents with fresh context windows.
- **CI before next issue:** Never pick up a new issue while the previous PR's CI is red. Wait for green, or fix it first (up to 2 attempts). This prevents a pile-up of broken PRs.
- **Backoff polling:** When no issues are available, sleep between polls. Do NOT repeatedly call `gh issue list` without sleeping — this wastes both tokens and API rate limit.
- **Race safety:** Always verify claims before starting work. If verification fails, skip gracefully.
- **Clean branches:** Each issue gets its own branch off `DEFAULT_BRANCH`. Always start from a clean, up-to-date checkout.
- **Error isolation:** If a subagent fails, catch the error, label the issue `agent-failed`, and continue to the next issue. Never let one failure kill the loop.
- **Deadline respect:** Check the deadline after every issue (including CI wait time) and after every backoff sleep. Exit cleanly when time is up.
