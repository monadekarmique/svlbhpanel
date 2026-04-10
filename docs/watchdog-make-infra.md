# SVLBH Watchdog Infra — Make.com

## Scenario
- **ID**: `#9017210`
- **Name**: SVLBH Watchdog Infra
- **Status**: Active, valid (`isinvalid: false`)
- **Scheduling**: Every 15 minutes (`interval: 900`)
- **Team**: `630342` / Org `1799074`

## Architecture

```
[Scheduled every 15 min]
     │
     ▼
Module 1: HTTP GET /api/v2/scenarios?teamId=630342&limit=100
     │  → 1.data.scenarios (array)
     ▼
Module 2: HTTP GET /api/v2/hooks?teamId=630342&limit=100
     │  → 2.data.hooks (array)
     ▼
Module 3: HTTP POST → WA Router webhook
     │  body: { message: "WATCHDOG DD/MM HH:mm: N scenarios, queue=Q" }
     │  Formulas inline: length(1.data.scenarios), sum(map(2.data.hooks; "queueCount"))
     ▼
  [Alert sent to Patrick via iMessage]
```

## Key Technical Decisions

### Why no `util:SetVariables`?
`util:SetVariables` causes `BundleValidationError` at runtime in scenarios
created via API, even with static values. Root cause unknown — possibly a
Make.com bug with scheduled scenarios that lack a webhook/trigger first module.

**Workaround**: All formulas computed inline in `jsonStringBodyContent` of the
POST module. This is proven to work.

### Why `inputMethod: "jsonString"` not `"dataStructure"`?
`inputMethod: "dataStructure"` requires interface metadata to validate body
fields at runtime. Without it → `BundleValidationError`. `jsonString` bypasses
validation entirely.

### Data paths
With `parseResponse: true` on HTTP modules:
- Scenarios array: `{{1.data.scenarios}}`
- Hooks array: `{{2.data.hooks}}`
- Field access: `{{1.data.scenarios[].isinvalid}}`

## Make.com API Rules (discovered)

| Rule | Detail |
|------|--------|
| Blueprint `name` | Must be inside the blueprint JSON, NOT in the top-level payload |
| `scheduling` | Must be a JSON string, not an object |
| Blueprint `metadata` | Required: `{"version": 1}` minimum |
| Activate | `POST /scenarios/{id}/start` (not PATCH with isActive) |
| Module HTTP | `http:MakeRequest` v4 — use `parseResponse: true` for JSON |
| Cloudflare | Always include `User-Agent: Mozilla/5.0 ...` header |
| POST body | Use `inputMethod: "jsonString"` + `jsonStringBodyContent` |
| SetVariables | AVOID via API — use inline formulas instead |
| Delete+Create | Only way to fix blueprints (PATCH with blueprint → 500) |

## Future Enhancements

### Phase 2: Conditional Alerting (Router)
Add a `builtin:BasicRouter` between modules 2 and 3:
- **Route A** (issues detected): POST alert → requires filter conditions
- **Route B** (all OK): no action

Router filter conditions to add via Make UI:
```
has_issues = contains(map(1.data.scenarios; "isinvalid"); true)
          OR contains(map(1.data.scenarios; "iswaiting"); true)
          OR sum(map(2.data.hooks; "queueCount")) > 50
```

### Phase 3: Auto-Repair (MA-DLQ)
Webhook-triggered scenario that:
- Replays DLQ items
- Disables invalid+active scenarios
- Detects error rate > 50%

## Webhook
- **WA Router**: `https://hook.eu2.make.com/lllo1g6btuv4e3qjt4qvpj8fjwyd663s`

## Session: 2026-04-08
Created by Claude Code session. Previous session attempts failed due to:
1. Wrong module name (`http:ActionSendData` → fixed to `http:MakeRequest`)
2. `util:SetVariable` singular → fixed to `util:SetVariables` plural
3. `util:SetVariables` BundleValidationError → bypassed with inline formulas
4. `inputMethod: "dataStructure"` → fixed to `"jsonString"`
