---
name: morning-analysis
description: 6 AM briefing — everything pre-cooked for Pablo's day. Prioritized tasks, draft responses, calendar, overnight items. Pablo only decides, never researches. Triggered at 6:03 AM or manually.
user-invocable: true
---

# Morning Briefing (6:00–7:00 AM Block)

Pablo has 1 hour to plan his day. Everything must be ready to decide, not to research.

## What to produce

### 1. Overnight Scan
```bash
gog gmail search "newer_than:12h is:unread" --max 20 --account pablo.huichalaf@aidtogrow.com
wacli messages list --store ~/.wacli-aidtogrow --after "$(date -v-12H +%Y-%m-%dT%H:%M:%SZ)" --limit 30
```

### 2. Calendar Today
```bash
gog calendar events --account pablo.huichalaf@aidtogrow.com --from today --to tomorrow
```

### 3. Open Issues (from Paperclip)
```bash
curl -s "http://localhost:3200/api/companies/68ca43dc-1912-4139-b6ae-56a254cebc9e/issues?status=backlog,in_progress&limit=20" \
  -H "Authorization: Bearer $(cat /Users/pablohuichalaf/Documents/colabs/agent-config.json | python3 -c 'import json,sys;print(json.load(sys.stdin)["paperclip"]["apiKey"])')" \
  -H "Company-Id: 68ca43dc-1912-4139-b6ae-56a254cebc9e"
```

### 4. Yesterday's Unfinished
Read `memory/<yesterday>.md` — extract carry-forward items.

### 5. Draft Responses
For each email that needs a reply, write a draft response (1-3 lines). Pablo approves or edits, then sends.

## Output Format

Log to `memory/<today>.md`:

```markdown
## Morning Briefing — 06:03

### 🔴 Decide Now (before 7 AM)
1. ElevenLabs $2,180 — pagar hoy? [YES/NO]
2. Bryan Kamina v5 — aprobar envío masivo? [YES/NO/FEEDBACK: ...]

### 📋 Execution Block (9-12 AM)
1. [30 min] Revisar business case BPO LATAM → responder CEO
2. [15 min] SII MiSII — corregir DDJJ 1887/1948
3. [20 min] Standup Benjamin 09:00
4. [45 min] Pipeline review — contactar Centinela y Antofagasta

### 📧 Draft Responses (approve/edit/skip)
1. To: Bryan → "v5 aprobado, procede con envío masivo"
2. To: CEO → "Business case revisado, tengo 3 observaciones: ..."
3. To: SII → (no response needed, action in MiSII)

### 📅 Calendar
- 09:00 Standup Benjamin
- 10:30 catch-up aidtogrow
- ...

### 💤 FYI (no action, just context)
- LinkedIn: 1,209 impressions
- Chile IA: discussing Cámara Chilena de IA
```

## Rules
- NEVER send emails or messages — only draft
- Everything pre-cooked: Pablo reads, decides YES/NO, moves on
- Max 5 items in "Decide Now"
- Max 8 items in "Execution Block" with time estimates
- If nothing urgent, say so — don't invent work
