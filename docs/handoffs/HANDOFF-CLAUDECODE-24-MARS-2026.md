# HANDOFF Claude Code — SVLBHPanel v4.2.9
# 24 mars 2026 — 04h00

## CONTEXTE PROJET

App iOS SwiftUI : **SVLBHPanel** — outil praticien VLBH (Vibrational Light Body Healing)
- Projet : `/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0/`
- Team ID Xcode : `NKJ86L447D`
- Make.com PUSH webhook : `https://hook.eu2.make.com/1xhfk4o1l5pu4h23m0x26zql6oe8c3ns`
- Make.com PULL webhook : `https://hook.eu2.make.com/n00qt5bxbemy49l3woix0xaopltg8sas`
- Datastore Make : ID `155674` (nom : `svlbh-v2`)
- Format clé datastore : `{programCode}-{patientId}-{sessionNum}-{praticienCode}`
  - ex : `00-12-001-0300` (Cornelia, patient 12, session 1)
  - ex : `00-12-001-455000` (Patrick superviseur, patient 12, session 1)
- `minPatientId = 12` (les codes < 12 sont réservés aux praticiens, pas aux patients)

---

## ÉTAT ACTUEL DU CODE

### Version en source
- **MARKETING_VERSION = 4.2.9** (déjà bumped dans pbxproj)
- **CURRENT_PROJECT_VERSION = 14** (build 14, déjà bumped dans pbxproj)
- Dernière archive buildée sur Desktop : `SVLBHPanel-v4.2.8.xcarchive`
- **v4.2.9 N'A PAS ÉTÉ BUILDÉE** — le build était en cours et a été interrompu

### Fichiers modifiés cette session (déjà écrits dans le source)

**`Models/SessionData.swift` — PatientRegistry.nextId() ligne ~479**
```swift
// CORRECT — déjà en place
static func nextId() -> String {
    let current = UserDefaults.standard.integer(forKey: key)
    return String(max(current + 1, SessionState.minPatientId))
}
```
Ce fix garantit que même si `UserDefaults["svlbh_nextPatientId"]` contient 0, 1 ou n'importe quelle valeur < 12, le patientId démarre toujours à 12.

**`Services/MakeSyncService.swift` — v4.0.4**
Trois fixes déjà appliqués :
1. Debounce anti queue-drain post-update TestFlight :
```swift
private var lastPullTimestamp: Date = .distantPast
private static let minPullIntervalSeconds: TimeInterval = 3.0
// dans pull() : guard now.timeIntervalSince(lastPullTimestamp) >= Self.minPullIntervalSeconds || manual
```
2. Guard pullKey invalide dans `pull()` (rejette les clés vides ou avec `--`)
3. Guard patientId dans `scanSources()` (rejette les scans avant que patientId soit valide)

**`Views/LeadBubbleTab.swift` — NOUVEAU FICHIER**
Nouvel onglet "Lead" (tag 5) pour présentation iPad lead :
- Silhouette corps humain + 7 chakras positionnels
- Séquence 3 bulles : T+15s → Bulle 1 (Pierres) → neutraliser → Bulle 2 (Chakras/Dimensions) → neutraliser → Bulle 3 (WA button `wa.me/+41792168200`)
- Fond dégradé couleurs VLBH (`#F5EDE4` → `#8B3A62`)

**`Views/MainTabView.swift`** — Tab 5 ajouté :
```swift
LeadBubbleTab()
    .tabItem { Label("Lead", systemImage: "person.wave.2") }
    .tag(5)
```

---

## TÂCHE IMMÉDIATE

### 1. Builder et déployer v4.2.9

```bash
cd "/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0"

xcodebuild archive \
  -scheme "SVLBH Panel" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "/Users/patricktest/Desktop/SVLBHPanel-v4.2.9.xcarchive" \
  DEVELOPMENT_TEAM="NKJ86L447D" \
  2>&1 | grep -E "ARCHIVE|error:|warning.*error" | tail -10
```

Si ARCHIVE SUCCEEDED :
```bash
xcodebuild -exportArchive \
  -archivePath "/Users/patricktest/Desktop/SVLBHPanel-v4.2.9.xcarchive" \
  -exportPath "/tmp/SVLBHPanel-v4.2.9-export" \
  -exportOptionsPlist /tmp/ExportOptions.plist \
  2>&1 | grep -E "EXPORT|error:" | tail -5
```

Le fichier `/tmp/ExportOptions.plist` existe déjà (créé cette session) avec :
```xml
<key>method</key><string>app-store-connect</string>
<key>teamID</key><string>NKJ86L447D</string>
```

Puis ouvrir l'archive dans Xcode Organizer pour upload TestFlight :
```bash
open /Users/patricktest/Desktop/SVLBHPanel-v4.2.9.xcarchive
```
→ Distribute App → TestFlight & App Store → Upload

### 2. Vérifier après déploiement

Après installation TestFlight sur iPhone Cornelia (0300) et iPhone Patrick (455000) :
- Vérifier que le PUSH crée bien la clé `00-12-001-0300` dans le datastore Make ID 155674
- Vérifier absence de BundleValidationError dans les logs PULL (scénario 8903591)
- Vérifier que les rafales de PULL simultanés ont disparu (debounce 3s actif)

---

## BUGS RÉSOLUS CETTE SESSION (NE PAS RETOUCHER)

| Build | Bug | Fix |
|---|---|---|
| v4.2.6 | `nextId()` retourne 1 sur appareil vierge | `current == 0 ? 12 : current+1` |
| v4.2.7 | `nextId()` retourne 2 si UserDefaults=1 | `max(current+1, 12)` ✅ |
| v4.2.8 | PULL avec clé vide → BundleValidationError Make | guard key + guard pullKey malformée |
| **v4.2.9** | Rafale 7+ PULL simultanés post-update TestFlight | debounce 3s + guard scanSources |

---

## CONTEXTE MAKE.COM

- Scénario PUSH : `8903574` — reçoit payload iOS → écrit dans datastore `svlbh-v2`
- Scénario PULL : `8903591` — reçoit session_id → lit datastore → retourne payload
- Les deux scénarios sont actifs (`isActive: true`)
- Erreur récurrente `BundleValidationError` = session_id vide envoyé au PULL → corrigé en v4.2.8/9
- Collision de clé observée : `00-1-001-0300` (Cornelia patient 1) vs `00-1-001-0301` (Flavia) → réglé par minPatientId=12

---

## FICHIERS CLÉS

```
SVLBHPanel-source-v1.4.0/
├── SVLBH Panel.xcodeproj/project.pbxproj    ← version 4.2.9 build 14 déjà bumped
├── SVLBH Panel/
│   ├── Models/
│   │   └── SessionData.swift                ← fix nextId() max()
│   ├── Services/
│   │   └── MakeSyncService.swift            ← v4.0.4 debounce + guards
│   └── Views/
│       ├── MainTabView.swift                ← tab 5 Lead ajouté
│       ├── LeadBubbleTab.swift              ← NOUVEAU — bulles chakras lead
│       ├── PierresTab.swift                 ← inchangé
│       └── ChakrasTab.swift                 ← inchangé
```

---

## PRATICIENS / CODES

- Patrick (superviseur) : code `455000` — MacBook Pro `patricktest@macbookpro.home`
- Cornelia : code `0300` — iPhone 16 Pro de test (numéro test = +41792168200)
- Flavia : code `0301`
- Anne (simulée) : code `0302`
- `minPatientId = 12` — les IDs 1–11 sont réservés aux praticiens eux-mêmes

---

*Généré automatiquement par Claude claude.ai — session 24 mars 2026 ~04h00*
