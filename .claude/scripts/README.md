# `.claude/scripts`

Utility scripts for Claude Code integration in this repo.

## `create-remotion-managed-agent.mjs`

Mirrors the local Claude Code subagent defined in
[`../agents/remotion.md`](../agents/remotion.md) as a **Managed Agent** on
the Anthropic Console
(<https://platform.claude.com/workspaces/default/agents>).

### Why two agents?

| | Local subagent | Managed Agent |
|---|---|---|
| **File** | `.claude/agents/remotion.md` | Server-side resource, no local file |
| **Loaded by** | `claude` CLI in this repo | Anthropic API `/v1/agents` |
| **Visible in the Console?** | No | Yes |
| **Callable via the REST API?** | No | Yes |
| **Callable via `claude` CLI?** | Yes | No (different product) |

Both use the **same Markdown source of truth** — this script is the glue
that keeps them in sync.

### Prerequisites

- Node.js 18 or newer (for native `fetch`). This repo already uses Node 22
  for the Remotion sub-project, so no extra install needed.
- An Anthropic API key with access to the Managed Agents beta. Create one at
  <https://platform.claude.com/settings/keys>.

### Preview the payload (no network call)

```bash
node .claude/scripts/create-remotion-managed-agent.mjs --dry-run
```

Prints the exact JSON body that would be POSTed, plus the endpoint and
beta headers. Use this to sanity-check changes to
`.claude/agents/remotion.md` before pushing them to the Console.

### Create the agent

```bash
export ANTHROPIC_API_KEY=sk-ant-...
node .claude/scripts/create-remotion-managed-agent.mjs
```

On success, prints:

```
Managed agent created.
  id:      agent_01ABC...
  version: 1
  name:    remotion

Visible at: https://platform.claude.com/workspaces/default/agents
```

Refresh the Console — the new agent should appear under the default
workspace.

### What the script does

1. Reads `.claude/agents/remotion.md`.
2. Splits the YAML frontmatter from the Markdown body.
3. Builds a request body for `POST https://api.anthropic.com/v1/agents`:
   - `name` and `description` from the frontmatter.
   - `system` from the Markdown body.
   - `model` pinned to `claude-sonnet-4-6` (Managed Agents require Claude
     4.5+; the local `model: sonnet` shorthand is not a valid API id).
   - `tools: [{ type: "agent_toolset_20260401" }]` — the built-in dev
     toolset (bash, read, write, edit, glob, grep, web_fetch, web_search).
     The local `tools:` line uses Claude Code tool names, which are *not*
     the same as the API tool types.
   - `metadata` with a provenance tag so you can tell in the Console that
     this agent was synced from the repo.
4. Sends the request with the required headers:
   - `x-api-key`
   - `anthropic-version: 2023-06-01`
   - `anthropic-beta: managed-agents-2026-04-01`

### Updating an existing agent

The current script is **create-only**. If an agent named `remotion` already
exists, the API returns `409` and the script prints a hint. To update:

1. Delete the existing agent in the Console
   (<https://platform.claude.com/workspaces/default/agents>).
2. Re-run `node .claude/scripts/create-remotion-managed-agent.mjs`.

(A proper `PATCH /v1/agents/{id}` update path can be added later if we
end up iterating on the prompt often.)

### Troubleshooting

**`HTTP 401 invalid x-api-key`**
Your key is missing, wrong, or doesn't have Managed Agents access. Verify
at <https://platform.claude.com/settings/keys>.

**`HTTP 400 model_not_allowed`**
Managed Agents require Claude 4.5+. The script already pins
`claude-sonnet-4-6`; if Anthropic changes the id, update `DEFAULT_MODEL`
at the top of the script.

**`HTTP 400 beta_not_enabled`**
The `managed-agents-2026-04-01` beta flag is not enabled for your account.
Request access through the Anthropic Console support channel.

**Agent created but missing tools in the Console UI**
The built-in `agent_toolset_20260401` unfolds into individual tools
server-side; they should all appear. If not, check that your API version
header matches the one in the script.
