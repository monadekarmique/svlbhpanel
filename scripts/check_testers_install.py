#!/usr/bin/env python3
"""Check TestFlight tester install state for Daphné Friederich & Yvette Dayer Bersier.
One-shot exploratory ASC API call. Run from Patrick's Mac.
"""
import json
import time
import urllib.request
import urllib.error
from pathlib import Path

try:
    import jwt  # pyjwt
except ImportError:
    print("ERROR: pyjwt not installed. Run: pip3 install pyjwt[crypto]")
    raise SystemExit(1)

KEY_CANDIDATES = [
    Path.home() / ".appstoreconnect" / "private_keys" / "AuthKey_2VRW78KLKM.p8",
    Path("/Users/patricktest/private_keys/AuthKey_2VRW78KLKM.p8"),
]

ISSUER_ID = "06df5236-7489-4e45-bca4-1fef3aa9855a"
KEY_ID = "2VRW78KLKM"
AUDIENCE = "appstoreconnect-v1"
APP_ID = "6760935383"

TESTERS = {
    "Yvette Dayer Bersier": "3112801c-390d-4e9e-b32e-d57bed5e6ff4",
    "Daphné Friederich":    "c310b46d-5221-4dad-b2de-7f195eb76278",
}


def load_private_key() -> str:
    for p in KEY_CANDIDATES:
        if p.exists():
            return p.read_text()
    raise FileNotFoundError(
        "AuthKey_2VRW78KLKM.p8 not found in either ~/.appstoreconnect/private_keys/ "
        "or /Users/patricktest/private_keys/"
    )


def mint_jwt() -> str:
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 1200,  # 20 min max
        "aud": AUDIENCE,
    }
    headers = {"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}
    token = jwt.encode(payload, load_private_key(), algorithm="ES256", headers=headers)
    return token if isinstance(token, str) else token.decode()


def asc_get(path: str, token: str):
    url = f"https://api.appstoreconnect.apple.com{path}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        try:
            body = json.loads(e.read().decode())
        except Exception:
            body = {"raw": "<unparseable>"}
        return e.code, body
    except Exception as e:
        return 0, {"exception": str(e)}


def describe_tester(name: str, tid: str, token: str) -> dict:
    print(f"\n=== {name}  id={tid} ===")
    result = {"name": name, "id": tid}

    # 1) Basic tester info + relationships
    status, body = asc_get(
        f"/v1/betaTesters/{tid}?include=apps,betaGroups,builds",
        token,
    )
    result["status"] = status
    if status != 200:
        print(f"  HTTP {status} : {json.dumps(body)[:400]}")
        return result

    data = body.get("data", {})
    attrs = data.get("attributes", {})
    rels = data.get("relationships", {})
    included = body.get("included", [])

    print(f"  attributes : {json.dumps(attrs, ensure_ascii=False)}")
    result["attributes"] = attrs

    # Count relationships
    n_builds = len(rels.get("builds", {}).get("data", []))
    n_groups = len(rels.get("betaGroups", {}).get("data", []))
    n_apps = len(rels.get("apps", {}).get("data", []))
    print(f"  linked apps={n_apps}  groups={n_groups}  builds={n_builds}")
    result["linked_builds"] = n_builds
    result["linked_groups"] = n_groups


    # 2) Walk included builds to show version / uploadedDate / expired
    builds_info = []
    for inc in included:
        if inc.get("type") == "builds":
            b_attrs = inc.get("attributes", {})
            bi = {
                "id": inc.get("id"),
                "version": b_attrs.get("version"),
                "uploadedDate": b_attrs.get("uploadedDate"),
                "expired": b_attrs.get("expired"),
                "processingState": b_attrs.get("processingState"),
            }
            builds_info.append(bi)
            print(
                f"    build v{bi['version']}  uploaded={bi['uploadedDate']}  "
                f"expired={bi['expired']}  state={bi['processingState']}"
            )
    result["builds"] = builds_info

    # 3) Try the metrics endpoint (per-tester session/install stats)
    status_m, body_m = asc_get(
        f"/v1/betaTesters/{tid}/apps",
        token,
    )
    if status_m == 200:
        n_apps_m = len(body_m.get("data", []))
        print(f"  /apps endpoint OK : {n_apps_m} app(s)")
    else:
        print(f"  /apps endpoint HTTP {status_m}")

    return result


def main():
    print("Signing JWT ES256...")
    try:
        token = mint_jwt()
    except Exception as e:
        print(f"JWT signing FAILED: {e}")
        raise SystemExit(2)
    print(f"JWT OK ({len(token)} chars)")

    # Fetch latest builds of the app for context
    status, body = asc_get(
        f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=3",
        token,
    )
    print(f"\nLatest builds for app {APP_ID} (HTTP {status}):")
    if status == 200:
        for b in body.get("data", []):
            a = b.get("attributes", {})
            print(
                f"  build id={b.get('id')}  v{a.get('version')}  "
                f"uploaded={a.get('uploadedDate')}  expired={a.get('expired')}"
            )
    else:
        print(f"  error: {json.dumps(body)[:300]}")

    results = []
    for name, tid in TESTERS.items():
        results.append(describe_tester(name, tid, token))

    print("\n\n=== SUMMARY JSON ===")
    print(json.dumps(results, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
