---
name: crons
description: Import OpenClaw crons as Claude Code local scheduled tasks, or list current crons. Triggers on /agent:crons, "importar crons", "traer crons", "import crons", "list crons".
user-invocable: true
---

# Import Crons

Convert OpenClaw cron jobs into Claude Code **local scheduled tasks** using the `CronCreate` tool.

Local crons run on the user's machine with full access to files, MCP servers (including WhatsApp), and all Claude Code tools. This is the closest equivalent to OpenClaw's cron system.

## Understanding the formats

### OpenClaw cron (source: `~/.openclaw/cron/jobs.json`)

The file has the shape `{"version": 1, "jobs": [...]}`. Each job in the `jobs` array:
```json
{
  "id": "uuid",
  "agentId": "main",
  "name": "Job Name",
  "enabled": true,
  "schedule": { "kind": "cron", "expr": "0 14 * * 3,6", "tz": "America/Santiago" },
  "payload": { "kind": "agentTurn", "message": "prompt here", "model": "opus" },
  "delivery": { "mode": "announce", "channel": "whatsapp" }
}
```

When iterating, use `data["jobs"]`, not `data` directly.

### Claude Code local cron (target: `CronCreate` tool → `.claude/scheduled_tasks.json`)
- Standard 5-field cron expression (minute hour day month weekday) — **parameter name is `cron`, not `schedule`**
- Runs in **local timezone** (no UTC conversion needed)
- Full access to local files, MCP servers, tools
- `durable: true` → persists to `.claude/scheduled_tasks.json` and survives across restarts
- `recurring: true` (default) = fires until deleted; `recurring: false` = one-shot
- Executes while REPL is idle (between user queries)
- Default expiration: 7 days for recurring jobs

**IMPORTANT**: `CronCreate` is a **deferred tool**. Before invoking it for the first time in a session, call `ToolSearch` with `query="select:CronCreate"` to load its schema. Same for `CronList` and `CronDelete`.

## Classification (3 tiers)

Not every OpenClaw cron can be imported cleanly. Classify each into GREEN / YELLOW / RED before importing, so you can tell the user *why* each cron is importable or not.

```bash
HARD_RED='sessions_spawn|gateway config\.patch|http://192\.168\.|canvas\(|remindctl|wacli|openclaw gateway|HEARTBEAT_OK|NO_REPLY|peekaboo'
SOFT_YELLOW='sessions_send|message\(|~/\.openclaw/|\.openclaw/credentials'
```

For each cron in `jobs.json`:

