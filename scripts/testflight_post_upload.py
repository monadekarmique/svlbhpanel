#!/usr/bin/env python3
"""
Post-upload automation for SVLBH Panel TestFlight builds.

Runs after xcodebuild upload:
  1. Polls ASC for the latest build of the app (waits until it appears and is VALID)
  2. Creates or updates the fr-FR Beta Build Localization with the "What to Test" text
     read from scripts/whats_to_test_fr.txt
  3. Links the build to the external beta group "SVLBH Bash 3 à 5"
  4. Submits the build to Apple Beta App Review

Requires:
  - Python 3.9+
  - PyJWT with cryptography: pip3 install 'pyjwt[crypto]'
  - ASC API key at ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8

Usage:
  python3 scripts/testflight_post_upload.py
  python3 scripts/testflight_post_upload.py --build-version 85   # target a specific build number
  python3 scripts/testflight_post_upload.py --skip-submit        # link only, don't submit to review
"""

import argparse
import json
import os
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

try:
    import jwt  # pyjwt
except ImportError:
    sys.stderr.write(
        "ERROR: pyjwt is not installed. Run: pip3 install 'pyjwt[crypto]'\n"
    )
    sys.exit(1)

# ---- Configuration (edit here if the app or group changes) ----
APP_ID = "6760935383"                                    # SVLBH Panel
BETA_GROUP_ID = "90a16e04-0f26-437f-85bd-613d7ecba262"   # SVLBH Bash 3 à 5 (external)
KEY_ID = "2VRW78KLKM"
ISSUER_ID = "06df5236-7489-4e45-bca4-1fef3aa9855a"
KEY_PATH = Path.home() / ".appstoreconnect" / "private_keys" / f"AuthKey_{KEY_ID}.p8"
LOCALE = "fr-FR"

SCRIPT_DIR = Path(__file__).resolve().parent
WHATS_TO_TEST_PATH = SCRIPT_DIR / "whats_to_test_fr.txt"

POLL_INTERVAL_SEC = 30
POLL_TIMEOUT_SEC = 30 * 60   # 30 minutes max to wait for processing

API_BASE = "https://api.appstoreconnect.apple.com"


# ---- JWT + HTTP helpers ----
def load_key() -> str:
    if not KEY_PATH.exists():
        sys.exit(f"ERROR: ASC API key not found at {KEY_PATH}")
    return KEY_PATH.read_text()


def make_token(private_key: str) -> str:
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(
        payload,
        private_key,
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )


def api_request(private_key, method: str, path: str, body=None):
    url = API_BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", "Bearer " + make_token(private_key))
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return resp.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read() or b""
        try:
            return e.code, json.loads(raw)
        except json.JSONDecodeError:
            return e.code, {"raw": raw.decode(errors="replace")}


# ---- ASC operations ----
def fetch_latest_build(private_key, target_version: str | None):
    """Return (build_id, attributes) for the latest build, optionally matching a specific version number."""
    path = (
        f"/v1/builds?filter[app]={APP_ID}"
        f"&sort=-uploadedDate&limit=10"
    )
    code, data = api_request(private_key, "GET", path)
    if code != 200:
        raise RuntimeError(f"Failed to list builds: {code} {data}")
    builds = data.get("data", [])
    if not builds:
        return None, None
    if target_version:
        for b in builds:
            if b["attributes"].get("version") == str(target_version):
                return b["id"], b["attributes"]
        return None, None
    return builds[0]["id"], builds[0]["attributes"]


def wait_for_valid_build(private_key, target_version: str | None):
    """Poll until a build appears and reaches processingState=VALID."""
    deadline = time.time() + POLL_TIMEOUT_SEC
    last_state = None
    while time.time() < deadline:
        bid, attrs = fetch_latest_build(private_key, target_version)
        if bid:
            state = attrs.get("processingState")
            if state != last_state:
                print(f"  build {attrs.get('version')} → processingState={state}")
                last_state = state
            if state == "VALID":
                return bid, attrs
            if state in ("FAILED", "INVALID"):
                raise RuntimeError(f"Build {attrs.get('version')} processing failed: {state}")
        else:
            print("  waiting for build to appear on ASC…")
        time.sleep(POLL_INTERVAL_SEC)
    raise TimeoutError("Timed out waiting for build to become VALID")


def get_or_create_beta_build_localization(private_key, build_id: str, whats_new: str):
    """Ensure a fr-FR Beta Build Localization exists with the given whatsNew text."""
    code, data = api_request(
        private_key, "GET", f"/v1/builds/{build_id}/betaBuildLocalizations"
    )
    if code != 200:
        raise RuntimeError(f"Failed to list beta build localizations: {code} {data}")

    bbl_id = None
    for loc in data.get("data", []):
        if loc["attributes"].get("locale") == LOCALE:
            bbl_id = loc["id"]
            break

    if bbl_id:
        body = {
            "data": {
                "type": "betaBuildLocalizations",
                "id": bbl_id,
                "attributes": {"whatsNew": whats_new},
            }
        }
        code, data = api_request(
            private_key, "PATCH", f"/v1/betaBuildLocalizations/{bbl_id}", body
        )
        if code != 200:
            raise RuntimeError(f"Failed to PATCH beta build localization: {code} {data}")
        print(f"  ✓ What to Test updated on existing {LOCALE} localization ({bbl_id})")
    else:
        body = {
            "data": {
                "type": "betaBuildLocalizations",
                "attributes": {"locale": LOCALE, "whatsNew": whats_new},
                "relationships": {
                    "build": {"data": {"type": "builds", "id": build_id}}
                },
            }
        }
        code, data = api_request(
            private_key, "POST", "/v1/betaBuildLocalizations", body
        )
        if code != 201:
            raise RuntimeError(f"Failed to create beta build localization: {code} {data}")
        print(f"  ✓ What to Test created ({LOCALE}) on build {build_id}")


