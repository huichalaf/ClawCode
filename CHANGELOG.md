# Changelog

## [Unreleased]

## [1.3.0] — 2026-04-15

### Thanks

- **[@JD2005L](https://github.com/JD2005L)** for the thorough write-up in [#4](https://github.com/crisandrews/ClawCode/issues/4) — 13 friction points from running ClawCode 24/7 as a systemd service with Telegram on Debian LXC. This release addresses 7 of them directly (item 1 TTY bypass-dialog hang, item 6 multi-instance race on restart, item 10 config-edit MCP drop, item 11 stale plugin paths after user switch, item 12 stale FTS index after import, plus item 5 groundwork via the new opt-in watchdog which is the testable answer to "plugin subprocess dies silently"). Items deferred to future iterations are parked in `ideas/`.

### Fixed
- `memory_search` now picks up files added or edited during a session. Previously the FTS index was only re-synced on the first search after MCP startup or via `/agent:doctor --fix` — files added mid-session (e.g. by `/agent:import` while a session was running, or new WhatsApp / Telegram conversation logs landing under an `extraPaths` directory) stayed invisible until restart. Root cause: the `dirty` flag in `MemoryDB` was initialized to `true` (so the first search synced) but `markDirty()` had no external callers, so subsequent file changes never triggered a re-sync. Fix: the `MemoryDB` constructor now sets up an `fs.watch` on `memory/` (top-level) and on each entry in `memory.extraPaths` (recursive on macOS / Windows; top-level only on Linux due to a Node `fs.watch` limitation). Any `.md` create / edit / rename / delete marks the index dirty so the next search re-syncs. Best-effort with a `try/catch` fallback per watcher — if a watcher cannot be created (missing path, NFS, watcher limits), the existing dirty-on-startup behavior + `/agent:doctor --fix` still cover the user. Reported by [@JD2005L](https://github.com/JD2005L) in [#4](https://github.com/crisandrews/ClawCode/issues/4) item 12; the user's stated symptom ("only `MEMORY.md` indexed after import") was an indirect effect of this bug.

### Added
- `/agent:service install` now pre-checks `~/.claude/settings.json` before writing any service files. If `skipDangerousModePermissionPrompt: true` is missing, the skill explains the consequence (silent hang at startup with no TTY to answer the bypass dialog) and offers to add it via a `jq`-based atomic merge that preserves any existing keys. Decline once and the skill warns; decline twice and install aborts cleanly without touching launchd / systemd. Cross-platform: same fix applies to macOS launchd and Linux systemd because the file is `~/.claude/settings.json` on both.
- **Watchdog (optional)**: new `recipes/watchdog/` folder with an opt-in external health probe for always-on services. A short-lived `watcher.sh` runs every 5 min (via systemd user timer on Linux or launchd `StartInterval` on macOS) and performs up to **5 tiered checks** — service-manager status, HTTP bridge `/health`, new ClawCode `/watchdog/mcp-ping` endpoint, scoped `pgrep -P <main-pid>` against expected channel plugins, and new `/watchdog/llm-ping` which injects a `__watchdog_ping__ PONG-<nonce>` message and polls chat history for the agent's echo to verify the LLM is responding end-to-end. First failing tier short-circuits and triggers `--on-fail` (default: restart) plus optional `--alert-cmd` (Telegram Bot API helper + generic template shipped). New `watchdog_ping` MCP tool and both HTTP routes refuse non-loopback requests regardless of `http.host` (belt-and-suspenders middleware) and inherit the bridge's token auth. Tier 5 LLM ping additionally requires `http.token` (token-drain protection) and is rate-limited to 1/hour per token; watcher also guards with its own `--llm-ping-interval` (default 3600s). Installers auto-detect label / port / token / installed plugins; typical install asks zero or one question. Does not touch the running service during install. Full docs: [`docs/watchdog.md`](docs/watchdog.md). Reported by [@JD2005L](https://github.com/JD2005L) in [#4 item 5](https://github.com/crisandrews/ClawCode/issues/4).
- **Public helper** `isLoopbackAddress(addr: string | undefined): boolean` exported from `lib/http-bridge.ts`. Pure classifier used internally by `/watchdog/*` routes to refuse non-loopback peers (covers IPv4, IPv6, IPv4-mapped-IPv6). External code may consume it; small surface, no runtime behavior change vs. prior inline version.
- `lib/service-generator.ts` now emits `ExecStartPre=-/usr/bin/pkill -f "claude.*--dangerously-skip-permissions"` in the systemd unit on Linux. Prevents the multi-instance race condition where a restart leaves the old `claude` briefly alive next to the new one and both connect to the same channel, fighting for incoming messages. The `-f` filter only matches service-mode invocations, so an interactive `claude` session in another terminal is left alone. macOS plist is unchanged — launchd already guarantees single-instance per Label. Existing installs do not benefit automatically; reinstall (`/agent:service uninstall` + `/agent:service install`) to regenerate the unit. Reported by [@JD2005L](https://github.com/JD2005L) in [#4](https://github.com/crisandrews/ClawCode/issues/4).

### Documentation
- `docs/service.md` — added a "Heads-up" note inside the safety trade-off section and a troubleshooting row explaining that `--dangerously-skip-permissions` alone is not enough under launchd / systemd: bypass mode shows an interactive `WARNING: Bypass Permissions mode — Do you accept?` dialog at startup that a daemon has no TTY to answer, so the service hangs silently before reaching the listening state. Fix: persist `"skipDangerousModePermissionPrompt": true` in `~/.claude/settings.json` before installing the service. Tracked upstream as [anthropics/claude-code#25503](https://github.com/anthropics/claude-code/issues/25503). Only affects service mode; interactive `claude` is unaffected.
- `docs/service.md` — troubleshooting row noting that editing `~/.claude/settings.json` while the service runs reloads MCPs and some plugins (Telegram observed) do not reconnect, leaving the service "active" but dropping messages. Fix: restart the service after any manual edit. Reported by [@JD2005L](https://github.com/JD2005L) in [#4](https://github.com/crisandrews/ClawCode/issues/4).
- `docs/doctor.md` — added "Issues NOT auto-fixed" entry for "unknown skill" errors caused by stale plugin paths in `~/.claude/plugins/installed_plugins.json` after a runtime user change. The file is Claude Code internal (ClawCode does not own it), so doctor cannot safely auto-rewrite. Documented manual `jq` fix (validated by [@JD2005L](https://github.com/JD2005L) in [#4](https://github.com/crisandrews/ClawCode/issues/4)).
- `docs/watchdog.md` — new full user guide for the optional watchdog recipe.
- `docs/INDEX.md` — watchdog row added under "Optional".
- `docs/memory.md` — rewrote the three lines that claimed "re-syncs on next search" to reflect the actual behavior after the `fs.watch` fix; added a paragraph to the `extraPaths` section about the Linux recursive-watch caveat.
- `README.md` — mascot image added above the title; watchdog link added after the always-on-service section.
- `assets/clawcode.png` (new) — mascot artwork used by the README.

## [1.2.2] — 2026-04-13

### Thanks
- @JD2005L for reporting [#1](https://github.com/crisandrews/ClawCode/issues/1) — the investigation into your report surfaced a bug that affected every user silently. Fix below.

### Fixed (GitHub issue #1)
- **Reminders now persist across session closes.** Previously the SessionStart hook relied on a `.crons-created` marker that persisted on disk while the crons themselves died with the session, so heartbeat / dreaming / imported / ad-hoc crons silently disappeared after every restart. The new system keeps a registry at `memory/crons.json` and reconciles it against the live harness on every SessionStart — anything missing is recreated, anything live-but-unknown is adopted.
- **Ad-hoc reminders ("remind me in 4 hours to X") survive restarts.** A PostToolUse hook captures every `CronCreate` call and writes it to the registry; next session, reconcile recreates it.
- **User deletions stay deleted.** `CronDelete` tombstones the registry entry; reconcile skips it.

### Added
- `/agent:crons` skill extended with subcommand dispatcher: `list`, `add`, `delete`, `pause`, `resume`, `reconcile`, plus existing `import`. Aliases: `/agent:reminders`, "list reminders", "show crons", "recordatorios", "mis crons".
- `skills/crons/writeback.sh` — single writer for `memory/crons.json`. Subcommands: `seed-defaults`, `upsert`, `tombstone`, `set-alive`, `adopt-unknown`, `pause`, `resume`, `migration-mark`. Lockfile-protected, atomic-write.
- `hooks/reconcile-crons.sh` — SessionStart hook. Seeds defaults, detects migration need, emits a deterministic reconcile envelope for the agent to execute. Degraded-mode fallback if `jq` is missing.
- `hooks/cron-posttool.sh` — PostToolUse hook on `CronCreate`/`CronDelete`. Captures ad-hoc crons; tombstones on delete. Idempotent via `harnessTaskId` key. Suppressed during reconcile via `memory/.reconciling` marker.
- Migration flow for upgraders who had OpenClaw imports: SessionStart detects `IMPORT_BACKLOG.md` + `~/.openclaw/cron/jobs.json` and offers re-import via native `AskUserQuestion` (Sí / Después / No nunca). Answer persisted in `migration.openclawAnsweredAt`; auto-flagged if user runs `/agent:crons import` manually.
- `docs/crons.md` — user-facing documentation: registry schema, commands, harness assumptions, failure modes.
- Doctor adds two checks: `cron-registry` (parseable + stale tombstone count) and `jq` (presence).
- Tests: `tier1m-cron-registry.sh` (18 unit tests for writeback), `tier2q-reconcile-hook.sh` (10 integration tests for reconcile hook), `tier2r-cron-posttool.sh` (10 integration tests for posttool hook), plus `tests/stubs/Cron{Create,List,Delete}.sh` fakes.

### Removed
- Inline "MANDATORY ACTION REQUIRED" bash block in SessionStart hook — replaced with a single `bash ${CLAUDE_PLUGIN_ROOT}/hooks/reconcile-crons.sh` invocation.
- `server.ts` bootstrap context's inline `CronCreate(..., durable=true)` instructions — replaced with a short reference to the reconcile flow.
- `skills/import/SKILL.md` Step B no longer tells the agent to call CronCreate directly — delegates to `writeback.sh seed-defaults`.
- Legacy `.crons-created` marker at workspace root is now cleaned up automatically by reconcile-crons.sh on first run (kept in `.gitignore` so users mid-upgrade don't accidentally commit it).

## [1.2.1] — 2026-04-13

### Security
- Token is now **required** when HTTP bridge binds to non-localhost (`host != 127.0.0.1`). Bridge refuses to start without one.
- WebChat HTML now requires auth when token is configured (was served without auth before).

### Added
- Webhook tutorials: Cloudflare Email Worker catch-all, Gmail push via Pub/Sub (full code + setup steps)
- Webhook use cases linked from README to detailed docs
- Self-managing heartbeat: agent edits `HEARTBEAT.md` with initiative during conversations
- Lightweight `HEARTBEAT.md` template (5 lines, not 50)
- Heartbeat state tracking via `memory/heartbeat-state.json`
- Plugin update workaround in README (manual method when `/plugin update` says "already at latest")

### Fixed
- Heartbeat template was too heavy — moved behavioral rules to AGENTS.md and skill, kept only the checklist in HEARTBEAT.md

## [1.2.0] — 2026-04-13

### Fixed
- Silent `npm install` failure — errors are now visible instead of "Failed to reconnect" with no explanation
- Dependencies only install if not already present (faster subsequent sessions)

### Added
- Cron persistence limitation documented in troubleshooting

## [1.1.0] — 2026-04-12

### Added
- Active memory with bilingual recall (ES ↔ EN, 40+ synonym pairs)
- Date expansion in memory queries ("hoy" → today's date)
- Voice TTS/STT (sag, ElevenLabs, OpenAI, macOS say, Whisper)
- WebChat browser UI with SSE real-time delivery
- Conversation logging in JSONL + Markdown (same format as WhatsApp plugin)
- HTTP bridge with status/skills/webhook/chat endpoints
- Live config — non-critical settings apply without `/mcp`
- Channel detector + launch command builder
- Command discovery (dynamic `/help`)
- `/doctor` diagnostics with `--fix` auto-repair
- Skill manager — install from GitHub with `owner/repo@branch#subdir`
- Service manager (launchd/systemd)
- AskUserQuestion wizard for import/create flows
- Clean imports — no file annotations, all notes go to IMPORT_BACKLOG.md
- Terse agent behavior by default
- Lifecycle hooks documented (SessionStart, PreCompact, Stop, SessionEnd)
- Language adaptation — responds in user's language

### Fixed
- `CronCreate` parameter is `cron`, not `schedule`
- `CronCreate` is a deferred tool — needs `ToolSearch` first
- Bilingual memory recall: `recencyBoost` was passing `ageDays` instead of `filePath`
- FTS5 query changed from AND to OR (improves cross-language recall)

## [1.0.0] — 2026-04-09

### Added
- Initial release
- Persistent identity (SOUL.md, IDENTITY.md, USER.md)
- Memory system (SQLite + FTS5, temporal decay, MMR)
- QMD optional backend (local embeddings)
- Dreaming (3-phase: Light, REM, Deep with 6 weighted signals)
- Heartbeat (30-min periodic checks)
- Bootstrap ritual (conversational onboarding)
- Import from existing agent workspaces
- Skills: create, import, crons, heartbeat, settings, messaging, status, usage, new, compact, help, whoami
- Hooks: SessionStart, PreCompact, Stop, SessionEnd
- Messaging channel support (WhatsApp, Telegram, Discord, iMessage, Slack)
