---
name: morning-analysis
description: Daily 6 AM briefing — reviews yesterday's activity, pending items, inbox, calendar, and produces a prioritized daily plan with improvement notes. READ-ONLY. Triggered by cron at 6:03 AM or manually via "/agent:morning-analysis".
user-invocable: true
---

# Morning Analysis — Daily Briefing

You run at 6 AM every day. Your job: review everything from yesterday, check what's ahead today, and produce a structured daily plan. READ-ONLY — never send anything.

## Execution Steps

### 1. Review Yesterday's Logs

Read yesterday's memory file:
```bash
cat memory/$(date -v-1d +%Y-%m-%d).md 2>/dev/null || echo "No log from yesterday"
```

Extract:
- All ACTION_NEEDED items — were they resolved?
- All URGENT items — still pending?
- Patterns: what types of items keep recurring?

### 2. Gmail Overview

```bash
gog gmail search "newer_than:1d is:unread" --max 20 --account pablo.huichalaf@aidtogrow.com
gog gmail search "newer_than:1d is:starred" --max 10 --account pablo.huichalaf@aidtogrow.com
```

Categorize:
- **Must respond today** — emails from clients, partners, team with questions
- **Review needed** — reports, documents, invoices
- **Can wait** — newsletters, promotions

### 3. Calendar Check

```bash
gog calendar list --from today --to tomorrow --account pablo.huichalaf@aidtogrow.com
```

Note meetings, deadlines, and preparation needed.

### 4. WhatsApp Pending

```bash
wacli messages list --store ~/.wacli-aidtogrow --after "$(date -v-1d +%Y-%m-%d)" --limit 30
wacli messages list --store ~/.wacli --after "$(date -v-1d +%Y-%m-%d)" --limit 30
```

Flag unanswered DMs and active group threads.

### 5. Self-Improvement Review

Look at the last 3 days of memory files and identify:
- Items that stayed ACTION_NEEDED for more than 1 day
- Scans that found nothing (were they at the right time?)
- Patterns in what gets flagged vs acted on

### 6. Produce Daily Plan

Log to `memory/<today>.md`:

```markdown
## Morning Briefing — 06:03

### Today's Priority Stack
1. [URGENT] ElevenLabs invoice $2,180 — 17 days overdue, pay today
2. [CLIENT] Bryan/Kamina — review v5 mail previews, approve or feedback
3. [INTERNAL] CEO business case BPO LATAM — read and respond
4. [MEETING] 10:00 — Client call (prepare deck)

### Unresolved from Yesterday
- Daniel Olivares pipeline update — no response on Centinela/Antofagasta
- Prospect that didn't reply to Daniel — needs escalation decision

### Gmail Quick Hits (respond before 9 AM)
- Bryan Paredes: mail morosos test
- Mercury: security check-in

### Improvement Notes
- WhatsApp sync still broken — investigate alternative or fix wacli auth
- 3 scans yesterday found no new WhatsApp data — wasted cycles
```

## Rules

- **NEVER send messages or emails** — analysis only
- Be concise — the plan should fit on one screen
- Prioritize by: URGENT > CLIENT > INTERNAL > FYI
- If yesterday had no log, note it and start fresh
- Don't repeat FYI items from yesterday unless they became actionable

## Schedule

Daily at 6:03 AM (Chile time)
```
3 6 * * *
```
