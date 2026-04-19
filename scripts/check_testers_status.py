#!/usr/bin/env python3
"""
SVLBH TestFlight tester status poller.

Polls App Store Connect every N minutes (via launchd) and emits a WhatsApp
notification queue when one of the watched testers (Yvette Dayer Bersier,
Daphné Friederich) progresses through the TestFlight funnel.

Two passes:
  1. App Store Connect /v1/betaTesters polling (state + linked-builds diff).
     NOTE: ASC does NOT expose `appDevices` on betaTesters (the brief was
     wrong on that point). The available relationships are
     `apps`, `betaGroups`, `builds`. We use `builds` as the install proxy:
     when a tester has at least one build linked to them, it means they
     installed the binary at least once. The count is therefore "linked
     builds" rather than "device count" — same idea, different wording.
  2. (Future, gated by TELEMETRY_ENDPOINT_URL) backend telemetry endpoint
     for actual Apple Sign-In events. Disabled until the backend is wired up.

Notifications are produced *only* — they are appended to
scripts/.testers_notify_queue.jsonl. The Cowork side (which has the
WhatsApp MCP for the patrickbays account) is responsible for draining
the queue.

Usage:
    scripts/.venv/bin/python3 scripts/check_testers_status.py --once
    scripts/.venv/bin/python3 scripts/check_testers_status.py --init
    scripts/.venv/bin/python3 scripts/check_testers_status.py --watch 600
    scripts/.venv/bin/python3 scripts/check_testers_status.py --force-notify <id>
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

# Reuse the JWT signing helpers from the existing post-upload script.
SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
from testflight_post_upload import (  # noqa: E402
    APP_ID,
    BETA_GROUP_ID,
    load_key,
    make_token,
)


# ---- Configuration ----------------------------------------------------------

# Patrick — WhatsApp self-notification (E.164)
NOTIFY_TO_E164 = "+41792168200"
# Cowork-side MCP account that drains the queue
NOTIFY_VIA_MCP_ACCOUNT = "patrickbays"

# Watched testers — only these produce WhatsApp notifications.
# Other group members are logged but never notified.
WATCHED_TESTERS = {
    "3112801c-390d-4e9e-b32e-d57bed5e6ff4": {
        "name": "Yvette Dayer Bersier",
        "first_name": "Yvette",
        "email": "yvette.dayer@bluewin.ch",
    },
    "c310b46d-5221-4dad-b2de-7f195eb76278": {
        "name": "Daphné Friederich",
        "first_name": "Daphné",
        "email": "daphnefriederich@icloud.com",
    },
}

# Niveau 2 telemetry endpoint — disabled until backend is implemented + validated.
TELEMETRY_ENDPOINT_URL: str | None = None

API_BASE = "https://api.appstoreconnect.apple.com"

STATE_PATH = SCRIPT_DIR / ".testers_state.json"
LOG_PATH = SCRIPT_DIR / ".testers_state.log"
QUEUE_PATH = SCRIPT_DIR / ".testers_notify_queue.jsonl"

ZURICH = ZoneInfo("Europe/Zurich")

# ---- Event types ------------------------------------------------------------
EV_ACCEPTED = "ACCEPTED"
EV_INSTALLED = "INSTALLED"
EV_FIRST_BUILD = "FIRST_BUILD"
EV_NEW_BUILD = "NEW_BUILD"
EV_EXPIRED = "EXPIRED"
EV_STATE_CHANGE = "STATE_CHANGE"
EV_FORCE = "FORCE"

# Events that translate into a WhatsApp notification (others are log-only).
NOTIFIABLE_EVENTS = {EV_ACCEPTED, EV_INSTALLED, EV_FIRST_BUILD, EV_NEW_BUILD, EV_FORCE}

EVENT_EMOJI = {
    EV_ACCEPTED: "👆",
    EV_INSTALLED: "📲",
    EV_FIRST_BUILD: "📱",
    EV_NEW_BUILD: "➕",
    EV_FORCE: "🧪",
}

EVENT_VERB = {
    EV_ACCEPTED: ("a accepté", "l'invitation TestFlight"),
    EV_INSTALLED: ("a installé", "le build"),
    EV_FIRST_BUILD: ("a installé", "son premier build"),
    EV_NEW_BUILD: ("a installé", "un nouveau build"),
    EV_FORCE: ("(test)", "notif factice"),
}


# ---- HTTP helpers -----------------------------------------------------------

def _asc_get(private_key: str, path: str) -> tuple[int, dict]:
    url = API_BASE + path
    req = urllib.request.Request(url, method="GET")
    req.add_header("Authorization", "Bearer " + make_token(private_key))
    req.add_header("Accept", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            return resp.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        body_raw = e.read() or b""
        try:
            return e.code, json.loads(body_raw)
        except json.JSONDecodeError:
            return e.code, {"raw": body_raw.decode(errors="replace")}
    except urllib.error.URLError as e:
        return 0, {"error": "network", "reason": str(e.reason)}


# ---- ASC fetch + parse ------------------------------------------------------

def fetch_beta_testers(private_key: str) -> dict:
    """Fetch all beta testers for the app, with apps/betaGroups/builds included."""
    path = (
        f"/v1/betaTesters"
        f"?filter[apps]={APP_ID}"
        f"&include=apps,betaGroups,builds"
        f"&limit=200"
    )
    status, body = _asc_get(private_key, path)
    if status != 200:
        raise RuntimeError(f"ASC betaTesters fetch failed: HTTP {status}: {json.dumps(body)[:400]}")
    return body


def fetch_latest_build_str(private_key: str) -> str:
    """Return e.g. '7.5.1 (85)' from the most recently uploaded build."""
    status, body = _asc_get(
        private_key,
        f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=1",
    )
    if status != 200:
        return "?.?.? (?)"
    data = body.get("data", [])
    if not data:
        return "?.?.? (?)"
    attrs = data[0].get("attributes", {}) or {}
    version = attrs.get("version") or "?"
    # ASC `builds.attributes.version` is the build number; the marketing
    # version lives on the related `preReleaseVersion`. Fetch it lazily.
    rels = data[0].get("relationships", {}) or {}
    pre_id = (
        rels.get("preReleaseVersion", {})
        .get("data", {})
        .get("id")
        if isinstance(rels.get("preReleaseVersion", {}).get("data"), dict)
        else None
    )
    marketing = "?"
    if pre_id:
        st, prv = _asc_get(private_key, f"/v1/preReleaseVersions/{pre_id}")
        if st == 200:
            marketing = (prv.get("data", {}).get("attributes", {}) or {}).get("version") or "?"
    return f"{marketing} ({version})"


def build_included_index(payload: dict) -> dict:
    """Map (type, id) → resource object from the JSON:API `included` array."""
    idx: dict = {}
    for item in payload.get("included", []) or []:
        idx[(item["type"], item["id"])] = item
    return idx


def resolve_related(tester: dict, relation_name: str, included_idx: dict) -> list[dict]:
    """Walk a tester's `relationships.<name>.data` and return resolved objects."""
    rel = (
        tester.get("relationships", {})
        .get(relation_name, {})
        .get("data", [])
        or []
    )
    if isinstance(rel, dict):  # to-one
        rel = [rel]
    out = []
    for r in rel:
        key = (r.get("type"), r.get("id"))
        if key in included_idx:
            out.append(included_idx[key])
    return out


