# claude-statusline

A status line script for [Claude Code](https://claude.ai/code) that displays context window usage and rate limit info directly below the chat bar.

## What it shows

```
Ctx: ████████░░░░ 67%  5h: ███░░░░░░░░░ 25% (reset dans 4m 12s)  7j: 10%
```

- **Ctx** — context window used (block progress bar)
- **5h** — 5-hour rate limit usage + countdown to reset
- **7j** — 7-day rate limit usage (when available)

## Install

```bash
# 1. Copy the script
cp statusline-context.sh ~/.claude/statusline-context.sh
chmod +x ~/.claude/statusline-context.sh

# 2. Add to ~/.claude/settings.json
```

```json
"statusLine": {
  "type": "command",
  "command": "bash /Users/YOUR_USERNAME/.claude/statusline-context.sh"
}
```

Replace `YOUR_USERNAME` with your macOS username (`whoami`).

## Requirements

- Claude Code CLI
- `jq` (`brew install jq`)
