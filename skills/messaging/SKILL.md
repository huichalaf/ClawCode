---
name: messaging
description: Set up a messaging channel (WhatsApp, Telegram, Discord, iMessage, Slack) to reach this agent from outside Claude Code. Triggers on /agent:messaging, "configurar whatsapp", "setup messaging", "conectar telegram", "agregar canal".
user-invocable: true
argument-hint: [platform]
---

# Set Up a Messaging Channel

This skill connects your agent to a messaging platform so you can chat with it from your phone or desktop messaging apps.

## Available platforms

| # | Platform | Marketplace | Notes |
|---|---|---|---|
| 1 | **WhatsApp** ⭐ | `crisandrews/claude-whatsapp` | Recommended. Rich access control, voice transcription. |
| 2 | **Telegram** | `claude-plugins-official` | Official Bot API. Pairing-based access. |
| 3 | **Discord** | `claude-plugins-official` | Threading, rich reactions, guild support. |
| 4 | **iMessage** | `claude-plugins-official` | macOS only. Reads chat.db natively. |
| 5 | **Slack** | `claude-plugins-official` | Workspace-based, OAuth. |

## Steps

1. **Ask the user** which platform they want (unless specified in the argument).
   Default recommendation: WhatsApp.

2. **Check if the plugin is already installed**:
   ```bash
   ls ~/.claude/plugins/cache/ 2>/dev/null | grep -iE "whatsapp|telegram|discord|imessage|slack"
   ```

3. **Show the user the exact commands to run** in the Claude Code REPL. The agent CANNOT execute `/plugin marketplace add` or `/plugin install` — these are REPL-only commands. Just show them clearly:

### WhatsApp (crisandrews/claude-whatsapp)
```
/plugin marketplace add crisandrews/claude-whatsapp
/plugin install whatsapp@claude-whatsapp
/exit
```
Then relaunch with the channels flag:
```sh
claude --dangerously-load-development-channels plugin:whatsapp@claude-whatsapp
```
Then in Claude Code:
```
/whatsapp:configure
```
Follow the QR code prompt.

### Telegram (official)
```
/plugin marketplace add anthropics/claude-plugins-official
/plugin install telegram@claude-plugins-official
```
Create a bot via @BotFather on Telegram, get the token, then:
```
/telegram:configure <your-bot-token>
```

### Discord (official)
```
/plugin marketplace add anthropics/claude-plugins-official
/plugin install discord@claude-plugins-official
```
Create a Discord bot, get the token, then:
```
/discord:configure <your-bot-token>
```

### iMessage (official, macOS only)
```
/plugin marketplace add anthropics/claude-plugins-official
/plugin install imessage@claude-plugins-official
```
Requires granting Full Disk Access to Claude Code in System Settings → Privacy.

### Slack (official)
```
/plugin marketplace add anthropics/claude-plugins-official
/plugin install slack@claude-plugins-official
/slack:configure
```
Follow the OAuth flow.

## How it works with ClawCode

- **Both plugins coexist** — each is an independent MCP server. No conflicts.
- **Your personality applies** — when a message arrives, you respond as yourself (from SOUL.md + IDENTITY.md), not as a generic Claude.
- **Formatting is automatic** — each messaging plugin injects its own format rules (e.g., WhatsApp uses `*bold*`, not `**bold**`).
- **Memory is shared** — what the user tells you via WhatsApp is saved to `memory/YYYY-MM-DD.md` just like in terminal.

## Important

- The agent CANNOT install plugins directly. Show the user the commands and explain they must run them.
- After installing a messaging plugin, the user must restart Claude Code for it to connect.
- Verify the installation with `/mcp` — both `clawcode` and the new plugin should appear.
- For WhatsApp, the first connection requires scanning a QR code on the user's phone.
- Access control is per-plugin — the user configures who can reach the agent via each plugin's `access` skill.

## After setup

Tell the user:
1. Restart Claude Code with the appropriate channels flag
2. Run `/mcp` to verify both plugins are connected
3. Send a test message from their phone
4. The agent should respond with its personality (not generic Claude)
