# Skill Manager — install, list, remove skills

Add community skills to your agent from GitHub or a local directory, list what's installed, or remove what you no longer want.

A skill is a directory with a `SKILL.md` (YAML frontmatter + markdown instructions). This is the same format Claude Code natively supports — our agent uses a subset of the spec, but the artifact is interchangeable with standalone Claude Code skills.

## Commands and tools

| Surface | Invocation | Effect |
|---|---|---|
| Slash (skill) | `/agent:skill install <source>` | Installs into `./skills/` (default) |
| Slash (skill) | `/agent:skill install <source> --scope=<plugin\|project\|user>` | Installs into the chosen scope |
| Slash (skill) | `/agent:skill list` | Lists installed skills across all scopes |
| Slash (skill) | `/agent:skill remove <name>` | Removes, asking for confirmation |
| Slash (skill) | `/agent:skill remove <name> --force` | Removes without prompting |
| MCP tool | `skill_install({ source, scope?, force?, dryRun? })` | Programmatic install |
| MCP tool | `skill_list()` | Programmatic list |
| MCP tool | `skill_remove({ name, scope?, confirm? })` | Programmatic remove |

## Sources accepted

| Form | Example | Notes |
|---|---|---|
| GitHub shorthand | `alice/pomodoro` | Default branch |
| With branch/tag | `alice/pomodoro@v1.2` | Any git ref |
| With subdir | `alice/skills#weather` | Use when the repo hosts multiple skills |
| Both | `alice/skills@main#weather` | Branch and subdir |
| Full URL | `https://github.com/alice/pomodoro` | Same options via `@` and `#` |
| Local path | `/Users/me/dev/my-skill` | Useful while developing |

Local paths copy the directory as-is (minus `.git` and `node_modules`).

## Install scopes

| Scope | Destination | Read by |
|---|---|---|
| `plugin` (default) | `<workspace>/skills/<name>/` | ClawCode (registered in workspace `AGENTS.md`) |
| `project` | `<workspace>/.claude/skills/<name>/` | Claude Code natively, per-project |
| `user` | `~/.claude/skills/<name>/` | Claude Code natively, all projects |

Plugin scope is the default because it keeps the skill tied to this agent and surfaces it via the workspace `AGENTS.md`. Promote to `project` or `user` if you want the skill available to any Claude Code session (not just this agent).

## Format detection

The installer inspects the cloned `SKILL.md` and decides:

| Verdict | Behavior |
|---|---|
| **Valid skill** — has frontmatter with `name` and `description` | Installs |
| **OpenClaw-flavored** — references `sessions_spawn`, `NO_REPLY`, `gateway`, etc. | **Rejects.** Points to `/agent:import-skill` for the GREEN/YELLOW/RED classifier |
| **Invalid** — missing SKILL.md, no frontmatter, or missing required fields | Rejects with a reason |

ClawCode and Claude Code native skills share the same format, so valid skills work in both contexts. OpenClaw skills use a different tool surface and need adaptation — we don't do that adaptation automatically because it requires per-trigger judgment.

## Requirements gating

Skills can declare what they need via a `requires:` block in the frontmatter:

```yaml
---
name: pomodoro
description: Start a pomodoro timer
requires:
  os: ["darwin", "linux"]
  node: ">=18"
  binary: ["terminal-notifier"]
  env: ["POMODORO_WEBHOOK_URL"]
---
```

| Requirement | On fail |
|---|---|
| `os` | **Hard fail.** Install aborts. |
| `node` | **Hard fail.** Install aborts. |
| `binary` | **Soft warn.** Installs, but warns the binary is not in PATH. The skill may fail at runtime. |
| `env` | **Soft warn.** Installs, but warns the env var is not set. |

All four are optional. Skills without a `requires` block install freely.

## Safety

- **Install scripts are not executed.** If a repo has `install.sh`, `postinstall.js`, or similar, we ignore them. You can run them manually if you understand what they do.
- **Clones are shallow** (`--depth=1`) and cleaned up after install.
- **Collisions are rejected** by default. Pass `force=true` to overwrite an existing skill with the same name.
- **Remove requires confirmation.** Passing `confirm: true` is the only way to actually delete. The default behavior is a dry run that tells you what would be removed.
- **Only `.git` and `node_modules` are stripped** when copying — other repo files are preserved.

## Registration in AGENTS.md

When you install at `plugin` scope, the installer appends an entry to the `## Local imported skills` section in your workspace `AGENTS.md`. That way ClawCode's agent sees the skill on next session start.

For `project` and `user` scopes, no registration happens — Claude Code's native skill loader finds them without us doing anything.

Remove does the reverse: deletes the `AGENTS.md` entry when removing from plugin scope.

## Example flows

### Install from GitHub shorthand

```
/agent:skill install alice/pomodoro
```

```
✅ Installed "pomodoro" to /Users/you/my-agent/skills/pomodoro
   scope: plugin
   Start a pomodoro timer with system notifications

⚠️  Warnings:
   - env: POMODORO_WEBHOOK_URL not set
```

### Install OpenClaw-flavored skill

```
/agent:skill install legacy-user/openclaw-weather
```

```
❌ Install failed: SKILL.md references OpenClaw-specific tokens not available in Claude Code.
   Use /agent:import-skill on "/tmp/clawcode-skill-XYZ" instead — it runs the GREEN/YELLOW/RED classifier for OpenClaw skills.
   Evidence: "sessions_spawn" at line 14, "NO_REPLY" at line 22
```

### List

```
/agent:skill list
```

```
3 skill(s) installed:

--- plugin (/Users/you/my-agent/skills) ---
  pomodoro           [user-invocable]  Start a pomodoro timer with system notifications
  standup            [user-invocable]  Generate a standup summary from recent memory

--- user (/Users/you/.claude/skills) ---
  git-tidy           [user-invocable]  Clean merged local branches
```

### Remove

```
/agent:skill remove pomodoro
```

```
Would remove "pomodoro" from /Users/you/my-agent/skills/pomodoro (scope: plugin).

Pass confirm=true to actually delete.
```

User says "yes":

```
/agent:skill remove pomodoro --force
```

```
✅ Removed "pomodoro" from /Users/you/my-agent/skills/pomodoro
```

## Implementation

| File | Role |
|---|---|
| `lib/skill-manager.ts` | Source parsing, clone, format detection, requirements, install/list/remove, AGENTS.md sync |
| `server.ts` | `skill_install`, `skill_list`, `skill_remove` MCP tools |
| `skills/skill-manager/SKILL.md` | Dispatch layer + UX |

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `git clone failed` | No network or private repo | Check connectivity; use local path during dev |
| `Skill "X" already installed` | Name collision | `--force` to overwrite or pick a different source |
| OpenClaw detection false positive | Your skill legitimately mentions those token words | Rename the mentions in your SKILL.md or use `/agent:import-skill` for classification |
| Installed but agent doesn't trigger it | AGENTS.md not reloaded | Run `/mcp` to reload MCP server, or open a new session |
