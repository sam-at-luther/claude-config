---
name: pr
description: "Use this skill whenever the user asks to create a PR, open a PR, or submit changes for review. Runs local tests, performs security review, creates the PR, then runs QA professor on test quality. Examples: 'create a PR', 'open a pull request', 'submit this for review', 'PR these changes'."
---

# Pull Request with QA & Security Review

This skill orchestrates creating a GitHub pull request with automatic quality assurance and security reviews.

## Workflow

### 1. Determine Base Branch and Rebase

First, identify the default branch and ensure we're rebased:

```bash
# Get the default branch name (main, master, develop, etc.)
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'

# Fetch latest and rebase against it
git fetch origin
git rebase origin/<default-branch>
```

If there are conflicts, help resolve them before proceeding.

### 2. Analyze Changes

Understand what's being proposed:

```bash
# Check current branch and status
git status
git log <default-branch>..HEAD --oneline
git diff <default-branch>...HEAD --stat
```

Identify:
- Which files are modified
- Which are test files (matching `*_test.go`, `*_test.py`, `test_*.py`, `*.test.ts`, `*.spec.ts`, etc.)
- Which files contain security-sensitive code (auth, crypto, permissions, input validation, API endpoints)

### 3. Run Relevant Local Tests

Before creating the PR, run tests related to the changed files:

**For Go projects:**
```bash
# Run tests in packages that were modified
go test ./path/to/modified/package/...
```

**For Python projects:**
```bash
# Run pytest on modified test files or related tests
uv run pytest path/to/tests/
```

**For Node.js/TypeScript projects:**
```bash
# Run tests related to changes
npm test -- --testPathPattern="<pattern>"
# or
npx vitest run path/to/tests/
```

If tests fail:
1. Report the failures to the user
2. Ask if they want to fix them before proceeding
3. Do NOT create the PR until tests pass (unless user explicitly requests it)

### 4. Run Security Review

Before creating the PR, perform a security review on changed files:

**Code patterns to check:**
- Input validation and sanitization
- Authentication and authorization logic
- Cryptographic operations
- SQL/NoSQL query construction
- File path handling
- Command execution
- Secrets and credential handling
- Error messages (no sensitive data leakage)
- CORS and CSP configurations
- Rate limiting and DoS protection

**Review approach:**
1. Identify security-sensitive files from the diff
2. Read each file and analyze for OWASP Top 10 vulnerabilities
3. Check for hardcoded secrets or credentials
4. Verify proper error handling doesn't leak sensitive info
5. Ensure input validation is present at trust boundaries

If security issues are found, report them and ask user whether to proceed.

### 5. Create the Pull Request

Use the standard PR creation flow:

```bash
# Ensure we're up to date and pushed
git push -u origin HEAD

# Create the PR
gh pr create --title "<concise title>" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points describing the changes>

## Test plan
- [ ] <testing checklist items>

<!-- For UI/frontend PRs, include manual verification checklist items like:
- [ ] Manual: desktop — feature works as expected
- [ ] Manual: mobile — layout unchanged or responsive
- [ ] Manual: dark mode — new elements respect theme
- [ ] Manual: state persistence — survives page reload
- [ ] Manual: animations — smooth, no layout shift
-->

---
*Local tests passed. Security review completed. QA professor review pending.*

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

Capture the PR URL from the output.

### 6. Run QA Professor Review

If any test files were modified or added, invoke the **qa-professor** agent:

```
Use the Task tool with subagent_type=qa-professor to review the test files that were modified in this PR.

Provide the agent with:
- The list of test files changed (from git diff <default-branch>...HEAD)
- Context about what the tests are testing
```

The qa-professor agent will evaluate:
- Assertion quality (not just `!= nil` checks)
- Test independence and isolation
- Behavioral vs line coverage
- Test design smells
- Mutation resistance
- Naming and intent clarity

### 7. Present Findings

After both reviews complete, present a summary:

```
## PR Created
URL: <pr-url>

## QA Review Summary
<qa-professor findings - PASS/NEEDS WORK/FAIL with key issues>

## Security Review Summary
<security findings - any concerns or all clear>

## Recommendations
<prioritized list of issues to address before merge, if any>
```

### 8. Offer Follow-up Actions

Ask if the user wants to:
- Address any issues found and update the PR
- Add reviewers to the PR
- Mark the PR as ready for review (if draft)

## Notes

- Run local tests and security review BEFORE creating the PR
- Only create the PR after tests pass and security is reviewed
- If no test files were changed, skip the qa-professor review but note it in the summary
- If no security-sensitive files were changed, do a brief sanity check but note it was low-risk
- Be concise in findings - focus on actionable items
