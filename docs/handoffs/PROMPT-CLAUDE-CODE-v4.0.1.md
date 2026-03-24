# SVLBH Panel — v4.0.1 Claude Code Session
# BUG FIX — BundleValidationError PULL Make

## CONTEXTE
- **Machine** : MacBook Pro (`patricktest@macbookpro.home`)
- **Source** : `/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0/`
- **Version actuelle** : 4.0.0 (TestFlight build 1)
- **Cible** : 4.0.1

---

## BUG IDENTIFIÉ — 1 seul fichier à corriger

**Fichier** : `SVLBH Panel/Models/SessionData.swift`

### Symptôme
`BundleValidationError: Validation failed for 1 parameter` sur SVLBH PULL v2 #8903591.
Make reçoit une `session_id` malformée → champ `key` vide → erreur.

### Cause — pullKey sans préfixe programme (F30 non propagé)

```swift
// ACTUEL (ligne ~522) — INCORRECT ❌
var pullKey: String {
    if role.isPatrick, let src = pullSource {
        return "\(patientId)-\(sessionNum)-\(src.codeFormatted)"
    } else {
        return "\(patientId)-\(sessionNum)-\(ActiveRole.patrickCode)"
    }
}
```

```swift
// CORRIGÉ ✅ — même préfixe sessionProgramCode que pushKey
var pullKey: String {
    if role.isPatrick, let src = pullSource {
        return "\(sessionProgramCode)-\(patientId)-\(sessionNum)-\(src.codeFormatted)"
    } else {
        return "\(sessionProgramCode)-\(patientId)-\(sessionNum)-\(ActiveRole.patrickCode)"
    }
}
```

### Cause secondaire — patientId String vide par défaut

`SessionState.patientId` est une `String` initialisée à `""` (ligne ~461).
En v4.0.0 (F26), `ShamaneProfile.patientId` est un `Int` (1–30000).
Si `SessionState.patientId` n'est pas alimenté depuis `ShamaneProfile`,
la clé devient `"00--001-455000"` → Make rejette la clé.

**Vérifier** (ne pas casser l'existant) :
- Dans `resetForShamane()` ou lors du switch de rôle vers `.shamane(profile)` :
  s'assurer que `self.patientId = String(profile.patientId)` est bien appelé.
- Si ce n'est pas le cas, ajouter dans le `didSet` de `role` :
```swift
if case .shamane(let p) = role {
    patientId = String(p.patientId)
}
```

---

## ORDRE D'EXÉCUTION

```
1. Lire SessionData.swift lignes 518–530 (zone pullKey)
2. Corriger pullKey → ajouter sessionProgramCode en préfixe
3. Lire resetForShamane() et didSet de role → vérifier alimentation patientId
4. Corriger si patientId non alimenté depuis ShamaneProfile
5. Build test → corriger erreurs
6. Bump MARKETING_VERSION → 4.0.1 dans .pbxproj (6 occurrences)
7. Headers Swift concernés → // v4.0.1
8. Archive → upload TestFlight
```

---

## TEST DE VALIDATION POST-FIX

Après déploiement, vérifier dans Make Data Store (svlbh-v2, ID 155674) :
- Clé créée = `00-{patientId}-{sessionNum}-455000` (Patrick)
- Clé créée = `00-{patientId}-{sessionNum}-300` (Cornelia)
- Aucun BundleValidationError dans les exécutions PULL

---

## RÉFÉRENCES

- Push webhook : `https://hook.eu2.make.com/1xhfk4o1l5pu4h23m0x26zql6oe8c3ns`
- Pull webhook : `https://hook.eu2.make.com/n00qt5bxbemy49l3woix0xaopltg8sas`
- Team ID : NKJ86L447D
- Signing : Apple Development: Patrick Bays (VQ5VP5JJ6G)

---
*PROMPT-CLAUDE-CODE-v4.0.1.md — Digital Shaman Lab — 23 mars 2026*
