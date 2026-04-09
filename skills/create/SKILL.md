---
name: create
description: Create a new agent in the current directory with personality files and bootstrap ritual. Triggers on /agent:create, "crear agente", "nuevo agente", "new agent", "create agent".
user-invocable: true
argument-hint: [agent-name]
---

# Create a New Agent

Set up the current directory as an agent workspace with personality files and a bootstrap ritual.

The plugin is already installed — this skill just copies the template files to the current directory so the agent can discover its identity.

## Steps

1. **Copy templates** to the current directory as the agent's initial files:
   ```bash
   cp ${CLAUDE_PLUGIN_ROOT}/templates/SOUL.md ./
   cp ${CLAUDE_PLUGIN_ROOT}/templates/IDENTITY.md ./
   cp ${CLAUDE_PLUGIN_ROOT}/templates/USER.md ./
   cp ${CLAUDE_PLUGIN_ROOT}/templates/AGENTS.md ./
   cp ${CLAUDE_PLUGIN_ROOT}/templates/TOOLS.md ./
   cp ${CLAUDE_PLUGIN_ROOT}/templates/HEARTBEAT.md ./
   ```

2. **Copy the bootstrap file** (the birth certificate):
   ```bash
   cp ${CLAUDE_PLUGIN_ROOT}/templates/BOOTSTRAP.md ./
   ```

3. **Create memory directory:**
   ```bash
   mkdir -p memory/.dreams
   echo '# Memory' > memory/MEMORY.md
   echo '{"version":1,"updatedAt":"","entries":{}}' > memory/.dreams/short-term-recall.json
   ```

4. **Reload the MCP server** to pick up the new files:
   ```
   /mcp
   ```

5. After reconnect, the agent should detect BOOTSTRAP.md and start the bootstrap ritual — a conversational onboarding where it discovers its name, personality, and vibe.

## Important

- Files are created in the **current directory** (where you launched Claude Code)
- BOOTSTRAP.md triggers the first-run ritual — the agent "wakes up" and discovers who it is
- After bootstrap, the agent writes IDENTITY.md, USER.md, adjusts SOUL.md, then deletes BOOTSTRAP.md
- No need to exit Claude Code — `/mcp` reloads everything
- Do NOT fill in IDENTITY.md or USER.md manually — the bootstrap conversation does that
