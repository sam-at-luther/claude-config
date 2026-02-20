---
name: email
description: "View, draft, and send emails using the zele CLI. Use when asked to check email, read threads, compose messages, reply, forward, manage labels, or watch for new mail."
---

# Email

Manage Gmail from any project using the `zele` CLI.

## CRITICAL: Never Send Without Approval

**NEVER execute `zele mail send`, `zele mail reply`, `zele mail forward`, or `zele draft send` without explicit user approval.** Always:

1. Show the full email (to, cc, bcc, subject, body) in the chat
2. Wait for the user to explicitly say "send it", "looks good", "approved", or similar
3. Only then run the send command

This applies even if the user said "send an email to X" -- draft it, show it, wait for approval. No exceptions.

## Prerequisites

`zele` must be installed globally (`npm install -g zele`) and authenticated (`zele login`). Multi-account is supported -- all commands fetch from all accounts unless `--account <email>` is specified.

## Writing Style

When composing emails on my behalf, follow these rules strictly:

- **Use my natural voice.** Write like a real person, not a language model. Short sentences. No filler.
- **No LLM tells.** Avoid:
  - Long dashes (use "--" not "---" or em dashes)
  - "It wasn't just X, but Y" constructions
  - "I wanted to reach out" / "I hope this finds you well" / "Just circling back"
  - Overly hedged language ("I think perhaps we might consider...")
  - Formulaic transitions ("That said," "Moreover," "Furthermore,")
  - Exclamation marks on mundane things ("Great question!")
  - "Happy to help" / "Please don't hesitate to" / "Feel free to"
- **Be direct.** State the point in the first sentence. No warm-up paragraphs.
- **Keep it short.** Most emails should be 2-5 sentences. If it needs to be longer, use bullet points.
- **Match the tone of the thread.** If the thread is casual, be casual. If formal, be formal. When in doubt, lean casual-professional.
- **Sign off simply.** "Thanks," / "Cheers," / just my name. No elaborate closings.

## Viewing Email

### Check inbox

```bash
zele mail list                          # recent inbox threads
zele mail list --max 50                 # more results
zele mail list --folder sent            # sent mail
zele mail list --folder starred         # starred
zele mail list --label work             # filter by label
```

### Search

```bash
zele mail search "from:github is:unread newer_than:7d"
zele mail search "subject:invoice has:attachment"
zele mail search "from:alice OR from:bob"
```

### Read a thread

```bash
zele mail read <threadId>
zele mail read <threadId> --raw         # RFC 5322 raw format
```

### Check unread counts

```bash
zele label counts
```

### Watch for new mail

```bash
zele mail watch                                    # poll inbox every 15s
zele mail watch --query "from:important@co.com"    # filtered
zele mail watch --once                             # check once and exit
```

## Composing & Sending

### Send a new email

```bash
zele mail send --to "alice@example.com" --subject "Meeting tomorrow" --body "Can we move to 3pm? The 2pm slot conflicts with another call."
```

With CC/BCC:
```bash
zele mail send --to "alice@example.com" --cc "bob@example.com" --bcc "manager@example.com" --subject "Q1 update" --body "Attached the latest numbers."
```

Body from file or stdin:
```bash
zele mail send --to "alice@example.com" --subject "Notes" --body-file notes.txt
echo "Quick update" | zele mail send --to "alice@example.com" --subject "Update" --body-file -
```

### Reply to a thread

```bash
zele mail reply <threadId> --body "Sounds good, let's do Thursday."
zele mail reply <threadId> --body "Agreed." --all    # reply-all
zele mail reply <threadId> --body "Adding Bob." --cc "bob@example.com"
```

### Forward a thread

```bash
zele mail forward <threadId> --to "bob@example.com"
zele mail forward <threadId> --to "bob@example.com" --body "FYI -- see below."
```

### Drafts

```bash
zele draft list
zele draft get <draftId>
zele draft create --to "alice@example.com" --subject "Draft" --body "WIP content"
zele draft send <draftId>
zele draft delete <draftId> --force
```

## Actions

```bash
zele mail star <threadId> [<threadId2> ...]
zele mail unstar <threadId>
zele mail archive <threadId> [<threadId2> ...]
zele mail trash <threadId>
zele mail untrash <threadId>
zele mail read-mark <threadId> [<threadId2> ...]
zele mail unread-mark <threadId>
zele mail label <threadId> --add "work,urgent"
zele mail label <threadId> --remove "inbox"
zele mail trash-spam                               # trash all spam
```

## Labels & Attachments

```bash
zele label list
zele label get <labelId>
zele label create "project-x" --bg-color "#4986e7" --text-color "#ffffff"
zele label delete <labelId> --force

zele attachment list <messageId>
zele attachment get <messageId> <attachmentId> --out-dir ./downloads
```

## Multi-Account

```bash
zele whoami                                # show all accounts
zele mail list --account sam@example.com   # filter to one account
```

Without `--account`, commands merge results from all authenticated accounts.

## Workflow: Read and Reply

A typical flow for processing email:

```bash
# 1. See what's new
zele label counts
zele mail list --max 10

# 2. Read a thread
zele mail read <threadId>

# 3. Reply
zele mail reply <threadId> --body "Thanks, I'll review and get back to you by EOD."

# 4. Archive or label
zele mail archive <threadId>
```

## Workflow: Compose from Context

When asked to draft or send an email about something from the current project:

1. Gather the relevant context (code changes, PR links, error logs, etc.)
2. Draft concise body text following the writing style rules above
3. Show the user the draft before sending
4. Use `zele mail send` or `zele draft create` based on user preference

**Never send without explicit approval** (see top of this skill).

## Key Reminders

- Output is YAML -- parse it or read it directly
- Thread IDs come from `mail list` / `mail search` output
- Message IDs (for attachments) come from `mail read` output
- `--body-file -` reads from stdin (useful for piping)
- Dates display as relative ("5m ago", "2h ago", "3d ago")
- `mail watch --query` only supports a subset of Gmail operators (from:, to:, subject:, is:, has:)
- Always draft-then-confirm for important emails -- use `draft create` then `draft send`