def parse_testers(payload: dict, group_id: str) -> dict:
    """Return {tester_id: {state, buildCount, buildIds, email, name, in_target_group}}.

    `buildCount` is the number of builds linked to this tester. ASC links a
    build to a tester after they've installed it on at least one device, so
    we use it as the install proxy.
    """
    idx = build_included_index(payload)
    out: dict = {}
    for tester in payload.get("data", []) or []:
        tid = tester.get("id")
        if not tid:
            continue
        attrs = tester.get("attributes", {}) or {}
        builds = resolve_related(tester, "builds", idx)
        groups = resolve_related(tester, "betaGroups", idx)
        in_target_group = any(g.get("id") == group_id for g in groups)
        build_ids = sorted([b.get("id") for b in builds if b.get("id")])
        first = (attrs.get("firstName") or "").strip()
        last = (attrs.get("lastName") or "").strip()
        full = (first + " " + last).strip() or attrs.get("email") or tid
        out[tid] = {
            "state": attrs.get("state"),
            "buildCount": len(build_ids),
            "buildIds": build_ids,
            "email": (attrs.get("email") or "").strip().lower() or None,
            "name": full,
            "inviteType": attrs.get("inviteType"),
            "in_target_group": in_target_group,
        }
    return out


# ---- State file -------------------------------------------------------------

def load_state() -> dict:
    if not STATE_PATH.exists():
        return {"testers": {}, "meta": {"last_telemetry_poll_at": None}}
    try:
        return json.loads(STATE_PATH.read_text())
    except json.JSONDecodeError:
        return {"testers": {}, "meta": {"last_telemetry_poll_at": None}}


def save_state_atomic(state: dict) -> None:
    tmp = STATE_PATH.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(state, ensure_ascii=False, indent=2, sort_keys=True))
    os.replace(tmp, STATE_PATH)


# ---- Diff -------------------------------------------------------------------

