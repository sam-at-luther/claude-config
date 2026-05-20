# Global Claude Code Instructions

## How I work — read first

- I type fast, lowercase, with typos and voice dictation. Parse intent; never nitpick wording or ask me to clarify obvious misspellings (`mian`=main, `emrged`=merged).
- **Be terse and scannable — I have ADHD.** Default to table format for summaries, comparisons, and status. Plain, clear English; no jargon or padding; links over prose; short status lines. "How's it looking?" wants a one-liner. Lead with the answer, details after.
- **Don't invent.** Don't suggest tools, products, or libraries I didn't ask for or that aren't well-known. Recommend few, well-established options.
- **Interview me on design, not execution.** If a non-trivial task is ambiguous about philosophy, scope, or tradeoffs, ask design questions in a Q&A before building. Never ask permission for mechanical steps — just do them.
- **Grind to completion.** Once direction is set, run autonomously to done — branch → fix → verify → PR → link. Don't stop for check-ins. For bug reports, just fix it; fix failing CI without being told how.
- I resume interrupted work often. Keep a running task list and next-step summary so I can pick up cleanly.

## Subagents & context

- My context window is a scarce resource. **Default to subagents/worktrees for any multi-part work, research, or exploration** — keep the main thread clean.
- One focused task per subagent. Use background subagents and worktrees for parallel work so agents don't step on each other.

## Plan mode

- Enter plan mode for non-trivial tasks (3+ steps or architectural decisions).
- If something goes sideways, STOP and re-plan — don't keep pushing.

## Git & PRs

- **NEVER** push or force-push to `main`/production (no `--force`, no `--force-with-lease`).
- Force-pushing a feature branch with an open PR is fine for WIP iteration — prefer `--force-with-lease`.
- Always branch off `main` first. Use `feature/`/`fix/`/`refactor/`/`docs/` prefixes.
- **Before touching any PR: `git fetch` and rebase off latest `origin/main`. Check whether the branch/PR was already merged before acting.**
- **Bundle related fixes into ONE PR, but one commit per work item.** Don't fragment work into many follow-up PRs. If I raise several issues in a session, file a ticket each but deliver the fixes in a single bundle PR I can test together. Phases are fine inside one PR. Keep each distinct work item as its own commit so individual changes can be reverted or bisected cleanly.
- File issues in the correct repo. If a problem belongs to another repo, file the ticket there rather than patching in place.
- Every ticket gets a GitHub issue. PR body references each (`Closes #N`); partial work updates the issue checklist instead.
- Run the `pr` skill (rebase, QC gates) and `qa-professor` on PRs without being reminded. **End every task by linking the PR/URL.**
- Use `gh` for remote ops; keep remotes on HTTPS so `gh auth` handles auth.
- No orphan branches or unpushed commits — every branch has a PR (draft is fine).

## Verification & quality

- **Never mark a task done without proving it works** — real endpoints, real environments, examples/tests that actually run. No mock theatre.
- Prefer running checks in CI over exhaustive local validation; watch CI and loop until green.
- Find root causes — no temp fixes, no hacks. If a fix feels hacky, do the elegant one. Don't over-engineer simple fixes.
- Changes touch only what's necessary. Would a staff engineer approve this?
- Be ready to justify claims with evidence — I probe assertions.

## Deferred work

- **No furtive partial implementations.** Defer only with an explicit `// TODO(scope): what's missing and why` at the spot, and call it out in your summary. For larger deferrals, open/reference a GitHub issue.
- Order of preference: (a) do it now, (b) marked TODO + surface it, (c) ask. Never (d) pretend it's done.
- **Don't defer substantial work that's in the spirit of the task — do it now.** Small nitpicky fixes you notice along the way: just fix them inline (drive-by), no ticket. Larger out-of-scope things you observe: file one follow-up ticket. Never file tickets for nitpicky deferrals — it spams my issue list.
- **See something, say something — for substantial issues only.** When you spot a *substantial* preexisting problem while working — a real bug, security/correctness risk, or meaningful design flaw — flag it, even if unrelated to the task, and ticket it. Don't report trivial nits or style quibbles; I don't want noise.

## Security

- Every new API endpoint is authenticated by default — decide public vs. auth explicitly in a comment. Session endpoints verify the caller owns that session; admin/bulk endpoints sit behind admin middleware. Include an auth test case.

## Attribution

- No `Co-Authored-By` lines, no "Generated with Claude Code" badges in commits or PRs.

## Browser automation

- NEVER use Claude-in-Chrome tools. Always use the Agent Browser plugin (`agent-browser@agent-browser`).

## Temp files

- Scratch files go in `.tmp/` in the project root; add `.tmp/` to `.gitignore`.

## Luther dev tooling

See `SETUP_ENV.md` for install. Key tools: `speculate` (AWS role assumption w/ MFA), `aws-cred-setup` (MFA creds), `luther-shell-helpers`, `mars` (Terraform/Ansible/Packer in Docker).
Shell helpers: `aws_login <role>` (MFA session, default `dev`), `aws_jump <account> <role>`, `aws_console <account>`, `setkns <ns>` / `kns` (kubectl namespace).
