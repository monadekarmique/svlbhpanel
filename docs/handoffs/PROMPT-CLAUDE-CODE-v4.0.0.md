# SVLBH Panel — v4.0.0 Claude Code Session

## CONTEXTE
- **Machine** : MacBook Pro (`patricktest@macbookpro.home`)
- **Source** : `/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0/`
- **Version actuelle** : 3.0.2 (TestFlight)
- **Cible** : 4.0.0

---

## TABLE DES CODES PRATICIENS (référence absolue)

| Praticienne | Code   | Tier        |
|-------------|--------|-------------|
| Patrick     | 455000 | Superviseur |
| Cornelia    | 300    | Certifiée   |
| Flavia      | 301    | Certifiée   |
| Anne        | 302    | Certifiée   |

Plages : 01–99 Lead · 100–299 Formation · 300–30000 Certifiée · 455000 Superviseur

---

## TABLE DES CODES PROGRAMME (référence absolue)

| Code | Nom | Attribué depuis |
|------|-----|-----------------|
| 00   | Non classifiée (défaut) | SVLBH Panel (auto) |
| 01   | Recherche | SVLBH Panel (Patrick uniquement) |
| 03   | Épidémie | App Admin uniquement |
| 05   | Gradients | App Admin uniquement |

**RÈGLE CRITIQUE** : Dans SVLBH Panel, Patrick peut UNIQUEMENT switcher entre 00 et 01.
Les codes 03 et 05 sont réservés à l'App Admin (pas dans ce build).

---

## 5 FEATURES — dans cet ordre : F29 → F28 → F30 → F26 → F25

---

### F29 — Code superviseur Patrick = 455000

**Fichier** : `SVLBH Panel/Models/SessionData.swift`

Ajouter `.superviseur` dans `PractitionerTier` :
```swift
case superviseur // 455000 → badge #8B3A62 "SUPERVISEUR"

static func from(code: String) -> PractitionerTier {
    guard let n = Int(code) else { return .lead }
    switch n {
    case 455000:       return .superviseur
    case 300...30000:  return .certifiee
    case 100...299:    return .formation
    default:           return .lead
    }
}
```

Dans `ActiveRole` : changer `case .patrick: return "01"` → `return "455000"`
Badge UI `.superviseur` : fond `#8B3A62`, label "SUPERVISEUR".
Vérifier : aucun hardcode "01" résiduel dans MakeSyncService / SyncBar / clés.

---

### F28 — Migration codes certifiées au premier lancement 4.0.0

**Fichier** : `SVLBH Panel/Models/SessionData.swift`

```swift
let codesMigration: [String: String] = [
    "25": "300",    // Cornelia
    "27": "301",    // Flavia
    "26": "302",    // Anne
    "01": "455000"  // Patrick
]
```

Lors du chargement `ShamaneProfile` depuis UserDefaults :
- Si `profile.code` ∈ `codesMigration` → remplacer + sauvegarder
- Logger : "Migration code XX → YYY"

---

### F30 — Préfixe 2 chiffres programme dans la clé + export

**Fichier** : `SVLBH Panel/Models/SessionData.swift`

Ajouter `programCode: String` dans `ResearchProgram` + mettre à jour les defaults :
```swift
struct ResearchProgram: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var nom: String
    var programCode: String  // "01", "03", "05"
    var actif: Bool = true
    var shamaneCodes: [String] = []
}

static let defaults: [ResearchProgram] = [
    ResearchProgram(id: "SCT", nom: "Scleroses chromatiques transgenerationnelles multiples", programCode: "01"),
    ResearchProgram(id: "AME", nom: "Accumulations masculines sur l'endometre",               programCode: "03"),
    ResearchProgram(id: "GLY", nom: "Glycemies I, II et III",                                 programCode: "05"),
]
```

Ajouter dans `SessionState` :
```swift
@Published var sessionProgramCode: String = "00"  // "00" = non classifiée
```

Modifier `sessionId` — la clé inclut TOUJOURS le préfixe :
```swift
var sessionId: String {
    "\(sessionProgramCode)-\(patientId)-\(sessionNum)-\(role.code)"
}
```

**UI dans SVLBHTab.swift (Patrick uniquement) :**
- Toggle ou Picker à 2 valeurs : `"00 — Non classifiée"` / `"01 — Recherche"`
- Visible uniquement si `role.isPatrick`
- Bind sur `sessionState.sessionProgramCode`
- Les shamanes ne voient PAS ce contrôle
- Les codes 03 et 05 ne sont PAS dans ce Picker (App Admin seulement)

**Fichier** : `SVLBH Panel/Services/SessionExporter.swift`

Dans la fonction `export()`, après la ligne date, ajouter :
```swift
if session.sessionProgramCode != "00" {
    let label = session.sessionProgramCode == "01" ? "Recherche" : session.sessionProgramCode
    lines += ["Programme : \(session.sessionProgramCode) · \(label)"]
}
```

---

### F26 — PatientId 1–30000 choisi par la shamane

**Fichier** : `SVLBH Panel/Models/SessionData.swift` — struct `ShamaneProfile`
```swift
var patientId: Int = 1  // 1–30000
```

**Fichier** : `TherapistManagerView` dans `SVLBHTab.swift`
- TextField `.keyboardType(.numberPad)`, validation `1...30000`, texte rouge si hors plage
- Persistance UserDefaults

Vérifier : `SessionState.patientId` utilise `shamaneProfile.patientId` (pas hardcodé).

---

### F25 — Fork galactique conditionnel au tier

**Fichier** : `SVLBH Panel/Views/DecodageTab.swift`

```swift
var currentTier: PractitionerTier {
    switch sessionState.activeRole {
    case .patrick: return .superviseur
    case .shamane(let p): return p.tier
    }
}
```

```swift
switch currentTier {
case .superviseur:
    // Tout visible — aucun filtre

case .certifiee:
    // Card collapsed : "✓ Fork résolu par la certification"

case .formation, .lead:
    // Card fond #F5EDE4, bordure #B8965A, label "Fork galactique"
    // — TextField "Code séphirothique principal"
    // — DisclosureGroup "5 codes secondaires" → 5 TextFields
}
```

---

## VERSIONING

1. `MARKETING_VERSION` → `4.0.0` dans `.pbxproj` (6 occurrences)
2. Headers Swift → `// v4.0.0`
3. Archive → upload TestFlight

---

## RÉFÉRENCES

- Push : `https://hook.eu2.make.com/1xhfk4o1l5pu4h23m0x26zql6oe8c3ns`
- Pull : `https://hook.eu2.make.com/n00qt5bxbemy49l3woix0xaopltg8sas`
- Team ID : NKJ86L447D · Signing : Apple Development: Patrick Bays (VQ5VP5JJ6G)
- Couleurs : `#8B3A62` / `#C27894` / `#F5EDE4` / `#B8965A`

---

## ORDRE D'EXÉCUTION

```
1.  Lire SessionData.swift
2.  F29 → .superviseur + code 455000 Patrick
3.  F28 → migration 25→300 / 27→301 / 26→302 / 01→455000
4.  F30 → programCode dans ResearchProgram + sessionProgramCode + sessionId préfixé
5.  F26 → patientId Int dans ShamaneProfile + UI
6.  Lire DecodageTab.swift
7.  F25 → fork conditionnel au tier
8.  Lire SessionExporter.swift
9.  F30 export → ligne "Programme : XX · label" si ≠ 00
10. Build test → corriger erreurs
11. Bump 4.0.0 + archive + TestFlight
```

---
*PROMPT-CLAUDE-CODE-v4.0.0.md — Digital Shaman Lab — 23 mars 2026*
