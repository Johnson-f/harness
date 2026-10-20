# harness
my personal implementation of agentic virtual machine.

Text an agent from your iPhone over iMessage; it does work on this Mac (or a server reached through it) and replies in the same chat.

## Status

Step 1 — iMessage bridge (echo bot). Reads new messages from `~/Library/Messages/chat.db`, ignores anyone not on the allowlist, replies via Messages.app.

## Setup

1. Sign **Messages** on this Mac into a separate Apple ID for the agent (Messages → Settings → iMessage). iCloud stays on your own account.
2. Give the app that runs `harness` **Full Disk Access** (System Settings → Privacy & Security → Full Disk Access), then quit and reopen it.
3. `cp .env.example .env` and set `HARNESS_ALLOWED_HANDLES` to your phone number (international form) and/or the email your iPhone sends iMessages from.
4. `swift run harness`
5. Text the agent's Apple ID from your iPhone. The first reply triggers a macOS prompt to allow controlling Messages — allow it.

`swift run harness send <handle> <message>` sends a one-off message, handy for testing outbound alone.

`swift test` runs the tests.

## Config

Read from the environment, falling back to `.env` in the working directory.

| Variable | Default |
| --- | --- |
| `HARNESS_ALLOWED_HANDLES` | required |
| `HARNESS_CHAT_DB` | `~/Library/Messages/chat.db` |
| `HARNESS_STATE_DIR` | `~/.harness` |
| `HARNESS_POLL_INTERVAL_MS` | `1000` |