| Tier | Criteria | Action |
|---|---|---|
| 🟢 GREEN | `enabled: true`, `kind: cron`, `payload.kind: agentTurn`, payload.message does NOT match HARD_RED, AND (no `delivery.channel` OR the channel's plugin is installed — check `ls ~/.claude/plugins/cache/ \| grep -i <channel>`) | Import directly via `CronCreate` |
| 🟡 YELLOW | `kind: at` with future timestamp, OR `kind: every` (convertible to `*/N`), OR `delivery.channel` points to a plugin not yet installed, OR payload.message matches SOFT_YELLOW | Import with adapted prompt + fallback note |
| 🔴 RED | `enabled: false`, OR `kind: at` with expired `expr: null`, OR `kind: systemEvent`, OR payload.message matches HARD_RED | Skip. Record specific reason. |

For every item, record the **specific reason** for its tier (which token matched at which line, or which field is the problem). That's what the user will see in the per-item summary.

## Steps

1. **Read OpenClaw crons:**
   ```bash
   cat ~/.openclaw/cron/jobs.json 2>/dev/null
   ```

2. **Filter** by the active agent's ID (`main`, `eva`, etc.). If no filter is given, ask the user which agent's crons to import.

3. **Classify** each enabled cron using the table above. Bucket them into GREEN / YELLOW / RED.

4. **Present the menu** (interactive, same as `/agent:import` Step D):
   ```
   <agent> has <N> enabled crons:

     🟢 <G> can be imported as-is
     🟡 <Y> need adaptation (schedule conversion or channel fallback)
     🔴 <R> can't be imported

     [a] Import all importable
     [s] Select specific crons
     [l] List all with status, then decide
     [n] Skip
   ```

5. **For selected crons, map the fields:**

   | OpenClaw field | CronCreate parameter | Notes |
   |---|---|---|
   | `schedule.expr` | `cron` (5-field expression) | Direct — both use 5-field cron. Drop OpenClaw's `tz` (Claude Code cron runs in local tz) |
   | `schedule.kind: "at"` | `cron` + `recurring: false` | Convert the ISO `at` timestamp to a minute-precision cron expression for the target date |
   | `schedule.kind: "every"` | `cron` (`*/N * * * *`) | `everyMs` → `*/N * * * *` where `N = max(1, round(everyMs / 60000))` |
   | `payload.message` | `prompt` | Apply token adaptation (see below) |
   | `name` | — | Not a CronCreate parameter; include as a comment inside the prompt for identification |
   | `delivery.channel: "whatsapp"` | Appended to prompt | Add "Send result via WhatsApp reply tool; fallback to memory file if plugin not loaded" |

6. **Adapt prompts** for Claude Code context:
   - Prepend: `"You are running as agent <Name>. Read SOUL.md, IDENTITY.md, USER.md for context. "`
   - Replace `sessions_spawn(...)` → `"Use the Agent tool (one-shot delegation)"`
   - Replace `sessions_send(...)` → `"Use the Agent tool"`
   - Replace `message(...)` → `"Use the messaging plugin's reply tool (or append to memory/$(date +%Y-%m-%d).md if no plugin is loaded)"`
   - Keep `memory_search`/`memory_get` as-is (ClawCode exposes them)
   - If `delivery.channel` is set and the plugin is not installed, append a fallback instruction to the prompt

7. **Show preview** of the conversion to the user:
   ```
   OpenClaw: "Ideas Check-in" | cron 0 14 * * 3,6 | agentTurn | whatsapp
   Local:    "Ideas Check-in" | cron 0 14 * * 3,6 | durable=true | prompt: "You are running as agent Wally. ..."
   ```

8. **After user confirmation**, load the CronCreate schema and create each cron:
   ```
   ToolSearch(query="select:CronCreate")  # first time per session
   CronCreate(
     cron: "<expr>",                       # NOT `schedule`
     prompt: "<adapted message>",
     durable: true,                        # persists to .claude/scheduled_tasks.json
     recurring: <true for cron/every, false for at>
   )
   ```

9. **Report** per-item results:
   ```
   Crons imported (<G+Y>):
     ✅ Ideas Check-in (0 14 * * 3,6)
     ⚠️  meditation (0 2 * * *) — whatsapp channel fallback to memory file

   Skipped (<R>):
     ❌ eva-sync-systemEvent — kind:systemEvent has no Claude Code equivalent
     ❌ cc-task-monitor — payload references `http://192.168.3.102:3123` Control Center HTTP
   ```

## Delivery mapping

OpenClaw crons have a `delivery` field that determines where results go:

| OpenClaw delivery | Claude Code equivalent |
|---|---|
| `mode: "announce"` + `channel: "whatsapp"` | Add to prompt: "Send the result to WhatsApp using the reply tool" |
| `mode: "announce"` + `channel: "telegram"` | Add to prompt: "Send the result to Telegram using the telegram MCP tools" |
| `mode: "none"` | No delivery instruction needed — cron runs silently |
| `mode: "webhook"` | Add to prompt: "POST the result to [webhook URL]" |

## Listing current crons

If the user asks to list crons (not import), use `CronList` to show existing local scheduled tasks.

## Important notes

- Local crons expire after 7 days by default — for permanent crons, the user may need to recreate periodically
- Crons execute while the REPL is idle — Claude Code must be running for them to fire
- Unlike OpenClaw's daemon, Claude Code crons don't fire when Claude Code is closed
- `durable: true` means the cron persists to disk and survives Claude Code restarts within the same project
