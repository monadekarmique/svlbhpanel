# SVLBH Panel — v4.0.3 Claude Code Session
# 3 BUGS BLOQUANTS + 1 UI FIX + 1 SPEC

## CONTEXTE
- **Machine** : MacBook Pro (`patricktest@macbookpro.home`)
- **Source** : `/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0/`
- **Version actuelle** : 4.0.2 (TestFlight build 1)
- **Cible** : 4.0.3

## TABLE DES CODES (référence absolue v4)

| Praticienne | code (stocké) | codeFormatted | Tier |
|-------------|---------------|---------------|------|
| Patrick     | 455000        | 455000        | Superviseur |
| Cornelia    | 300           | 0300          | Certifiée |
| Flavia      | 301           | 0301          | Certifiée |
| Anne        | 302           | 0302          | Certifiée |

Format clé datastore : `{PP}-{patientId}-{sessionNum}-{praticienCode}`
PP = "00" (non classifiée) ou "01" (Recherche)

---

## BUG ROOT CAUSE — MISMATCH `code` vs `codeFormatted`

`ShamaneProfile.code` = `"300"` (stocké en UserDefaults)
`ShamaneProfile.codeFormatted` = `"0300"` (padded via `%04d` pour certifiées)

Le code utilise tantôt `.code`, tantôt `.codeFormatted` pour construire les clés.
Résultat : Cornelia PUSH avec `codeFormatted` → clé `00-713-001-0300`,
mais Patrick PULL avec `code` brut → cherche `00-713-001-300` → MISS.

**RÈGLE** : TOUJOURS utiliser `codeFormatted` dans les clés sync.
Vérifier et corriger CHAQUE endroit où `.code` est utilisé dans une clé.

---

## FIX 1 — Pull Key format (A1 + C2 + C10) — 3 remontées, récurrent

**Fichiers** : `SessionData.swift`, `MakeSyncService.swift`

### SessionData.swift — `pullKey`
Vérifier que `pullKey` utilise `src.codeFormatted` (pas `.code`) :
```swift
var pullKey: String {
    if role.isPatrick, let src = pullSource {
        return "\(sessionProgramCode)-\(patientId)-\(sessionNum)-\(src.codeFormatted)"
    } else {
        return "\(sessionProgramCode)-\(patientId)-\(sessionNum)-\(ActiveRole.patrickCode)"
    }
}
```
→ Vérifier que `src.codeFormatted` est bien utilisé, pas `src.code`.

### MakeSyncService.swift — `scanSources()`
Ligne qui construit la clé de scan :
```swift
let key = "\(session.patientId)-\(session.sessionNum)-\(shamane.codeFormatted)"
```
→ Vérifier que le préfixe `sessionProgramCode` est inclus :
```swift
let key = "\(session.sessionProgramCode)-\(session.patientId)-\(session.sessionNum)-\(shamane.codeFormatted)"
```

### MakeSyncService.swift — `resolveNextSessionNum()`
Vérifier que `praticienCode` passé est bien `role.code` qui retourne
`codeFormatted` pour les shamanes (vérifier dans `ActiveRole.code`).

### Enum `Shamane` (dropdown) — rawValue vs code
`Shamane.cornelia.rawValue = "0300"` → OK, aligné avec `codeFormatted`.
Vérifier que dans `doPush()` de SyncBar, le matching utilise `codeFormatted`.

---

## FIX 2 — Formule SA1/SLSA (A3 + B1)

**Fichier** : `SessionData.swift` — struct `ScoresLumiere`

### Bug A3 : "14% SLSA ne peut pas valoir 29 et 29 en SA1"
Cornelia saisit SA1=29 mais SLSA affiche 14%. Le `slsaAutoCalc` est correct
(`SA1 + SA2 + SA3 + SA4 + SA5`), mais le problème est dans le BINDING :

**Vérifier dans SLMTab.swift** :
1. Le TextField pour SA1 bind-t-il sur `scoresTherapist.slsa` (correct)
   ou sur un autre champ ?
2. Quand SA1 est saisi, `recalcSLSA()` est-il appelé ?
3. Le label SLSA affiche-t-il `slsaEffective` ou `slsa` brut ?

### Bug B1 : "67 en SA4 ne peut pas donner 140%"
Si SA4=67 et SLSA=140, c'est cohérent SI d'autres SA sont renseignés
(ex: SA1=50 + SA4=67 + SA2=23 = 140). Mais si SEUL SA4=67, SLSA
devrait être 67. Vérifier que `slsaAutoCalc` ne double-compte pas.

