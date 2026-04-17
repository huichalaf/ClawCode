---
name: heartbeat
description: Central orchestrator — scans comms, creates Paperclip tasks, triggers agents, sends issue digest by email, updates memory/issues.md, calls Pablo if urgent. Accepts commands via Telegram. Triggers on /agent:heartbeat.
user-invocable: true
---

# Heartbeat — Central Orchestrator

Every 10 minutes (8am–8pm Chile). Full autopilot loop.

## Phase 1 — Comms Scan (read-only)

```bash
# WhatsApp
wacli messages list --store ~/.wacli-aidtogrow --after "<10min_ago>" --limit 20
wacli messages list --store ~/.wacli --after "<10min_ago>" --limit 20

# Gmail
gog gmail search "newer_than:15m is:unread" --max 10 --account pablo.huichalaf@aidtogrow.com

# Calendar (next 2 hours)
gog calendar events --account pablo.huichalaf@aidtogrow.com --from now --to "+2h"
```

Classify: **URGENT** / **ACTION_NEEDED** / **FYI**

## Phase 2 — Paperclip Issues + Memory

For URGENT/ACTION items, create Paperclip issue:
```bash
curl -s -X POST "http://localhost:3200/api/companies/$COMPANY/issues" \
  -H "Authorization: Bearer $KEY" -H "Company-Id: $COMPANY" \
  -H "Content-Type: application/json" \
  -d '{"title":"[SOURCE] Subject","description":"..."}'
```

**ALWAYS update `memory/issues.md`** — this is the persistent tracker:
- Add new issues to the Open table
- Move completed issues to Recently Closed
- This file is how future conversations know what's going on

Config (from `agent-config.json`):
- API: `http://localhost:3200`
- Company: `68ca43dc-1912-4139-b6ae-56a254cebc9e`
- CEO Agent: `3378e022-e2cd-4d27-941b-f3da89f99801`

## Phase 3 — Email Digest (SendGrid)

When new issues are created, send digest email via SendGrid (python):
- **To**: pablo.huichalaf@aidtogrow.com
- **From**: pablo.huichalaf@aidtogrow.com (name: "ClawCode Heartbeat")
- **Subject**: 🔔 [N issues] brief summary
- **Body**: HTML table with URGENT (red), ACTION (yellow), FYI (gray)
- **Footer**: "Responde con: cerrar AID-XXX, ignorar AID-XXX, priorizar AID-XXX"

Use the `/send-email` skill or direct SendGrid API. NEVER use AWS SES.

Only send when there are NEW issues since last email. Don't spam.

## Phase 4 — Agent Execution

Wake CEO to delegate auto-safe tasks:
```bash
curl -s -X POST "http://localhost:3200/api/agents/$CEO_ID/wakeup" \
  -H "Authorization: Bearer $KEY" -H "Company-Id: $COMPANY" \
  -H "Content-Type: application/json" \
  -d '{"reason":"Heartbeat: new task AID-XXX"}'
```

**Auto-safe**: research, analysis, drafts, reports, knowledge updates
**Needs Pablo**: send emails, payments, approvals, legal, money decisions → call him

## Phase 5 — Feedback Loop

Check completed issues:
```bash
curl -s "http://localhost:3200/api/companies/$COMPANY/issues?status=done" \
  -H "Authorization: Bearer $KEY" -H "Company-Id: $COMPANY"
```

For each newly completed:
1. Read comments (agent results)
2. Update `memory/issues.md` — move to Recently Closed
3. Update knowledge: `memory/pipeline.md`, `memory/finances.md`, `memory/contacts.md`
4. Log to `memory/<today>.md`

## Phase 6 — Telegram Commands

The gateway (port 18789) receives Telegram messages. When Pablo sends commands:
- **"cerrar AID-XXX"** → close issue in Paperclip, update memory/issues.md
- **"ignorar AID-XXX"** → add to ignored list, stop tracking
- **"priorizar AID-XXX"** → set priority to urgent
- **"asignar AID-XXX a [agent]"** → checkout issue to that agent
- **"status"** → list open issues
- **"qué hay pendiente"** → summary of urgent items

These commands come through the gateway's default bot (Telegram ID: 8585412296).

## Phase 7 — Call Pablo (/call-me)

For URGENT items needing human action:
```
Use /call-me skill
Phone: +56954433358
Agent: agent_0901kjmfam09ftmtstry20h33z1c
```

Trigger call for: invoices >7 days overdue, client escalations, system outages, legal deadlines.

## Phase 8 — Silent if nothing new

If no new items since last heartbeat → don't log, don't email, don't call. Silent.

## Schedule
```
*/10 8-20 * * *
```