def diff_testers(prev: dict, curr: dict) -> list[dict]:
    """Return a list of typed events for *all* testers (notification gating
    happens later)."""
    events: list[dict] = []
    for tid, c in curr.items():
        p = prev.get(tid)
        if p is None:
            # Brand-new tester record. Don't synthesize an INVITED notification —
            # the only thing we'd say is "they exist", which is just noise.
            # Future state changes will fire normally.
            continue

        prev_state = p.get("state")
        curr_state = c.get("state")
        prev_count = int(p.get("buildCount") or 0)
        curr_count = int(c.get("buildCount") or 0)
        prev_ids = set(p.get("buildIds") or [])
        curr_ids = set(c.get("buildIds") or [])

        sub_events: list[str] = []

        # State transitions
        if prev_state != curr_state:
            if curr_state == "INSTALLED":
                sub_events.append(EV_INSTALLED)
            elif curr_state == "ACCEPTED" and prev_state == "INVITED":
                sub_events.append(EV_ACCEPTED)
            elif curr_state == "EXPIRED":
                sub_events.append(EV_EXPIRED)
            else:
                sub_events.append(EV_STATE_CHANGE)

        # Linked-build count transitions (proxy for installs)
        if prev_count == 0 and curr_count > 0:
            sub_events.append(EV_FIRST_BUILD)
        elif curr_count > prev_count and curr_ids != prev_ids:
            sub_events.append(EV_NEW_BUILD)

        for ev in sub_events:
            events.append({
                "tester_id": tid,
                "event": ev,
                "prev_state": prev_state,
                "curr_state": curr_state,
                "prev_build_count": prev_count,
                "curr_build_count": curr_count,
                "name": c.get("name"),
                "email": c.get("email"),
            })

    return events


def consolidate_events(events: list[dict]) -> list[dict]:
    """If a tester has both INSTALLED and FIRST_DEVICE in the same run, fold
    them into a single INSTALLED notification (the stronger signal)."""
    by_tester: dict[str, list[dict]] = {}
    for e in events:
        by_tester.setdefault(e["tester_id"], []).append(e)

    out: list[dict] = []
    for tid, evs in by_tester.items():
        types = {e["event"] for e in evs}
        # Drop log-only events from the consolidated set first
        notif_evs = [e for e in evs if e["event"] in NOTIFIABLE_EVENTS]
        log_evs = [e for e in evs if e["event"] not in NOTIFIABLE_EVENTS]

        if EV_INSTALLED in types and EV_FIRST_BUILD in types:
            installed = next(e for e in notif_evs if e["event"] == EV_INSTALLED)
            installed["fold_first_build"] = True
            out.append(installed)
        elif EV_INSTALLED in types and EV_ACCEPTED in types:
            installed = next(e for e in notif_evs if e["event"] == EV_INSTALLED)
            out.append(installed)
        else:
            out.extend(notif_evs)

        out.extend(log_evs)
    return out


# ---- Notification queue -----------------------------------------------------

def render_message(event: dict, build_version_str: str, now_zurich: datetime) -> str:
    tid = event["tester_id"]
    meta = WATCHED_TESTERS.get(tid, {})
    prenom = meta.get("first_name") or (event.get("name") or "?").split(" ")[0]
    ev = event["event"]
    verbe, cible = EVENT_VERB.get(ev, ("a fait", "quelque chose"))
    emoji = EVENT_EMOJI.get(ev, "✨")
    fold = " (premier build détecté)" if event.get("fold_first_build") else ""
    return (
        f"SVLBH Bash — {prenom} {verbe} {cible}{fold} {emoji}\n"
        f"Build {build_version_str}\n"
        f"État ASC : {event.get('prev_state')} → {event.get('curr_state')}\n"
        f"Build(s) liés : {event.get('curr_build_count')}\n"
        f"Heure : {now_zurich.strftime('%Hh%M')}\n"
        f"🥰🙏"
    )


def append_notification(event: dict, build_version_str: str) -> dict:
    now_zurich = datetime.now(ZURICH)
    tid = event["tester_id"]
    record = {
        "ts": now_zurich.isoformat(),
        "to": NOTIFY_TO_E164,
        "via_mcp_account": NOTIFY_VIA_MCP_ACCOUNT,
        "channel": "whatsapp",
        "tester_id": tid,
        "tester_name": WATCHED_TESTERS.get(tid, {}).get("name") or event.get("name"),
        "event": event["event"],
        "message": render_message(event, build_version_str, now_zurich),
    }
    with QUEUE_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")
    return record


# ---- Logging ----------------------------------------------------------------

def write_run_log(entry: dict) -> None:
    with LOG_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


# ---- Main run ---------------------------------------------------------------

