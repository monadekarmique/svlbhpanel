# SVLBH testers detection — Niveau 1 (TestFlight install)

Polls App Store Connect for transitions on the two watched testers
(Yvette Dayer Bersier, Daphné Friederich) and queues a WhatsApp
notification each time one of them progresses through the funnel.

## What it watches

| Transition | Event | Notif WhatsApp |
|---|---|---|
| `INVITED → ACCEPTED` | `ACCEPTED` | yes |
| `* → INSTALLED` | `INSTALLED` | yes |
| `buildCount 0 → ≥1` | `FIRST_BUILD` | yes (folded into `INSTALLED` if same run) |
| `buildCount` increases | `NEW_BUILD` | yes |
| `* → EXPIRED` | `EXPIRED` | log only |
| Other state change | `STATE_CHANGE` | log only |

> ASC does **not** expose `appDevices` on `betaTesters` (the brief was
> wrong on that point — it returns `400 PARAMETER_ERROR.INVALID`). The
> available relationships on `/v1/betaTesters` are `apps`, `betaGroups`,
> `builds`. We use linked-`builds` count as the install proxy: ASC links
> a build to a tester after they've installed it on at least one device.

## Files

| Path | Role | Committed |
|---|---|---|
| `scripts/check_testers_status.py` | the poller | yes |
| `scripts/com.vlbh.svlbh.check-testers.plist` | launchd job | yes |
| `scripts/README_testers_detection.md` | this file | yes |
| `scripts/.testers_state.json` | last-known state, written atomically | **no** |
| `scripts/.testers_state.log` | one JSONL line per run | **no** |
| `scripts/.testers_notify_queue.jsonl` | append-only WhatsApp queue, drained by Cowork | **no** |
| `scripts/.launchd_stdout.log` / `.launchd_stderr.log` | launchd output | **no** |

## Notification flow

1. Claude Code (this Mac, has ASC API access) writes a JSONL line into
   `scripts/.testers_notify_queue.jsonl`.
2. Cowork (desktop Mac, has the WhatsApp MCP for the `patrickbays`
   account) reads + drains the queue, sends each message to
   `+41792168200` (Patrick).

Claude Code never tries to send WhatsApp directly — it has no access to
that MCP. The destination phone number and MCP account name are hardcoded
in `check_testers_status.py` (`NOTIFY_TO_E164`, `NOTIFY_VIA_MCP_ACCOUNT`).

The message template ends with `🥰🙏` — VLBH voice rule, non-negotiable.

## CLI

```bash
# Required first run after install — silent baseline, no notifications.
scripts/.venv/bin/python3 scripts/check_testers_status.py --init

# Single normal run (what launchd does).
scripts/.venv/bin/python3 scripts/check_testers_status.py --once

# Local debug loop (do NOT run this from launchd, use StartInterval).
scripts/.venv/bin/python3 scripts/check_testers_status.py --watch 600

# End-to-end test: queue a synthetic notification for one tester.
scripts/.venv/bin/python3 scripts/check_testers_status.py \
    --force-notify 3112801c-390d-4e9e-b32e-d57bed5e6ff4

# Quiet (launchd, log file only)
scripts/.venv/bin/python3 scripts/check_testers_status.py --once --quiet
```

## launchd setup

The plist `Label` is `com.vlbh.svlbh.check-testers`, which **must**
match the filename without `.plist`, otherwise `bootstrap` succeeds but
nothing ever runs.

```bash
# Bootstrap the job (first time, or after editing the plist)
launchctl bootstrap gui/$(id -u) \
  /Users/patricktest/Developer/svlbhpanel-v5/scripts/com.vlbh.svlbh.check-testers.plist

# Force an immediate run
launchctl kickstart -k gui/$(id -u)/com.vlbh.svlbh.check-testers

# Check it's loaded
launchctl print gui/$(id -u)/com.vlbh.svlbh.check-testers | head -40

# Tear down (e.g. before editing the plist)
launchctl bootout gui/$(id -u)/com.vlbh.svlbh.check-testers
```

`launchctl load`/`unload` are deprecated on modern macOS — use
`bootstrap`/`bootout` instead.

## Cadence

- **First 48 h after upload**: every 10 min (`StartInterval=600`, current value).
- **After 48 h**: every 30 min — edit `StartInterval` to `1800`, then
  `bootout` + `bootstrap` again.

This is a manual switch by design; we didn't want two conditional plists.

## Log rotation

Manual. Cadence is small enough that we don't need anything fancy:
- `.testers_state.log` ≈ 288 lines/day during the burst, then ≈ 50/day.
- `.testers_notify_queue.jsonl` is drained by Cowork.
- `.launchd_stdout.log` / `.launchd_stderr.log` only contain Python
  errors when the script crashes.

When any of these grows uncomfortable, just `: > scripts/.testers_state.log`.
No `logrotate`, no scheduled rotation. Documented here so we don't
re-open this in six months.

## Niveau 2 — Apple Sign-In telemetry (designed, not implemented)

A second pass is gated by `TELEMETRY_ENDPOINT_URL` in
`check_testers_status.py` (currently `None`). Design + investigation
notes live in `scripts/NOTES_signin_detection.md`. Do not enable until
the backend endpoint is shipped *and* validated end-to-end.

## Robustness notes

- The state file is only rewritten after a successful ASC fetch — a
  network error or 5xx leaves the previous state intact and exits 1.
- Two consecutive runs with no changes produce **zero** notifications
  and **zero** writes to the queue file.
- Brand-new tester records in the ASC payload do not synthesize fake
  `INVITED` events — they're just tracked silently and only future
  transitions fire.
- `--init` exists exactly because the first ever run otherwise looks
  like "everything just appeared", which would spam the queue.
