/**
 * Agent configuration — persistent settings stored in agent-config.json
 * Mirrors OpenClaw's openclaw.json memory section.
 */

import fs from "fs";
import path from "path";

export interface AgentConfig {
  /** Heartbeat configuration */
  heartbeat?: {
    /** Cron schedule (default: every 30 min) */
    schedule?: string;
    /** Active hours — heartbeat only fires within this window */
    activeHours?: {
      /** Start time in HH:MM 24h format (default: "08:00") */
      start?: string;
      /** End time in HH:MM 24h format (default: "23:00") */
      end?: string;
      /** IANA timezone (default: from USER.md or "UTC") */
      timezone?: string;
    };
  };
  /** Dreaming configuration */
  dreaming?: {
    /** Cron schedule (default: daily at 3 AM) */
    schedule?: string;
    /** Timezone for dreaming cron */
    timezone?: string;
  };
  memory: {
    /** "builtin" = SQLite+FTS5 (default), "qmd" = QMD external tool */
    backend: "builtin" | "qmd";
    /** Citation mode */
    citations: "auto" | "on" | "off";
    /**
     * Extra paths to index alongside the default memory/ directory.
     * Useful for indexing logs from messaging plugins, e.g.:
     *   ["~/.claude/channels/whatsapp/logs/conversations"]
     * Only *.md files are indexed. .jsonl, .json, binary files are skipped.
     * Paths starting with ~ are expanded to $HOME.
     */
    extraPaths?: string[];
    /** QMD-specific settings (only used when backend = "qmd") */
    qmd?: {
      /** Path to qmd binary (default: "qmd" — searches PATH) */
      command?: string;
      /** Search mode: "search" (fast), "vsearch" (reranked), "query" (slow, best) */
      searchMode?: "search" | "vsearch" | "query";
      /** Include default memory paths (MEMORY.md + memory/) */
      includeDefaultMemory?: boolean;
      /** Session transcript indexing */
      sessions?: {
        enabled?: boolean;
        retentionDays?: number;
      };
      /** Update intervals */
      update?: {
        /** Sync interval (e.g., "5m") */
        interval?: string;
        /** Debounce delay in ms */
        debounceMs?: number;
        /** Timeout for embedding operations in ms */
        embedTimeoutMs?: number;
      };
      /** Search limits */
      limits?: {
        maxResults?: number;
        timeoutMs?: number;
      };
    };
    /** Builtin-specific settings (only used when backend = "builtin") */
    builtin?: {
      /** Enable temporal decay for dated files */
      temporalDecay?: boolean;
      /** Half-life in days for temporal decay (default: 30) */
      halfLifeDays?: number;
      /** Enable MMR diversity re-ranking */
      mmr?: boolean;
      /** MMR lambda (0=diversity, 1=relevance, default: 0.7) */
      mmrLambda?: number;
    };
  };
}

const DEFAULT_CONFIG: AgentConfig = {
  memory: {
    backend: "builtin",
    citations: "auto",
    builtin: {
      temporalDecay: true,
      halfLifeDays: 30,
      mmr: true,
      mmrLambda: 0.7,
    },
  },
};

const CONFIG_FILENAME = "agent-config.json";

export function loadConfig(pluginRoot: string): AgentConfig {
  const configPath = path.join(pluginRoot, CONFIG_FILENAME);
  try {
    const raw = fs.readFileSync(configPath, "utf-8");
    const parsed = JSON.parse(raw);
    // Deep merge with defaults
    return {
      memory: {
        ...DEFAULT_CONFIG.memory,
        ...parsed.memory,
        qmd: parsed.memory?.qmd
          ? { ...parsed.memory.qmd }
          : undefined,
        builtin: {
          ...DEFAULT_CONFIG.memory.builtin,
          ...parsed.memory?.builtin,
        },
      },
    };
  } catch {
    return DEFAULT_CONFIG;
  }
}

export function saveConfig(pluginRoot: string, config: AgentConfig): void {
  const configPath = path.join(pluginRoot, CONFIG_FILENAME);
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + "\n");
}

export function configExists(pluginRoot: string): boolean {
  return fs.existsSync(path.join(pluginRoot, CONFIG_FILENAME));
}