def run_once(args, private_key: str) -> int:
    state = load_state()
    prev_testers = state.get("testers", {})

    try:
        payload = fetch_beta_testers(private_key)
    except Exception as e:
        msg = f"ASC fetch failed: {e}"
        if not args.quiet:
            print(msg, file=sys.stderr)
        write_run_log({
            "ts": datetime.now(ZURICH).isoformat(),
            "ok": False,
            "error": str(e),
        })
        return 1

    parsed = parse_testers(payload, BETA_GROUP_ID)

    # --force-notify: synthesize a fake event for the given tester id and exit.
    if args.force_notify:
        tid = args.force_notify
        if tid not in WATCHED_TESTERS:
            print(f"--force-notify: id {tid} not in WATCHED_TESTERS", file=sys.stderr)
            return 1
        meta = WATCHED_TESTERS[tid]
        try:
            build_str = fetch_latest_build_str(private_key)
        except Exception:
            build_str = "?.?.? (?)"
        ev = {
            "tester_id": tid,
            "event": EV_FORCE,
            "prev_state": "TEST",
            "curr_state": "TEST",
            "prev_build_count": 0,
            "curr_build_count": 0,
            "name": meta.get("name"),
            "email": meta.get("email"),
        }
        rec = append_notification(ev, build_str)
        if not args.quiet:
            print(json.dumps(rec, ensure_ascii=False, indent=2))
        return 0

    # --init: silent baseline write, no events emitted.
    if args.init:
        new_state = {
            "testers": parsed,
            "meta": state.get("meta", {"last_telemetry_poll_at": None}),
        }
        save_state_atomic(new_state)
        if not args.quiet:
            watched = {tid: parsed[tid] for tid in WATCHED_TESTERS if tid in parsed}
            print("=== --init baseline written ===")
            print(json.dumps(watched, ensure_ascii=False, indent=2))
            print(f"\nState file: {STATE_PATH}")
            print(f"Total testers indexed: {len(parsed)}")
        write_run_log({
            "ts": datetime.now(ZURICH).isoformat(),
            "ok": True,
            "mode": "init",
            "tester_count": len(parsed),
            "events": [],
        })
        return 0

    # Normal pass: diff vs previous, emit events.
    raw_events = diff_testers(prev_testers, parsed)
    events = consolidate_events(raw_events)

    notifications: list[dict] = []
    log_only: list[dict] = []
    build_str: str | None = None

    for ev in events:
        is_watched = ev["tester_id"] in WATCHED_TESTERS
        is_notifiable = ev["event"] in NOTIFIABLE_EVENTS
        if is_watched and is_notifiable:
            if build_str is None:
                try:
                    build_str = fetch_latest_build_str(private_key)
                except Exception:
                    build_str = "?.?.? (?)"
            rec = append_notification(ev, build_str)
            notifications.append(rec)
        else:
            log_only.append(ev)

    # Persist new state (only after a successful fetch + diff).
    new_state = {
        "testers": parsed,
        "meta": state.get("meta", {"last_telemetry_poll_at": None}),
    }
    save_state_atomic(new_state)

    write_run_log({
        "ts": datetime.now(ZURICH).isoformat(),
        "ok": True,
        "mode": "once",
        "tester_count": len(parsed),
        "events": events,
        "notifications_emitted": len(notifications),
    })

    if not args.quiet:
        print(f"OK — {len(parsed)} testers, {len(events)} events, "
              f"{len(notifications)} notifications queued")
        if events:
            for ev in events:
                tag = "📣" if ev["tester_id"] in WATCHED_TESTERS and ev["event"] in NOTIFIABLE_EVENTS else "·"
                print(f"  {tag} {ev['event']:14} {ev.get('name')} "
                      f"({ev.get('prev_state')}→{ev.get('curr_state')}, "
                      f"builds {ev.get('prev_build_count')}→{ev.get('curr_build_count')})")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="SVLBH TestFlight tester status poller")
    parser.add_argument("--once", action="store_true", help="Single run (default)")
    parser.add_argument("--watch", type=int, metavar="SEC", help="Local loop interval (debug only)")
    parser.add_argument("--init", action="store_true",
                        help="Silent baseline write — required for the very first run")
    parser.add_argument("--force-notify", metavar="ID",
                        help="Emit a synthetic notification for the given tester id (e2e test)")
    parser.add_argument("--quiet", action="store_true", help="Suppress stdout (log file only)")
    args = parser.parse_args()

    private_key = load_key()

    if args.watch:
        rc = 0
        try:
            while True:
                rc = run_once(args, private_key)
                time.sleep(args.watch)
        except KeyboardInterrupt:
            return rc
        return rc

    return run_once(args, private_key)


if __name__ == "__main__":
    sys.exit(main())
