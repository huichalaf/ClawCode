---
name: heartbeat
description: Central orchestrator — every 10 min (8am-8pm) scans Gmail+WhatsApp+Calendar, creates Paperclip tasks, triggers agents, updates knowledge, calls Pablo if urgent. Triggers on /agent:heartbeat.
user-invocable: true
---

# Heartbeat — Central Orchestrator

Every 10 minutes (8am–8pm Chile), runs the full loop:

## Phase 1 — Comms Scan (read-only, never send)

```bash
# WhatsApp
wacli messages list --store ~/.wacli-aidtogrow --after "<10min_ago>" --limit 20
wacli messages list --store ~/.wacli --after "<10min_ago>" --limit 20

# Gmail
gog gmail search "newer_than:15m is:unread" --max 10 --account pablo.huichalaf@aidtogrow.com

# Calendar (check next 2 hours for upcoming meetings)
gog calendar events --account pablo.huichalaf@aidtogrow.com --from now --to "+2h"
```

Classify each item: **URGENT** / **ACTION_NEEDED** / **FYI**

## Phase 2 — Paperclip Task Creation

Config in `agent-config.json`:
- API: `http://localhost:3200`
- Company: Aidtogrow (`68ca43dc-...`)
- Agent: CEO (`3378e022-...`)

For each URGENT or ACTION_NEEDED item, check existing issues:
```bash
curl -s "http://localhost:3200/api/companies/$COMPANY/issues?status=backlog,in_progress" \
  -H "Authorization: Bearer $KEY" -H "Company-Id: $COMPANY"
```

If no matching issue exists → create one:
```bash
curl -s -X POST "http://localhost:3200/api/companies/$COMPANY/issues" \
  -H "Authorization: Bearer $KEY" -H "Company-Id: $COMPANY" \
  -H "Content-Type: application/json" \
  -d '{"title":"[SOURCE] Subject","description":"..."}'
```

## Phase 3 — Agent Execution

For tasks that can be auto-executed (research, analysis, drafts):
```bash
# Wake up CEO to delegate
curl -s -X POST "http://localhost:3200/api/agents/$CEO_ID/wakeup" \
  -H "Authorization: Bearer $KEY" -H "Company-Id: $COMPANY" \
  -H "Content-Type: application/json" \
  -d '{"reason":"Heartbeat: new task AID-XXX"}'
```

**Auto-safe** (execute without asking):
- Research, summarize, analyze
- Draft responses (never send)
- Generate reports
- Update knowledge files

**Needs Pablo** (call him via /call-me):
- Send emails or messages
- Make payments
- Sign or approve documents
- Decisions involving money or legal

## Phase 4 — Feedback Loop (on completed tasks)

Check for recently completed issues:
```bash
curl -s "http://localhost:3200/api/companies/$COMPANY/issues?status=done&updatedAfter=<last_heartbeat>" \
  -H "Authorization: Bearer $KEY" -H "Company-Id: $COMPANY"
```

For each completed task:
1. Read the issue comments (agent's results)
2. Update knowledge base:
   - `memory/pipeline.md` — if deal-related
   - `memory/finances.md` — if financial
   - `memory/contacts.md` — if learned about a contact
   - `memory/substack-ideas.md` — if content-worthy
3. Log to `memory/<today>.md`

## Phase 5 — Alerts (call Pablo if critical)

If URGENT items found AND they need human action:
```
Use /call-me skill to call Pablo at +56954433358
Explain what was found and what action is needed
```

Trigger call for:
- Invoices overdue >7 days
- Client escalations
- System outages
- Tax/legal deadlines

## Phase 6 — Log & State

Update `memory/heartbeat-state.json` and append to `memory/<today>.md`.
If nothing new → stay silent, don't log.

## Paperclip Credentials

Read from `agent-config.json`:
```json
{
  "paperclip": {
    "apiUrl": "http://localhost:3200",
    "apiKey": "pcp_...",
    "companyId": "68ca43dc-...",
    "agentId": "3378e022-..."
  }
}
```

## Schedule

```
*/10 8-20 * * *
```