def link_build_to_beta_group(private_key, build_id: str):
    """Add the build to the external beta group (idempotent)."""
    code, data = api_request(
        private_key, "GET", f"/v1/betaGroups/{BETA_GROUP_ID}/builds?limit=50"
    )
    if code != 200:
        raise RuntimeError(f"Failed to list group builds: {code} {data}")
    existing_ids = {b["id"] for b in data.get("data", [])}
    if build_id in existing_ids:
        print(f"  ✓ build already linked to beta group")
        return

    body = {"data": [{"type": "builds", "id": build_id}]}
    code, data = api_request(
        private_key, "POST", f"/v1/betaGroups/{BETA_GROUP_ID}/relationships/builds", body
    )
    if code not in (200, 204):
        raise RuntimeError(f"Failed to link build to beta group: {code} {data}")
    print(f"  ✓ build linked to beta group {BETA_GROUP_ID}")


def submit_to_beta_review(private_key, build_id: str):
    """Create a Beta App Review submission for the build (no-op if already submitted).

    Apple's API is inconsistent here:
      - 201 = newly submitted
      - 409 = conflict, already submitted (rare)
      - 422 ENTITY_UNPROCESSABLE.INVALID_QC_STATE = already in a review/testing state
    We check the externalBuildState first to make this idempotent.
    """
    states_already_past_submission = {
        "WAITING_FOR_BETA_REVIEW",
        "IN_BETA_REVIEW",
        "IN_BETA_TESTING",
        "BETA_REJECTED",  # rejected, would need a new build — don't re-submit blindly
    }
    code, data = api_request(
        private_key, "GET", f"/v1/builds/{build_id}/buildBetaDetail"
    )
    if code == 200:
        external_state = data["data"]["attributes"].get("externalBuildState")
        if external_state in states_already_past_submission:
            print(
                f"  ℹ build already in externalBuildState={external_state}"
                f" — skipping submission"
            )
            return

    body = {
        "data": {
            "type": "betaAppReviewSubmissions",
            "relationships": {
                "build": {"data": {"type": "builds", "id": build_id}}
            },
        }
    }
    code, data = api_request(private_key, "POST", "/v1/betaAppReviewSubmissions", body)
    if code == 201:
        state = data["data"]["attributes"].get("betaReviewState")
        print(f"  ✓ submitted to Beta App Review (state={state})")
        return
    # 409 and 422/INVALID_QC_STATE both indicate "already submitted or in review"
    if code in (409, 422):
        errors = data.get("errors", []) if isinstance(data, dict) else []
        codes = [e.get("code", "") for e in errors]
        if code == 409 or any("INVALID_QC_STATE" in c for c in codes):
            print("  ℹ build already submitted to Beta App Review")
            return
    raise RuntimeError(f"Failed to submit to Beta App Review: {code} {data}")


# ---- Main ----
def main():
    parser = argparse.ArgumentParser(description="Post-upload TestFlight automation")
    parser.add_argument(
        "--build-version",
        help="Target a specific build number (e.g. 85). Default: latest.",
    )
    parser.add_argument(
        "--skip-submit",
        action="store_true",
        help="Do not submit to Beta App Review (link + localize only).",
    )
    parser.add_argument(
        "--whats-to-test",
        default=str(WHATS_TO_TEST_PATH),
        help=f"Path to What to Test text file (default: {WHATS_TO_TEST_PATH})",
    )
    args = parser.parse_args()

    whats_to_test_file = Path(args.whats_to_test)
    if not whats_to_test_file.exists():
        sys.exit(f"ERROR: What to Test file not found: {whats_to_test_file}")
    whats_new = whats_to_test_file.read_text().strip()
    if not whats_new:
        sys.exit(f"ERROR: What to Test file is empty: {whats_to_test_file}")

    private_key = load_key()

    print("==> Waiting for build on ASC")
    build_id, attrs = wait_for_valid_build(private_key, args.build_version)
    print(f"  ✓ build {attrs['version']} VALID (id={build_id})")

    print("==> Updating What to Test")
    get_or_create_beta_build_localization(private_key, build_id, whats_new)

    print("==> Linking build to external beta group")
    link_build_to_beta_group(private_key, build_id)

    if args.skip_submit:
        print("==> Skipping Beta App Review submission (--skip-submit)")
    else:
        print("==> Submitting to Beta App Review")
        submit_to_beta_review(private_key, build_id)

    print("\n✅ Post-upload automation complete.")
    print("External testers will be notified once Apple approves the Beta App Review.")


if __name__ == "__main__":
    main()