**Rappel mémoire** : SLSA peut légitimement dépasser 100% (jusqu'à 50 000%).
Ne PAS plafonner. Le bug est dans le calcul, pas dans la plage.

### Fix probable
Dans `ScoresLumiere` :
```swift
var slsaAutoCalc: Int {
    (slsa ?? 0) + (slsaS2 ?? 0) + (slsaS3 ?? 0) + (slsaS4 ?? 0) + (slsaS5 ?? 0)
}
```
Si `slsa` EST SA1, alors la formule est correcte. Mais vérifier que les
TextFields dans SLMTab.swift lient bien :
- SA1 → `$session.scoresTherapist.slsa`
- SA2 → `$session.scoresTherapist.slsaS2`
- SA3 → `$session.scoresTherapist.slsaS3`
- SA4 → `$session.scoresTherapist.slsaS4`
- SA5 → `$session.scoresTherapist.slsaS5`

Si un TextField lie SA1 au mauvais champ, c'est la cause.

---

## FIX 3 — Merge invisible côté Patrick (A2)

**Fichier** : `MakeSyncService.swift` — `applyPayload()` + `pull()`

### Symptôme
Cornelia PUSH → Patrick PULL → aucune fusion, aucune suggestion.

### Causes possibles (vérifier dans l'ordre)
1. **Pull Key mismatch** (même root cause que FIX 1) :
   Patrick construit pullKey avec `code` ("300") au lieu de `codeFormatted` ("0300")
   → Make.com ne trouve pas le record → retourne vide → rien à merger.

2. **applyPayload() ne parse pas** :
   Si le payload reçu est un JSON wrapper (ex: `{"payload": "..."}`)
   au lieu du texte brut, `applyPayload` ne trouvera aucune ligne parseable.
   Vérifier ce que `pull()` retourne exactement.

3. **Suggestions écrasées** :
   `applyPayload` appelle `clearSuggestions()` au début. Si le payload
   est vide (cause 1), les suggestions sont cleared sans rien ajouter.

### Test de validation
Après fix, simuler :
- Cornelia PUSH `00-713-001-0300` (payload avec G15, pierres, scores)
- Patrick sélectionne pullSource = Cornelia
- Patrick PULL → pullKey = `00-713-001-0300` (doit matcher)
- Résultat attendu : suggestions 🔬 visibles, diffLog non vide

---

## FIX 4 — Volumes pierres illisibles (A4)

**Fichier** : `SVLBH Panel/Views/PierresTab.swift`

Le volume peut atteindre 3 chiffres (ex: 150 kg). L'affichage actuel
tronque ou rend illisible les valeurs > 99.

### Fix
- Élargir le champ volume : `frame(minWidth: 50)` au lieu de la largeur actuelle
- Ou passer en layout `.fixedSize()` sur le HStack volume+unité
- Vérifier aussi dans `SVLBHTab.swift` → `PierresKPICard` que le volume
  s'affiche correctement

---

## SPEC — Code Patrick (A5)

**Décision** : Cornelia demande Patrick = code 800.
Actuellement Patrick = 455000 (implémenté F29 v4.0.0).

**NE PAS CHANGER** dans ce build. Garder 455000.
Si Patrick confirme le changement vers 800, ce sera un item v4.1.0
avec re-migration.

---

## ORDRE D'EXÉCUTION

```
1.  Lire SessionData.swift — zone pullKey, sessionId, ActiveRole.code
2.  FIX 1a — Vérifier/corriger pullKey utilise codeFormatted
3.  Lire MakeSyncService.swift — scanSources(), resolveNextSessionNum()
4.  FIX 1b — Ajouter préfixe sessionProgramCode dans scanSources() key
5.  FIX 1c — Vérifier ActiveRole.code retourne codeFormatted pour shamanes
6.  Lire SLMTab.swift — bindings SA1–SA5
7.  FIX 2 — Corriger bindings SLSA si nécessaire
8.  FIX 3 — Si pullKey corrigé (FIX 1), tester que pull retourne du contenu
9.  Lire PierresTab.swift — layout volume
10. FIX 4 — Élargir affichage volume 3 chiffres
11. Build test → corriger erreurs
12. Bump MARKETING_VERSION → 4.0.3 (6 occurrences pbxproj)
13. Headers Swift concernés → // v4.0.3
14. Archive → upload TestFlight
```

---

## RÉFÉRENCES

- Push : `https://hook.eu2.make.com/1xhfk4o1l5pu4h23m0x26zql6oe8c3ns`
- Pull : `https://hook.eu2.make.com/n00qt5bxbemy49l3woix0xaopltg8sas`
- Datastore : svlbh-v2 (ID 155674, zone eu2)
- Team ID : NKJ86L447D
- Signing : Apple Development: Patrick Bays (VQ5VP5JJ6G)
- Couleurs : #8B3A62 / #C27894 / #F5EDE4 / #B8965A
- **SLSA peut dépasser 100%** (jusqu'à 50 000%) — ne jamais plafonner

---
*PROMPT-CLAUDE-CODE-v4.0.3.md — Digital Shaman Lab — 23 mars 2026*
