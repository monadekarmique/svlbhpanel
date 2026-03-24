# HANDOFF — 22 MARS 2026
## SVLBH Panel v1.4.0 — Session TestFlight + Merge/Suggestions

**Machine** : MacBook Pro (`patricktest@macbookpro.home`)
**Source** : `/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0/`
**App Store Connect** : SVLBH Bash (ID 6760935383) — Team NKJ86L447D
**ExportOptions** : `/tmp/ExportOptions-TF.plist` (method: app-store-connect, upload, automatic signing)

---

## ÉTAT ACTUEL — BUILD 10 DÉPLOYÉ SUR TESTFLIGHT ✅

### Builds déployés aujourd'hui (22 mars 2026)
| Build | Heure | Contenu |
|-------|-------|---------|
| **5** | 08:47 | Scores lisibles iPhone, définitions SLM, SyncBar SVLBH only, iPad tabs en bas |
| **6** | 08:59 | Pierres kg/t en gros avec feedback visuel |
| **7** | 09:09 | Bouton "OK" toolbar clavier numberPad SLM + tap-to-dismiss |
| **8** | 09:37 | Définitions SLM 13pt, Pierres VStack (pas de chevauchement), icônes ₩, KPI Pierres ₩ |
| **9** | 09:55 | Scores @ObservedObject, Combine relay nested changes, Obsidienne "G-4" supprimé, durationDays=5 |
| **10** | 10:58 | **MERGE + SUGGESTIONS 🔬** — plus d'écrasement, système de propositions bleues |

### 5 Testeurs actifs (groupe "SVLBH Bash 1")
| Testeur | Email | Device | iOS |
|---------|-------|--------|-----|
| Patrick Bays | pb@vlbh.energy | iPhone 13 Pro +1 | 26.4 |
| Patrick Bays | bays.patrick@icloud.com | (2ème compte dev) | — |
| Cornelia Althaus | cornelia.althaus@hotmail.com | iPhone 16 Pro | 26.3.1 |
| Flavia Guift | flaviaguift@icloud.com | iPhone Air | 26.3.1 |
| Anne Grangier Brito | anne.gr29@gmail.com | iPad (A16) +1 | 26.3.1 |

---

## ARCHITECTURE MERGE + SUGGESTIONS 🔬 (Build 10)

