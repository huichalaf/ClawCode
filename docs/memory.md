# Memory system

ClawCode's core differentiator. The agent remembers what was said, read, and decided across sessions. All search runs locally by default — no API keys required unless you opt in to QMD or cloud embeddings.

## The files on disk

| Path | Role |
|---|---|
| `memory/MEMORY.md` | Long-term curated memory — evergreen facts, preferences, decisions. Promoted into by dreaming; also hand-edited. |
| `memory/YYYY-MM-DD.md` | Daily logs — append-only, written during sessions. One file per day. |
| `memory/.dreams/short-term-recall.json` | Every `memory_search` hit gets recorded here with score, concept tags, and recall count. Dreaming reads this to decide what to promote. |
| `memory/.dreams/phase-signals.json` | Reinforcement signals accumulated between dream runs. |
| `memory/.memory.sqlite` | Auto-generated FTS5 index. Safe to delete — rebuilds on next MCP startup or after the next `.md` change in `memory/`. |
| `DREAMS.md` | Dream diary (at workspace root, not inside `memory/`). Written after each dream run. |

`MEMORY.md` and dated files are human-readable markdown. You can `grep`, read, and edit them freely — the index re-syncs automatically when `memory/` files change (via `fs.watch`). The first search after MCP startup also syncs to cover anything added while the server was down. `extraPaths` are also watched (recursively on macOS and Windows, top-level only on Linux due to a Node `fs.watch` platform limitation — see [§ extraPaths](#extrapaths--indexing-beyond-memory)).

## Write it, don't memorize it

The agent is instructed to **always write** anything worth remembering to `memory/YYYY-MM-DD.md` or `MEMORY.md` instead of trusting context window retention. "Mental notes" don't survive session restarts; files do.

When the user says "remember X", the agent appends to today's daily log. When the agent learns a lesson, it adds it. When a decision is made, it goes to memory. This is enforced by `templates/CLAUDE.md`.

## Search pipeline

When `memory_search(query)` is called:

```
query
  │
  ▼
1. Keyword extraction      (stop-word filter: EN + ES)
  │
  ▼
2. Bilingual expansion     (ES↔EN synonym lookup)
  │
  ▼
3. Date expansion          ("ayer" → 2026-04-11.md)
  │
  ▼
4. FTS5 BM25 search        (SQLite index)
  │
  ▼
5. Temporal decay          (30-day half-life for dated files)
  │
  ▼
6. MMR re-rank             (diversity vs relevance, λ = 0.7)
  │
  ▼
Top N snippets with citations
```

Each step is disabled individually in config if needed.

## Chunking

Files are split into overlapping chunks before indexing:

- Default chunk size: **400 tokens**
- Default overlap: **80 tokens**
- Boundaries prefer markdown headers and paragraph breaks when possible

Small files (< 400 tokens) end up as a single chunk. Large daily logs end up as multiple. The overlap prevents a question from missing content that straddles a chunk boundary.

## BM25 ranking

SQLite's FTS5 extension provides BM25 out of the box. We use it as-is — no custom tuning. That means:

- Rarer terms outweigh common ones
- Term frequency in a chunk boosts score (up to a ceiling)
- Longer chunks are down-weighted slightly to prevent length bias

## Temporal decay

Dated files (`memory/YYYY-MM-DD.md`) age. The score multiplier is:

```
decay = 0.5 ^ (age_in_days / halfLifeDays)
```

- `halfLifeDays: 30` (default) → a 30-day-old file scores at 50% of today's
- `halfLifeDays: 90` → slower decay, older context stays relevant longer
- `halfLifeDays: 7` → aggressive, only the last week matters much

Non-dated files (`MEMORY.md`, imported files) are treated as evergreen — no decay.

Config:

```json
{ "memory": { "builtin": { "temporalDecay": true, "halfLifeDays": 30 } } }
```

Set `temporalDecay: false` to disable. Half-life is hot-reloadable (see [config-reload.md](config-reload.md)).

## MMR — diversity re-ranking

"Maximal Marginal Relevance" prevents the top N from being five near-duplicates of the same fact. After BM25 + decay produces an initial ranking, MMR picks one chunk at a time by balancing:

- **Relevance** to the query
- **Distance** from chunks already picked

```
λ = 0.7 (default) → 70% relevance, 30% diversity
λ = 1.0          → pure relevance (no diversity)
λ = 0.0          → pure diversity (may surface off-topic chunks)
```

Config:

```json
{ "memory": { "builtin": { "mmr": true, "mmrLambda": 0.7 } } }
```

## Keyword extraction + stop words

`memory_search("¿qué hablamos ayer sobre el proyecto Cookie?")` is never searched verbatim. We:

1. Lowercase + tokenize
2. Drop stop words — ~200 common EN words (`the`, `and`, `what`, `about`) + ~100 ES words (`el`, `la`, `de`, `que`)
3. Drop tokens shorter than 2 characters
4. Result: `["hablamos", "ayer", "proyecto", "cookie"]`

The filter is in `lib/keywords.ts`. To add or remove stop words, edit `STOP_WORDS` there.

## Bilingual synonym expansion

Before hitting FTS5, each keyword is expanded to its cross-language pairs:

| Keyword | Expanded |
|---|---|
| `perro` | `perro`, `dog` |
| `dog` | `dog`, `perro` |
| `camarón` | `camarón`, `shrimp` |
| `cumpleaños` | `cumpleaños`, `birthday` |

The mapping (~40 pairs, bidirectional) lives in `lib/keywords.ts`. This is what lets a Spanish question surface English memory and vice versa without requiring embeddings.

Adding a pair: edit the `BILINGUAL_SYNONYMS` object in `keywords.ts`, push the new entry. No code changes elsewhere.

## Date expansion

Words like "hoy", "ayer", "today", "yesterday" resolve to actual dates so they match daily log filenames:

| Word | Becomes |
|---|---|
| `hoy` / `today` | `2026-04-12` (today) |
| `ayer` / `yesterday` | `2026-04-11` |
| `antier` / `anteayer` | `2026-04-10` |

So "¿qué hablamos ayer?" hits `memory/2026-04-11.md` directly.

## `extraPaths` — indexing beyond `memory/`

By default only `memory/*.md` and `MEMORY.md` are indexed. You can add other directories:

```json
{
  "memory": {
    "extraPaths": [
      "~/.claude/channels/whatsapp/logs/conversations",
      "~/notes"
    ]
  }
}
```

- Paths starting with `~` expand to `$HOME`
- Walked recursively
- Only `.md` files are indexed; `.jsonl`, `.json`, binaries are skipped
- Path traversal (`..`) is blocked to prevent reading outside configured paths

**Live updates and the Linux caveat.** Each path in `extraPaths` is watched with `fs.watch({ recursive: true })`. On **macOS** and **Windows** the watcher fires for any `.md` change at any depth — new WhatsApp / Telegram conversation logs, edits to a note in a subfolder, etc. — and the index re-syncs on the next `memory_search`. On **Linux**, Node's `fs.watch` ignores the `recursive` flag (a longstanding libuv limitation), so the watcher only sees changes at the top level of each `extraPath`. For deep subdirectories on Linux, run `/agent:doctor --fix` after adding files, or restart the MCP server.

`extraPaths` is a **critical key** — adding or removing entries from the list requires `/mcp` (the watchers are set up at startup against the current list). Changes to files *inside* an existing path are picked up live as described above. See [config-reload.md](config-reload.md).

## Security: path traversal

`memory_get(path)` and the `extraPaths` walker reject paths outside the workspace or the configured extras. Attempting `memory_get("../../../etc/passwd")` returns an error without reading anything. Tests in `tier1b-internals.ts` verify this.

## MCP tools

| Tool | Use when |
|---|---|
| `memory_search({ query, maxResults? })` | You know what you're looking for. Precise query. Returns snippets with citations. |
| `memory_get({ path, from?, lines? })` | You want to read specific lines from a memory file. Typically after `memory_search` to pull more context around a hit. |
| `memory_context({ message })` | Active-memory turn-start reflex. Derives queries from a full message, runs multiple searches, dedupes, returns a digest. Prefer this over `memory_search` when responding to a user message. See [memory-context.md](memory-context.md). |

## Config reference

```json
{
  "memory": {
    "backend": "builtin",
    "citations": "auto",
    "extraPaths": [],
    "builtin": {
      "temporalDecay": true,
      "halfLifeDays": 30,
      "mmr": true,
      "mmrLambda": 0.7
    }
  }
}
```

| Key | Default | Hot-reload | Notes |
|---|---|---|---|
| `backend` | `"builtin"` | **No** — requires `/mcp` | `"builtin"` or `"qmd"` (see [qmd.md](qmd.md)) |
| `citations` | `"auto"` | Yes | `"auto"` / `"on"` / `"off"` — citation mode |
| `extraPaths` | `[]` | **No** | Index build happens at startup |
| `builtin.temporalDecay` | `true` | Yes | Toggle decay |
| `builtin.halfLifeDays` | `30` | Yes | Decay half-life |
| `builtin.mmr` | `true` | Yes | Toggle diversity re-rank |
| `builtin.mmrLambda` | `0.7` | Yes | 0 = pure diversity, 1 = pure relevance |

## Implementation

| File | Role |
|---|---|
| `lib/memory-db.ts` | `MemoryDB` class: SQLite+FTS5 init, sync/index, search, readFile, stats |
| `lib/chunker.ts` | `chunkMarkdown` — header-aware splitting with overlap |
| `lib/keywords.ts` | Stop words, bilingual synonyms, date expansion, query builder |
| `lib/temporal-decay.ts` | `getDecayMultiplier(ageDays, halfLife)` |
| `lib/mmr.ts` | `applyMMR(results, query, lambda, maxResults)` |
| `lib/memory-context.ts` | Active-memory wrapper (see [memory-context.md](memory-context.md)) |
| `lib/qmd-manager.ts` | Optional QMD backend (see [qmd.md](qmd.md)) |
| `server.ts` | `memory_search`, `memory_get`, `memory_context` MCP tools |

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Search returns nothing for obvious content | Index hasn't synced (rare — `fs.watch` should auto-mark dirty on file changes) | Confirm the file is at the top level of `memory/` (subdirectories under `memory/` are not watched). For `extraPaths` on **Linux**, deep subdirectories are not watched (`fs.watch` recursive limitation) — run `/agent:doctor --fix` after adding files there. For NFS / sshfs / unusual filesystems where `fs.watch` does not propagate events, same fix. As a last resort, delete `memory/.memory.sqlite` and restart the MCP to rebuild. |
| "Database unavailable" stub used | `better-sqlite3` native module didn't compile | Run `npm install` in the plugin dir; may need Xcode Command Line Tools on macOS |
| Old daily files outrank recent ones | Decay disabled or half-life too high | Set `builtin.halfLifeDays` to 30 or less |
| Query in one language misses memory in the other | Synonym pair not in the map | Add it to `BILINGUAL_SYNONYMS` in `lib/keywords.ts` |
| Path traversal error on legit path | Path outside workspace + `extraPaths` | Add the parent directory to `extraPaths` + `/mcp` |
| Chunks seem cut mid-sentence | Rare; chunker falls back to fixed size when no good boundary exists | Expected — overlap compensates. Increase chunk size if needed. |
