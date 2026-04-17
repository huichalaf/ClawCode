---
name: execution-prep
description: 8:57 AM prep — refreshes everything for Pablo's 9-12 execution block. New emails since morning, tasks ready, calendar. One screen. Triggered at 8:57 AM or manually.
user-invocable: true
---

# Execution Block Prep (8:57 AM)

Pablo's 3-hour execution window starts at 9. Give him a refreshed, one-screen view.

## What to produce

### 1. What changed since 7 AM
```bash
gog gmail search "newer_than:2h is:unread" --max 10 --account pablo.huichalaf@aidtogrow.com
```
Only show NEW items, not repeats from morning briefing.

### 2. Tasks for this block
Read today's morning briefing from `memory/<today>.md` → extract the "Execution Block" list.
Cross-check: did Pablo already handle any during the 6-7 block?

### 3. Calendar 9-12
```bash
gog calendar events --account pablo.huichalaf@aidtogrow.com --from "9:00" --to "12:00"
```

### 4. Quick wins
Anything that takes <5 min and can be knocked out first.

## Output

Append to `memory/<today>.md`:

```markdown
## Execution Prep — 08:57

### New since morning
- [Gmail] 2 new emails (none urgent)

### Task Stack (do in order)
1. ⏰ 09:00 Standup Benjamin (15 min)
2. 🔴 SII DDJJ correction (20 min)
3. 📧 Respond CEO BPO LATAM (30 min)
4. 📞 Call Daniel re: Centinela pipeline (15 min)
5. 📋 Review Kamina v5 previews (10 min)

### Quick wins (do between meetings)
- Approve Bryan's mail → 1 click
- Read IBKR newsletter → skip or save

### Time budget: 3h = 180 min, scheduled: 90 min, buffer: 90 min
```

## Rules
- Keep it to ONE screen
- Time estimates on every task
- Show remaining buffer
- Don't repeat morning briefing items already decided
