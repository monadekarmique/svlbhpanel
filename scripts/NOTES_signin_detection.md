# Niveau 2 — Apple Sign-In detection (Phase 1 investigation)

Goal: prove that Yvette / Daphné have actually authenticated inside the
app, not just installed the binary. Niveau 1 (`check_testers_status.py`)
already gives us the install signal via App Store Connect; Niveau 2 is
about catching the *first successful Apple Sign-In* and the
follow-up sessions.

## Findings

### Where Apple Sign-In is triggered (iOS)

`SVLBH Panel/Views/OnboardingView.swift:215-253` — `appleSignInSection`.

```swift
SignInWithAppleButton(.signIn) { request in
    request.requestedScopes = [.fullName, .email]
} onCompletion: { result in
    switch result {
    case .success(let auth):
        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
        let userID = credential.user
        let email = credential.email
        let fullName = credential.fullName
        Task {
            await identity.identifyWithApple(
                userID: userID,
                email: email,
                fullName: fullName
            )
            ...
        }
    case .failure(let err):
        error = err.localizedDescription
    }
}
```

Uses the SwiftUI `SignInWithAppleButton` (`AuthenticationServices`) — no
custom `ASAuthorizationControllerDelegate`. The post-success entry
point is the `Task { ... }` closure that calls
`identity.identifyWithApple(...)`.

### Where the credential goes after success

`SVLBH Panel/Models/SessionData.swift:604-713` — `PractitionerIdentity.identifyWithApple`.

The flow is:

1. **`lookupAppleUserID(userID:)`** (`SessionData.swift:686`) — POSTs
   `{action: "apple_lookup", apple_user_id: <id>}` to a **Make.com webhook**.
2. If lookup hits, identify locally and exit.
3. Else, fall back to UserDefaults / Keychain caches.
4. Else, if there's already a known practitioner code in this app
   instance, **register the binding** with `registerAppleUserID(...)`,
   which POSTs `{action: "apple_register", apple_user_id, code, name,
   categorie, email}` to the same webhook.

### The existing webhook

`SessionData.swift:522`:

```swift
private static let appleIdentityURL =
    URL(string: "https://hook.eu2.make.com/ril8mrrt2f97rq8r1ztip26th2nhd8zl")!
```

Make.com team: `630342`, region `eu2` (per CLAUDE.md). The webhook
already accepts `apple_lookup` and `apple_register` actions and writes
to a Make data store. Patrick's CLAUDE.md mentions
`s8920231_svlbh_h_dom_pull_response_v_2` and
`s8952437_vlbh_evernote_datastore` as available scenarios — neither
matches this webhook hash, so this is a **third, distinct scenario**
specifically for Apple identity binding.

### What's *not* tracked today

- The webhook only fires on **success** of either `apple_lookup` or
  `apple_register` — i.e. after a tester has *also* gone through the
  manual code-linking step. A brand-new sign-in by an unknown user
  (Yvette's first tap) hits the `lookupAppleUserID` branch, gets a
  miss, falls through to UserDefaults/Keychain (also misses), and
  eventually lands at line 651 — which only stashes the userID locally
  in `UserDefaults`. **No webhook ping is fired** in that branch.
- There's no Firebase / Supabase / FastAPI custom backend in the iOS
  code (greps for `firebase`, `supabase`, `backend.vlbh`, `telemetry`
  return zero hits in Swift).
- The only outbound telemetry on a sign-in event is *implicit*:
  `MakeSyncService` push, segment update, etc., which all assume the
  practitioner is already identified.

## Recommendation

**Two viable paths**, depending on how much I want to deploy.

### Option A — Reuse the existing Make.com webhook (no backend work)

Add a third action to the existing scenario:

```json
POST https://hook.eu2.make.com/ril8mrrt2f97rq8r1ztip26th2nhd8zl
{
  "action": "apple_signin_ping",
  "apple_user_id": "<credential.user>",
  "email": "<credential.email or null>",
  "name": "<credential.fullName or null>",
  "app_version": "7.5.1",
  "build_number": "85",
  "device_model": "iPhone14,2",
  "ios_version": "18.4",
  "locale": "fr-CH",
  "ts": "<ISO8601>"
}
```

Make scenario writes the row into `svlbh-v2` data store (id 155674,
already in CLAUDE.md), keyed by `apple_user_id`. First insert →
`first_seen_at` populated, subsequent inserts → upsert + bump
`total_signins`.

Then `check_testers_status.py` reads that data store via Make's HTTP
"data store get" endpoint or via a small read scenario, and matches
emails against `WATCHED_TESTERS`.

**Pros**: zero backend deployment, leverages infrastructure that's
already monitored.
**Cons**: Make data stores aren't great for time-window queries; the
read side is fiddly. Email is only available on the *very first*
sign-in (Apple drops it on subsequent calls), so the upsert key has to
be `apple_user_id` and the email is best-effort.

### Option B — Custom FastAPI endpoint on `vlbh-energy-mcp` (per the brief)

The full design from the original brief (POST
`/v1/telemetry/svlbh/signin`, two PostgreSQL tables, GET
`/v1/telemetry/svlbh/signin/recent`, `SVLBH_CLIENT_SECRET` shared
secret, fire-and-forget client) is **clean and matches the existing
post-upload script style** (JWT, Pydantic, urllib).

**Pros**: time-window queries are trivial (`WHERE last_seen_at >=
$since`), the schema is explicit, rate-limiting is straightforward,
and it doesn't add another responsibility to a Make scenario that
already binds Apple identities.
**Cons**: requires touching `vlbh-energy-mcp` (Alembic migration,
endpoint, secret rotation), an iOS code change in
`identifyWithApple` to fire-and-forget telemetry on every entry to
the function (regardless of whether the lookup hits), a new build
(7.5.2 or 7.5.1 (86)), and end-to-end validation.

### My recommendation

**Go with Option A** for the immediate need (Yvette + Daphné this
week), and keep Option B in our back pocket for any future tester
cohort where we need time-window queries or analytics.

Reason: the Make webhook already exists, the data store is already
monitored, and adding a new `action` to the scenario is a 5-minute
edit in Make.com. The only iOS change is a tiny fire-and-forget POST
inside `identifyWithApple` *before* the lookup (so we capture the
event regardless of whether the user is known yet). That's a one-line
change in Swift, no Alembic migration, no new secret to rotate, no
new build needed if we make it an action on the existing URL with the
same shape.

If Option A turns out to be insufficient (e.g. the Make data store
read side is too slow or too fiddly), we fall back to Option B as
designed.

## Next step (waiting on Patrick's go)

Either:

- **Option A path**:
  1. Add `apple_signin_ping` action to the Make scenario behind
     `https://hook.eu2.make.com/ril8mrrt2f97rq8r1ztip26th2nhd8zl`.
  2. Patch `PractitionerIdentity.identifyWithApple` (top of the
     function) to fire `await pingSigninTelemetry(...)` *before* any
     lookup — fire-and-forget, 3 s timeout.
  3. Add a Niveau 2 pass to `check_testers_status.py` that pulls
     recent rows from the Make data store and matches emails.

- **Option B path**:
  1. Implement the FastAPI endpoint, migration, secret as designed
     in the brief.
  2. Same iOS patch (fire-and-forget POST), but pointed at
     `https://backend.vlbh.energy/v1/telemetry/svlbh/signin`.
  3. Same Niveau 2 pass, pointed at the GET endpoint instead of Make.

**Stop here. Awaiting explicit go-ahead.**
