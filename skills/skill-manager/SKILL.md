---
name: skill-manager
description: Install, list, and remove community skills from GitHub or local paths. Triggers on /agent:skill, /agent:skill install, /agent:skill list, /agent:skill remove, "instalar skill", "listar skills", "remover skill", "eliminar skill", "agregar skill", "install skill from github".
user-invocable: true
argument-hint: install|list|remove [source-or-name]
---

# Skill Manager

Add community skills to this agent, list what's installed, or remove what you no longer want. A "skill" here is a directory with a `SKILL.md` — the same format Claude Code natively uses — so the exact same artifact works in either place.

This is a CORE feature. See `docs/skill-manager.md` for the full reference.

## Dispatch

Parse the user's command and route to the correct MCP tool:

| User says | Action |
|---|---|
| `/agent:skill install <source>` | Call `skill_install({ source })` |
| `/agent:skill install <source> --scope=<plugin\|project\|user>` | Call `skill_install({ source, scope })` |
| `/agent:skill install <source> --force` | Call `skill_install({ source, force: true })` — only after the user confirms an overwrite |
| `/agent:skill list` | Call `skill_list()` and print the card |
| `/agent:skill remove <name>` | Call `skill_remove({ name })` (dry run) then ask the user to confirm, then call again with `confirm: true` |
| `/agent:skill remove <name> --force` | Call `skill_remove({ name, confirm: true })` directly — no confirmation prompt |

Default scope is `plugin` (`./skills/`). Users can promote a skill later.

## Install flow

1. Validate the source (GitHub shorthand, full URL, or local path — the tool parses all three)
2. Call `skill_install({ source })` — the tool clones, detects format, checks requirements
3. Print the returned card verbatim
4. If `format: openclaw` was detected (rejected), DO NOT retry with `force`. Suggest `/agent:import-skill` and stop.
5. If the skill installed with warnings, remind the user what needs to be set up (missing env var, binary, etc.)

## List flow

1. Call `skill_list()`
2. Print the card. On messaging channels, compress to one line per skill.

## Remove flow

1. Call `skill_remove({ name })` first — this is a dry run; it reports what WOULD be removed
2. Ask the user: "Remove <name> from <dir>? [y/N]" — short and clear
3. If they confirm, call `skill_remove({ name, confirm: true })`
4. If they say no, just acknowledge and stop

If the user passed `--force`, skip step 2 and call directly with `confirm: true`.

## Response style

- Terse. No preamble.
- Install: show the install card (already formatted) then one line of what to do next if warnings.
- List: the card as-is on CLI/WebChat; one line per skill on WhatsApp/Telegram.
- Remove: confirmation prompt → result line.

## Never

- Do NOT run install scripts from cloned repos (no `postinstall`, no `install.sh`). The tool does not run them and neither do you.
- Do NOT try to auto-convert OpenClaw-flavored skills. If the tool rejects one as OpenClaw, direct the user to `/agent:import-skill`.
- Do NOT install without showing the install card — the user needs to see what they're getting.

## References

- `docs/skill-manager.md` — full docs
- `lib/skill-manager.ts` — implementation
- `docs/INDEX.md` — master feature list
