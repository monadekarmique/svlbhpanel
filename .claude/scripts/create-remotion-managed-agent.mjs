#!/usr/bin/env node
// .claude/scripts/create-remotion-managed-agent.mjs
//
// Mirrors the local Claude Code subagent defined in
// `.claude/agents/remotion.md` as a Managed Agent on the Anthropic Console
// (https://platform.claude.com/workspaces/default/agents).
//
// The local subagent and the Managed Agent are two *different* products:
//   - Local subagent: loaded by the Claude Code CLI from the repo, never
//     touches Anthropic servers.
//   - Managed Agent: server-side resource, callable via the REST API and
//     visible in the Console.
//
// This script keeps them in sync by reading the same Markdown source of
// truth and POSTing it to `/v1/agents`.
//
// Usage:
//   export ANTHROPIC_API_KEY=sk-ant-...
//   node .claude/scripts/create-remotion-managed-agent.mjs
//
// Preview without hitting the API:
//   node .claude/scripts/create-remotion-managed-agent.mjs --dry-run
//
// Requirements: Node 18+ (for native `fetch`). No npm deps.

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, "..", "..");
const SUBAGENT_PATH = join(REPO_ROOT, ".claude", "agents", "remotion.md");

const ENDPOINT = "https://api.anthropic.com/v1/agents";
const ANTHROPIC_VERSION = "2023-06-01";
const ANTHROPIC_BETA = "managed-agents-2026-04-01";
const DEFAULT_MODEL = "claude-sonnet-4-6";

/**
 * Parse the flat YAML frontmatter + Markdown body of a Claude Code subagent
 * file. Intentionally does NOT depend on a YAML library — the frontmatter
 * format is simple key: value pairs, one per line.
 */
function parseSubagentMarkdown(raw) {
  if (!raw.startsWith("---\n")) {
    throw new Error(
      `Expected ${SUBAGENT_PATH} to start with YAML frontmatter ('---\\n'), got: ${raw.slice(0, 40)}`,
    );
  }
  const end = raw.indexOf("\n---\n", 4);
  if (end === -1) {
    throw new Error("YAML frontmatter never closed (expected '\\n---\\n').");
  }
  const frontmatterRaw = raw.slice(4, end);
  const body = raw.slice(end + 5).trim();

  const frontmatter = {};
  for (const line of frontmatterRaw.split("\n")) {
    const m = line.match(/^([a-zA-Z_][\w-]*):\s*(.*)$/);
    if (m) frontmatter[m[1]] = m[2].trim();
  }
  return { frontmatter, body };
}

function buildPayload({ frontmatter, body }) {
  const name = frontmatter.name || "remotion";
  // Console agent `description` max is 2048 chars. The local subagent
  // description is already short, but truncate defensively.
  const description = (frontmatter.description || "").slice(0, 2048);

  return {
    name,
    description: description || undefined,
    // Managed Agents require Claude 4.5+. The local file may specify
    // `model: sonnet` (a Claude Code shorthand) — we ignore that and pin
    // to a concrete API model id.
    model: DEFAULT_MODEL,
    system: body,
    // Grants the full built-in dev toolset (bash, read, write, edit,
    // glob, grep, web_fetch, web_search). The local file's `tools:` line
    // uses Claude Code tool names, which are not valid API tool types.
    tools: [{ type: "agent_toolset_20260401" }],
    metadata: {
      source: "svlbhpanel/.claude/agents/remotion.md",
      synced_by: "create-remotion-managed-agent.mjs",
    },
  };
}

async function main() {
  const dryRun = process.argv.includes("--dry-run");

  let raw;
  try {
    raw = readFileSync(SUBAGENT_PATH, "utf8");
  } catch (err) {
    console.error(`Could not read ${SUBAGENT_PATH}: ${err.message}`);
    process.exit(1);
  }

  const parsed = parseSubagentMarkdown(raw);
  const payload = buildPayload(parsed);

  if (dryRun) {
    console.log("=== DRY RUN: payload that would be POSTed ===");
    console.log(JSON.stringify(payload, null, 2));
    console.log("\n=== endpoint ===");
    console.log(`POST ${ENDPOINT}`);
    console.log(`anthropic-version: ${ANTHROPIC_VERSION}`);
    console.log(`anthropic-beta:    ${ANTHROPIC_BETA}`);
    return;
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    console.error("ANTHROPIC_API_KEY env var is not set.");
    console.error(
      "Create one at https://platform.claude.com/settings/keys and export it:",
    );
    console.error("  export ANTHROPIC_API_KEY=sk-ant-...");
    process.exit(1);
  }

  const res = await fetch(ENDPOINT, {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "anthropic-version": ANTHROPIC_VERSION,
      "anthropic-beta": ANTHROPIC_BETA,
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    json = { raw: text };
  }

  if (!res.ok) {
    console.error(`HTTP ${res.status} ${res.statusText}`);
    console.error(JSON.stringify(json, null, 2));
    if (res.status === 409 || /already exists/i.test(text)) {
      console.error(
        "\nAn agent with this name may already exist. Delete it in the",
      );
      console.error(
        "Console (https://platform.claude.com/workspaces/default/agents)",
      );
      console.error("or rename `name:` in .claude/agents/remotion.md.");
    }
    process.exit(1);
  }

  console.log("Managed agent created.");
  console.log(`  id:      ${json.id ?? "(no id field)"}`);
  console.log(`  version: ${json.version ?? "(no version field)"}`);
  console.log(`  name:    ${json.name ?? payload.name}`);
  console.log("");
  console.log(
    "Visible at: https://platform.claude.com/workspaces/default/agents",
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