### Principe
- **Plus de Reset** — les données locales sont préservées lors de la réception
- Champ local **vide** + Patrick propose → remplissage silencieux
- Champ local **identique** → rien à faire
- Champ local **différent** → stocké en suggestion 🔬 (bleu #185FA5)
- **Scores SLA/SLSA/SLM** → application directe (supervision, pas de suggestion)
- Adoption **individuelle** par champ — pas de "Tout adopter"

### Modèle (SessionData.swift)
**Generation** — 6 champs suggestion ajoutés :
- `sugAbuseur`, `sugVictime`, `sugPhases`, `sugGu`, `sugMeridiens`, `sugStatuts`
- `hasSuggestions: Bool` (computed), `clearSuggestions()` (méthode)

**PierreState** — 5 champs suggestion ajoutés :
- `sugSelected`, `sugVolume`, `sugUnit`, `sugDurationMin`, `sugDurationDays`
- `hasSuggestions: Bool`, `clearSuggestions()`

**SessionState** :
- `sugChakraStates: [String: Bool]` — suggestions chakras Patrick
- `import Combine` + `cancellables` — relay nested ObservableObject changes

### Service (MakeSyncService.swift)
- `applyPayload` → mode MERGE (plus de Reset)
- `mergeGeneration()`, `mergePierre()`, `mergeChakra()` — remplacent les anciens parsers
- `mergeField()` / `mergeSetField()` — helpers génériques string/set
- `MergeResult { merged, suggestions }` — compteurs

### Vues
**DecodageTab.swift** :
- Badge 🔬 dans le header de chaque génération avec suggestions
- Suggestions par champ sous chaque section (abuseur, victime, phases, gu, méridiens, statuts)
- `SuggestionAdopt` — composant bouton bleu pour champ string
- `SuggestionSetAdopt` — composant bouton bleu pour set de valeurs

**PierresTab.swift** :
- Pierre non sélectionnée + suggestion → bord bleu pointillé + "Proposée · 3t"
- Pierre sélectionnée + suggestion différente → suggestion volume/durée en bleu sous les valeurs
- Bouton ✓ individuel qui adopte et clearSuggestions()

**ChakrasTab.swift** :
- `isSuggested` computed sur chaque ChakraRow
- Badge 🔬 bleu tapable à côté du checkbox → adopte le chakra
- Compteur suggestions `sugInDim` par dimension dans le header
- Fond bleu léger pour chakras suggérés

**PasteImportView.swift** :
- "Écraser les données actuelles ?" → "Fusionner avec les données actuelles ?"
- Bouton "Importer" destructif → bouton "Fusionner" normal

---

## AUTRES CORRECTIONS APPLIQUÉES (Builds 5–9)

| Fichier | Changement |
|---------|------------|
| **SVLBHTab.swift** | `ScoresKPICard` refait en `ScoreRow` (13pt bold), layout vertical, `@ObservedObject` |
| **SVLBHTab.swift** | `PierresKPICard` + `ChakrasKPICard` → `@ObservedObject` (re-render temps réel) |
| **SVLBHTab.swift** | KPI Pierres icône ◆ → ₩ |
| **SLMTab.swift** | Barres comparaison supprimées → `ScoreDefinitions` (définitions SLA/SLSA/SLM/TotSLM) |
| **SLMTab.swift** | Définitions font 11pt → 13pt, couleur `.primary.opacity(0.75)` |
| **SLMTab.swift** | Toolbar clavier "OK" + `@FocusState` + `hideKeyboard()` tap-to-dismiss |
| **MainTabView.swift** | SyncBar conditionnée `selectedTab == 0` (SVLBH uniquement) |
| **MainTabView.swift** | `.tabViewStyle(.tabBarOnly)` via `TabBarOnlyModifier` (iOS 18+ avec fallback) |
| **PierresTab.swift** | `PierreDetail` restructuré VStack — volume 22pt bold, sélecteur kg/t séparé |
| **SessionData.swift** | 8 icônes pierres → toutes ₩ |
| **SessionData.swift** | Obsidienne noire : "G-4" supprimé du rôle, `defaultDays` = 5 |
| **SessionData.swift** | `import Combine` + relay nested changes via `objectWillChange.sink` |

---

## FEEDBACKS TESTFLIGHT — ÉTAT AU 22 MARS 10h58

### ✅ Résolus
| Feedback | Testeur | Corrigé dans |
|----------|---------|-------------|
| Scores illisibles iPhone (onglet SVLBH) | Patrick | Build 5 |
| Barres comparaison inutiles (SLM) → définitions | Patrick | Build 5 |
| SyncBar sur tous les onglets → SVLBH only | Cornelia | Build 5 |
| iPad onglets pas en bas | Patrick | Build 5 |
| "Problème : je vois pas les kg" | Cornelia | Build 6 |
| "Coincée" (clavier bloqué) | Cornelia | Build 7 |
| Clavier numberPad sans bouton Done | Patrick | Build 7 |
| "Teste trop petit" (définitions SLM) | Patrick | Build 8 |
| "chevauchement — manque les tonnes" | Patrick | Build 8 |
| Symboles pierres → ₩ | Patrick | Build 8 |
| Scores SLM pas reflétés dans SVLBH | Patrick | Build 9 |
| Pierres sélection pas reflétée dans SVLBH | Patrick | Build 9 |
| Obsidienne "G-4" + jours 5 | Patrick | Build 9 |
| "Fusionner données importées" (Anne) | Anne | Build 10 |
| Clavier s'enlève mais onglets bloqués (Anne) | Anne | Build 9 (fix OK confirmé) |

### 🔜 TODO — Prochaine session
| Prio | Feedback | Testeur | Détail |
|------|----------|---------|--------|
| **P0** | Export WhatsApp bloque sur iPhone | Patrick | ShareSheet iOS bloque sur WhatsApp app — ajouter bouton "Copier" clipboard |
| **P1** | Expliquer mécanisme patient/groupe | Patrick | Texte d'aide : numéro anonyme, sessions, code shamane, confidentialité, + vert = urgence |
| **P2** | CIM-11 pathologies sélectionnables | Patrick | Toggle individuel par code CIM-11 dans ChakrasTab |

---

## CONTEXTE PRODUIT — POUR LA PROCHAINE SESSION

### But de l'app (à intégrer dans le texte d'aide P1)
La thérapeute transmet son décodage à Patrick **sans transgresser la confidentialité** :
- Patrick ne sait jamais qui est la patiente
- Numéro anonyme (ex: 728, 021, 1523, 14968) défini par la thérapeute
- Nombre de sessions (001, 002…) = sessions déjà travaillées ou pressenties
- Code Shamane = son numéro de formation
- Toggle **Patient** = décodage individuel, **Système** = constellation énergétique
- **+ vert** = demande d'aide **urgente**, numérotée, traitée en priorité
- Tout le reste = traité **à bien plaire**

---

## PROCÉDURE DEPLOY TESTFLIGHT (depuis MacBook Pro)

```bash
# Build
cd "/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0"
xcodebuild -scheme "SVLBH Panel" -destination "platform=iOS Simulator,name=iPhone 17 Pro" build 2>&1 | grep -E "error:|BUILD"

# Archive
xcodebuild -scheme "SVLBH Panel" -configuration Release -destination "generic/platform=iOS" archive \
  -archivePath /tmp/SVLBHPanel-v1.4.0-bN.xcarchive

# Export + Upload TestFlight
xcodebuild -exportArchive \
  -archivePath /tmp/SVLBHPanel-v1.4.0-bN.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions-TF.plist \
  -exportPath /tmp/SVLBHPanel-v1.4.0-bN-export
```

Le build apparaît automatiquement dans le groupe "SVLBH Bash 1" (4 testeurs internes).
Les testeurs font pull-to-refresh dans TestFlight pour voir la mise à jour.

---

## FICHIERS MODIFIÉS AUJOURD'HUI

| Fichier | Lignes | Changements clés |
|---------|--------|-------------------|
| `Models/SessionData.swift` | ~370 | sug* fields, Combine relay, icônes ₩, Obsidienne fix |
| `Services/MakeSyncService.swift` | ~295 | applyPayload merge, mergeGeneration/Pierre/Chakra |
| `Views/SVLBHTab.swift` | ~400 | ScoresKPICard refait, @ObservedObject, ScoreRow |
| `Views/SLMTab.swift` | ~260 | ScoreDefinitions, toolbar OK, hideKeyboard |
| `Views/DecodageTab.swift` | ~320 | SuggestionAdopt, SuggestionSetAdopt, badges 🔬 |
| `Views/PierresTab.swift` | ~240 | PierreDetail VStack, suggestions pierres, bord pointillé |
| `Views/ChakrasTab.swift` | ~190 | isSuggested, badge 🔬, sugInDim compteur |
| `Views/MainTabView.swift` | ~100 | SyncBar tab 0 only, TabBarOnlyModifier |
| `Views/PasteImportView.swift` | ~118 | Écraser → Fusionner |

---

## NOTES TECHNIQUES

- **ContinuityCaptureAgent** : process macOS qui consomme 93% CPU. `launchctl disable` ne suffit pas, il respawn. **Action user** : Réglages système → Général → AirDrop et Handoff → désactiver Caméra Continuity.
- **RAM** : 16 GB saturée (153 MB libre). Fermer Chrome ou Claude Desktop quand les deux sont ouverts.
- **Thermal** : niveau 140, CPU throttlé à 34%. Lié au ContinuityCaptureAgent + charge builds.
- **SSH iMac→MacBook** : bloqué (host key verification failed). Non résolu.

---

*Relai préparé le 22 mars 2026 à 11h00 — Patrick Bays / Digital Shaman Lab*
