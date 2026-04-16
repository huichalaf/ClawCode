---
name: heartbeat
description: Central orchestrator — every 10 min (8am-8pm) scans comms, creates Paperclip tasks for actionable items, triggers agent execution, and updates knowledge base on completion. Triggers on /agent:heartbeat.
user-invocable: true
---

# Heartbeat — Central Orchestrator

The heartbeat is the engine that drives everything. Every 10 minutes (8am–8pm), it:
1. Scans communications (WhatsApp + Gmail)
2. Creates Paperclip tasks for actionable items
3. Triggers agents to execute tasks
4. Updates the knowledge base when work completes

## Execution Flow

### Phase 1 — Comms Scan (read-only)

Scan WhatsApp and Gmail for new items since last heartbeat:

```bash
# WhatsApp
wacli messages list --store ~/.wacli-aidtogrow --after "<10min_ago>" --limit 20
wacli messages list --store ~/.wacli --after "<10min_ago>" --limit 20

# Gmail
gog gmail search "newer_than:15m is:unread" --max 10 --account pablo.huichalaf@aidtogrow.com
```

Classify each item: **ACTION_NEEDED**, **URGENT**, or **FYI**.

### Phase 2 — Paperclip Task Creation

For each ACTION_NEEDED or URGENT item, check if a Paperclip task already exists:

```bash
# Search existing tasks via Paperclip MCP or CLI
paperclip_issue(action="list", status="open")
```

If no existing task matches → create one:
```
paperclip_issue(action="create", title="[SOURCE] Subject", description="...")
```

Link the task to the relevant project/client if identifiable:
- Bryan/Kamina emails → project: Kamina
- Daniel Olivares → project: Sales Pipeline
- SII/legal → project: Compliance
- ElevenLabs invoice → project: Finance

### Phase 3 — Agent Execution

For tasks that can be executed autonomously (no human approval needed):
1. Check if a suitable agent exists in Paperclip: `paperclip_agents(action="list")`
2. Assign the task: `paperclip_issue(action="checkout", id=<task_id>, agentId=<agent_id>)`
3. Wake up the agent: `paperclip_agents(action="wakeup", agentId=<agent_id>, reason="Heartbeat: <task summary>")`

Tasks that CAN be auto-executed:
- Research and summarize an email thread
- Review and log document contents
- Analyze data and produce reports
- Draft responses (but NEVER send without approval)

Tasks that CANNOT be auto-executed (flag for Pablo):
- Sending emails or messages
- Making payments
- Signing documents
- Decisions involving money or legal commitments

### Phase 4 — Knowledge Base Update

When a task completes (agent reports back or you finish work):
1. Extract key learnings from the task
2. Update relevant knowledge files:
   - `memory/whatsapp/<contact>.md` — if conversation produced new info
   - `memory/MEMORY.md` — for important decisions or facts
   - `memory/<today>.md` — daily log entry
3. If the task involved a client/project, update project-specific knowledge

### Phase 5 — State & Log

Update `memory/heartbeat-state.json`:
```json
{
  "lastRun": "<ISO timestamp>",
  "itemsScanned": { "whatsapp": 5, "gmail": 3 },
  "tasksCreated": 1,
  "agentsTriggered": 0,
  "knowledgeUpdated": true
}
```

Log summary to `memory/<today>.md`:
```markdown
## Heartbeat — HH:MM
- Scanned: 5 WhatsApp, 3 Gmail
- New: 1 ACTION_NEEDED (Bryan/Kamina v5 review)
- Tasks: created IND-42 in Paperclip
- Agents: none triggered (needs human approval)
```

If nothing new → don't log. Silent heartbeats are fine.

## Active Hours

Only runs 8am–8pm Chile time. Outside this window, skip silently.
Morning analysis (6:03 AM) handles the overnight gap.

## Schedule

```
*/10 8-20 * * *
```

## Architecture

```
  Heartbeat (every 10 min)
      │
      ├── 1. Scan Comms (WhatsApp + Gmail)
      │       └── Classify: URGENT / ACTION / FYI
      │
      ├── 2. Create Paperclip Tasks
      │       └── Link to project/client
      │
      ├── 3. Trigger Agents
      │       ├── Auto-execute if safe
      │       └── Flag for Pablo if needs approval
      │
      ├── 4. Update Knowledge Base
      │       └── On task completion
      │
      └── 5. Log & State
```
