---
name: status
description: Show agent runtime status — OpenClaw-style card with version, model, context, session, options, activation. Works from CLI or messaging. Triggers on /status, /agent:status, "status del agente", "cómo estás técnicamente".
user-invocable: true
---

# /status — Runtime Status

Show the OpenClaw-style status card with runtime info. Works from CLI and from messaging channels.

## Output format (OpenClaw-compatible)

```
🦞 ClawCode <version>
🧠 Model: <provider>/<model>
📚 Context: <tokens>/<limit> (<%>) · 🧹 Compactions: <count>
🧵 Session: <session-key> • updated <time-ago>
⚙️ Runtime: <runtime-label> · Think: <level>
```

Additional lines (when available):
- `🧮 Tokens: <input> in / <output> out` — if token data is available
- `📎 Media: <caps>` — if media capabilities are relevant
- `🔊 Voice: ...` — if TTS/voice is configured
- `👥 Activation: <mode>` — if in a group chat
- `🪢 Queue: <mode>` — if queue depth > 0

## Steps

1. **Call `agent_status` MCP tool** to get identity, memory stats, dreams.

2. **Gather additional data**:
   - Bash: `date` for current time
   - Bash: `cat .claude/scheduled_tasks.json 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0` for cron count
   - Read `package.json` from `$CLAUDE_PLUGIN_ROOT` for version
   - Detect surface from `<channel source="...">` if present

3. **Build the status card** following the format above. Use the AGENT'S data, not fake fields:
   - Replace `<version>` with version from package.json
   - Replace `<provider>/<model>` with the current Claude Code model (you are running on claude-opus-4-6 or similar)
   - Replace `<tokens>/<limit>` with memory chunks or "—" if not applicable
   - Replace `<session-key>` with channel info (cli, whatsapp:<user>, telegram:<user>)
   - Replace `<runtime-label>` with `builtin` or `qmd` depending on config
   - Replace `<level>` with `off` (default thinking)

4. **Format per surface**:

### CLI
Use the standard markdown block above with proper line breaks.

### WhatsApp
Same content, but replace any `**bold**` with `*bold*` (single asterisk). No headers (`#`).

### Telegram
Use `**bold**`, headers are fine.

5. **Reply tool** if on a messaging channel; otherwise print to stdout.

## Example output (WhatsApp)

```
🦞 *ClawCode 1.0.0*
🧠 *Model:* anthropic/claude-opus-4-6
📚 *Context:* 4 files · 12 chunks · 🧹 0 compactions
🧵 *Session:* whatsapp:JC • updated ahora
⚙️ *Runtime:* builtin (SQLite + FTS5 + BM25 + temporal decay + MMR) · Think: off
👤 *Agent:* <Name> <emoji>
```

## Important

- This is PURELY informational. It does not modify state.
- Get REAL data from `agent_status`, `agent_config`, and the filesystem. Never fabricate numbers.
- The token/cost fields come from Claude Code's session (which the plugin can't access directly). Show "—" for those or recommend the native `/usage` for cost details.
- This is the agent-aware equivalent of OpenClaw's `/status`.
