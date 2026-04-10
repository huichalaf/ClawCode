---
name: usage
description: Show usage cost summary — session, today, last 30 days. OpenClaw-compatible format. Works from CLI or messaging. Triggers on /usage, /agent:usage, "cuanto gasté", "agent usage", "cost".
user-invocable: true
---

# /usage — Cost Summary

Show usage costs in the OpenClaw-compatible format. Works from CLI or messaging channels.

## Output format (matches OpenClaw exactly)

```
💸 Usage cost
Session <cost> · <tokens> tokens
Today <cost>
Last 30d <cost>
```

## Subcommands

- `/usage` — show the cost summary (default)
- `/usage tokens` — compact token display
- `/usage full` — verbose token + cost
- `/usage cost` — same as default

## Steps

1. **Detect surface** (CLI vs messaging channel).

2. **Try to read session cost data** from Claude Code's session store:
   ```bash
   ls ~/.claude/projects/*/\*.jsonl 2>/dev/null | head -3
   ```
   
   NOTE: Claude Code stores session data in `~/.claude/projects/<slug>/*.jsonl`. The plugin cannot reliably read these because:
   - The session slug depends on the current cwd
   - The format is internal to Claude Code
   - Token counts per session are not always available to skills

3. **Fall back to estimate from memory/dreams**:
   - Call `agent_status` MCP tool → get file/chunk counts
   - Bash: `du -sh memory/ | awk '{print $1}'` → memory dir size
   - Bash: `wc -l memory/.dreams/events.jsonl 2>/dev/null | awk '{print $1}'` → event count

4. **Build the response** in OpenClaw format:

### When cost data is available
```
💸 Usage cost
Session $0.42 · 125k tokens
Today $1.23
Last 30d $34.56
```

### When cost data is NOT available (most likely case)
```
💸 Usage cost
Session n/a (run native /cost or /usage in CLI for tokens)
Today n/a
Last 30d n/a

📊 Agent resources
Memory: <size>, <N> files, <M> chunks
Dreams: <events> events, <unique> unique memories
```

5. **Format per surface**:
   - **CLI**: standard markdown
   - **WhatsApp**: single `*bold*`
   - **Telegram**: `**bold**`

6. **Reply tool** if on messaging channel.

## Important

- Claude Code does not expose session cost data to plugin skills directly.
- The honest answer is "n/a — use native /cost on CLI for real token/cost data".
- Agent resources (memory, dreams, files) ARE available and we can show them.
- This matches OpenClaw's `/usage cost` format but with the Claude Code limitation documented.
- This is the agent-aware equivalent of OpenClaw's `/usage`.
