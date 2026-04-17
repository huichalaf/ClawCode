---
name: end-of-block
description: 12 PM wrap-up — summarizes what got done, carries forward unfinished items, sends email digest, updates issues. Triggered at 12:00 PM or manually.
user-invocable: true
---

# End of Block (12:00 PM)

Pablo's done for the day. Wrap up everything.

## Steps

### 1. What got done
Read `memory/<today>.md` — compare morning task list vs what was actually completed.

### 2. Update Paperclip issues
For tasks Pablo completed:
```bash
curl -s -X PATCH "http://localhost:3200/api/issues/$ID" \
  -H "Authorization: Bearer $KEY" -H "Company-Id: $COMPANY" \
  -H "Content-Type: application/json" \
  -d '{"status":"done"}'
```

### 3. Carry forward
Unfinished items → create or update in `memory/issues.md` with note "carry → tomorrow"

### 4. Scan what came in during 9-12
```bash
gog gmail search "newer_than:3h is:unread" --max 10 --account pablo.huichalaf@aidtogrow.com
```
Classify and queue for tomorrow's morning briefing.

### 5. Email digest
Send via SendGrid:
- Subject: "📊 Día completado — X de Y tareas"
- Body: done list, carry-forward list, new items queued

### 6. Update knowledge
- `memory/issues.md` — move completed to closed
- `memory/pipeline.md` — if any deal progressed
- `memory/assistant-context/ACTIVE_ISSUES.md` — refresh

## Output

Append to `memory/<today>.md`:

```markdown
## End of Block — 12:00

### Done ✅
1. ✅ Standup Benjamin — discussed Kamina migration
2. ✅ SII DDJJ corrected in MiSII
3. ✅ Approved Bryan v5 mail

### Carry Forward → Tomorrow
1. ⏭ BPO LATAM business case (no time)
2. ⏭ Call Daniel re: pipeline

### New Items (queued for tomorrow)
1. [Gmail] New invoice from GCP
2. [WhatsApp] Benjamin asks about deploy

### Stats
- Planned: 5 tasks | Done: 3 | Carry: 2
- Emails received: 7 | Responded: 2 | Queued: 5
```

## After this runs
The heartbeat continues scanning 12-8 PM but only queues — never interrupts Pablo unless URGENT (invoice overdue, client escalation, system down).
