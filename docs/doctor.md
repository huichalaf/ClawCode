# Doctor — diagnostics and auto-repair

The doctor inspects the health of a ClawCode agent workspace and, on request, applies safe auto-fixes for common issues. Equivalent in spirit to `openclaw doctor`.

## When to run it

- Right after `/agent:create` or `/agent:import` — confirm setup is clean
- When something feels off (memory search returns nothing, crons not firing, HTTP bridge unreachable)
- After toggling a config value — verify the change took effect
- Periodically — as a health heartbeat, though not required

## Commands and tools

| Surface | Invocation | Effect |
|---|---|---|
| Slash (skill) | `/agent:doctor` | Runs full diagnostics and prints a card |
| Slash (skill) | `/agent:doctor --fix` | Applies safe fixes, then re-runs diagnostics |
| MCP tool | `agent_doctor(action: "check")` | Returns structured report (JSON) |
| MCP tool | `agent_doctor(action: "fix")` | Applies safe fixes + re-checks |

The skill is the preferred surface for humans. The MCP tool exists so WebChat, HTTP API, or other agents can invoke it programmatically.

## Checks performed

| ID | Label | What it inspects | Status values |
|---|---|---|---|
| `config` | Config | `agent-config.json` exists + valid JSON | `ok` / `info` (using defaults) / `error` (malformed) |
| `identity` | Identity | SOUL.md, IDENTITY.md, USER.md present and non-empty | `ok` / `warn` (empty) / `error` (missing) |
| `memory-dir` | Memory dir | `memory/` exists and is writable; counts md files | `ok` / `warn` / `error` |
| `sqlite` | SQLite | FTS5 DB opens + stats retrievable | `ok` / `error` |
| `qmd` | QMD | Only checked if `memory.backend: "qmd"` — binary in PATH | `ok` / `error` / `off` (not configured) |
| `bootstrap` | Bootstrap | `BOOTSTRAP.md` still present despite identity being filled | `ok` / `warn` (stale) / `info` (in progress) |
| `http` | HTTP bridge | Pings `/health` if `http.enabled: true` | `ok` / `error` (unreachable) / `off` |
| `messaging` | Messaging | Detects installed channel plugins in `~/.claude/plugins/cache/` | `info` / `off` |
| `dreaming` | Dreaming | Recall tracking state + DREAMS.md presence | `info` / `off` |

## Auto-fixes (safe only)

When `action: "fix"` is invoked, these fixes run without human confirmation because they are idempotent and cannot destroy work:

| Fix | Condition | Action |
|---|---|---|
| `memory-dir` | `memory/` does not exist | Creates `memory/` and `memory/.dreams/` |
| `sqlite` | Always | Runs `MemoryDB.sync()` — indexes new files, skips unchanged |
| `bootstrap` | `BOOTSTRAP.md` exists AND IDENTITY.md has real name (not placeholder) | Deletes stale `BOOTSTRAP.md` |

Issues NOT auto-fixed (require human decision):
- Malformed `agent-config.json` — user fixes JSON or deletes file
- Missing identity files — run `/agent:create` or `/agent:import`
- QMD binary missing — install it per `/agent:settings`
- HTTP bridge not reachable — run `/mcp` to restart MCP server
- "Unknown skill" errors after a runtime user change (e.g. ran `claude` as `root`, then switched the service to a non-root user) — `~/.claude/plugins/installed_plugins.json` is a Claude Code internal file and still references the previous user's home (`/root/.claude/...`). ClawCode does not write or own this file, so the doctor cannot safely auto-rewrite it. Two manual fixes: (a) reinstall plugins under the new user, or (b) `jq`-rewrite the paths in place: `jq --arg new "$HOME/.claude" --arg old "/root/.claude" 'walk(if type=="string" then sub($old; $new) else . end)' ~/.claude/plugins/installed_plugins.json > tmp && mv tmp ~/.claude/plugins/installed_plugins.json`. Reported by [@JD2005L](https://github.com/JD2005L) in [#4](https://github.com/crisandrews/ClawCode/issues/4).

The diagnostic report includes a `hint` field for every non-OK check that tells the user (or agent) what to do.

## Output format

### `check` action

```
🩺 Agent Diagnostics

✅  Config        agent-config.json valid
✅  Identity      SOUL, IDENTITY, USER all present
✅  Memory dir    writable · 42 md files · 1248.3 KB
✅  SQLite        integrity OK · 42 files, 312 chunks indexed
⏸️  QMD           not configured (using builtin)
✅  Bootstrap     complete
⏸️  HTTP bridge   disabled
                  → Enable via /agent:settings to get WebChat + webhooks
ℹ️  Messaging     detected: whatsapp
ℹ️  Dreaming      12 memories tracked · DREAMS.md exists · last update 2026-04-11

All checks passed. Nothing to fix.
```

### `fix` action

Produces a fix section plus the post-fix report:

```
🔧 Doctor fix

✅ memory-dir: created memory/ and memory/.dreams/
✅ sqlite: indexed 3, unchanged 0, removed 0

Skipped:
⏸️  bootstrap: no BOOTSTRAP.md to remove

--- Post-fix diagnostics ---

🩺 Agent Diagnostics
...
```

## Implementation

| File | Role |
|---|---|
| `lib/doctor.ts` | All check and fix functions, plus `runDoctor()`, `runDoctorFix()`, `formatReport()`, `formatFixReport()` |
| `server.ts` | `agent_doctor` MCP tool dispatches to `runDoctor` / `runDoctorFix` |
| `skills/doctor/SKILL.md` | Triggers, invokes the MCP tool, also runs `CronList` (REPL-only) for cron status that the tool can't see |

## Checks the MCP tool cannot do

The MCP server process doesn't have access to Claude Code's runtime state, so these checks live in the skill file and run via REPL-only tools:

- **Cron status** — the skill calls `CronList` to confirm heartbeat and dreaming crons exist, then merges that into the report
- **Hook activity** — inferred from `hooks/hooks.json` existence + whether `.crons-created` marker is present

## Extending

To add a new check:

1. Write a function in `lib/doctor.ts` returning `DiagnosticCheck`
2. Add it to `runDoctor()` in the checks array
3. If it has a safe auto-fix, add a function and wire into `runDoctorFix()`
4. Add a row to the "Checks performed" table above
5. Update this doc in the same commit
