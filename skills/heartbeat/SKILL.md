---
name: heartbeat
description: Central executor — scans comms, RESOLVES issues autonomously, sends low-risk responses, sends drafts to Pablo via WhatsApp for approval on medium/high risk. Triggers on /agent:heartbeat.
user-invocable: true
---

# Heartbeat — Central Executor

Every 15 minutes (8am–8pm Chile). The system RESOLVES, not queues.

## Pablo's Blocks
- 6-7 AM: Morning decisions (YES/NO on drafts)
- 9-12 PM: Execution (strategic work)
- Rest: System resolves autonomously

## Phase 1 — Scan
```bash
gog gmail search "newer_than:15m is:unread" --max 10 --account pablo.huichalaf@aidtogrow.com
wacli messages list --store ~/.wacli-aidtogrow --after "<15min_ago>" --limit 20
gog calendar events --account pablo.huichalaf@aidtogrow.com --from now --to "+2h"
```

## Phase 2 — Resolve (not queue)

For each item:

### If it's something the system CAN resolve alone:
1. Research the topic (search memory, Gmail history, WhatsApp history, web)
2. Prepare the solution
3. If LOW RISK → send response directly (email via SendGrid, WhatsApp via plugin)
4. If MEDIUM/HIGH RISK → send draft to Pablo via WhatsApp plugin:
   ```
   "📋 Borrador para [destinatario]:
   [contenido]
   ¿Envío? OK / NO / edita"
   ```
5. Create/update Paperclip issue
6. Update knowledge base

### If it requires agent work:
1. Create Paperclip issue
2. Wake CEO agent → delegates to MiniMax agent
3. Agent executes (research, analysis, code, reports)
4. Result posted as comment on issue
5. If result needs external communication → draft to Pablo

## Phase 3 — Feedback loop
Check completed Paperclip issues → extract results → update:
- memory/issues.md
- memory/pipeline.md (if deal-related)
- memory/finances.md (if financial)
- memory/assistant-context/ACTIVE_ISSUES.md

## Phase 4 — Alerts (only if critical)
- System down affecting clients → call Pablo
- Active money loss → call Pablo
- Legal deadline TODAY → call Pablo
- Everything else → resolve or draft, never call

## LOW RISK responses (send without asking):
- "Recibido, lo estoy revisando"
- Internal operational confirmations
- Follow-up reminders (no commitments)
- Status updates to team

## MEDIUM/HIGH RISK (draft → WhatsApp to Pablo):
- Client responses with specific content
- Proposals, pricing, conditions
- Anything involving money
- Legal or contractual
- Mass sends (e.g., Kamina mail campaigns)

## Config
- Paperclip: localhost:3200, Company Aidtogrow, CEO agent
- Email: SendGrid (never SES)
- WhatsApp send: plugin (never wacli)
- WhatsApp read: wacli (history) + plugin (live)
- Benjamin does NOT exist. Never assign to him.

## Schedule
```
*/15 8-20 * * *
```
