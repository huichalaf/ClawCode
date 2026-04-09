---
name: import
description: Import an existing OpenClaw agent from its workspace directory into the current project. Triggers on /agent:import, "importar agente", "traer de openclaw", "import agent".
user-invocable: true
argument-hint: [agent-id]
---

# Import an OpenClaw Agent

Import an existing agent from an OpenClaw installation into this directory.

## Steps

1. **List available OpenClaw agents:**
   ```bash
   ls -d ~/.openclaw/workspace* 2>/dev/null
   ```
   
   For each workspace, read IDENTITY.md to show the agent's name:
   - `~/.openclaw/workspace/` — default agent (main)
   - `~/.openclaw/workspace-eva/` — agent "eva"
   - `~/.openclaw/workspace-jack/` — agent "jack"

2. **Let the user choose** which agent to import (or use argument if provided).

3. **Determine the source path:**
   - Default/main: `~/.openclaw/workspace/`
   - Named agent: `~/.openclaw/workspace-{id}/`

4. **Copy bootstrap files** to the current project root:
   ```
   Source: ~/.openclaw/workspace[-{id}]/
   Target: ./ (current directory = project root)
   ```
   
   Files to copy:
   - `SOUL.md`, `IDENTITY.md`, `USER.md`, `AGENTS.md`, `TOOLS.md`, `HEARTBEAT.md`

5. **Import memory** (ask user first):
   - Copy `MEMORY.md` to `./memory/MEMORY.md`
   - Copy recent memory files from `memory/` (skip files older than 30 days)
   - Create `./memory/.dreams/` directory
   - **NEVER copy** `memory/wally-credentials.md` or similar credential files

6. **Adapt AGENTS.md** for Claude Code:
   After copying, add a note at the top and remove/comment sections about:
   - `sessions_spawn`, `message tool`, `browser tool`
   - `gateway`, `cron tool`, OpenClaw CLI commands
   - `HEARTBEAT_OK`, `NO_REPLY`, `ANNOUNCE_SKIP`
   
   Keep: safety rules, behavioral rules (REGLA CARDINAL), memory protocols, learning rules

7. **Reload the agent** to apply imported personality:
   ```
   /mcp
   ```

8. **Report** what was imported and confirm the agent is ready.

## Important

- Never copy credential files (API keys, passwords, tokens)
- Ask before overwriting existing files in the project
- The AGENTS.md adaptation is important — remove OpenClaw tool references, keep behavioral rules
