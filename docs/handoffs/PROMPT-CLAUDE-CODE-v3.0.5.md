# CLAUDE CODE — PROMPT SESSION v3.0.5
## Feedbacks v3.0.4 + résidus v3.0.3

**Projet** : `/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0/`
**Version actuelle** : 3.0.4 (TestFlight)
**Spec** : `SPEC-ROLES-SYNC.md` — LIS-LE D'ABORD
**Cible** : Build v3.0.5, deploy TestFlight

---

## F30 — BUG CIM-11 : tickbox active le mauvais checkbox

### Contexte
Quand on active le tickbox CIM-11 sur un chakra, c'est le tickbox
du chakra à DROITE qui s'active au lieu du bon.

### Diagnostic probable
Bug d'indexation dans ChakrasTab.swift — le toggle CIM modifie
`selectedCIM` avec la mauvaise clé (décalage d'index).

### Ce qu'il faut vérifier et corriger
1. Dans `ChakrasTab.swift`, trouver les toggles CIM-11
2. Vérifier que la clé utilisée pour `selectedCIM[key]` correspond
   bien au chakra affiché et pas au chakra suivant
3. Tester : activer CIM sur C1 → seul C1 doit s'activer

---

## F31 — SLSA = somme directe SA1+SA2+SA3+SA4+SA5

### Contexte
SLSA ne doit PAS être 100 + somme. C'est la SOMME DIRECTE :
SLSA = SA1 + SA2 + SA3 + SA4 + SA5

### Ce qu'il faut corriger
1. Dans `SessionData.swift`, modifier `slsaAutoCalc` :
   - AVANT : `100 + (slsaS2 ?? 0) + ...`
   - APRES : `(slsa ?? 0) + (slsaS2 ?? 0) + (slsaS3 ?? 0) + (slsaS4 ?? 0) + (slsaS5 ?? 0)`
   - En fait SLSA = SA1 + SA2 + SA3 + SA4 + SA5
   - Donc `slsaEffective` = somme de tous les SA renseignés
2. Mettre à jour `hasDetailedSLSA` : true si AU MOINS SA2 renseigné
3. Quand hasDetailedSLSA = true, SLSA = somme. Sinon SLSA = SA1 seul.
4. Mettre à jour les définitions dans SLMTab :
   - "SLSA = SA1 + SA2 + SA3 + SA4 + SA5"
   - Plus de mention de "100 +"
5. Mettre à jour la légende du tableau :
   "SA1 = SLSA si seul, sinon SLSA = somme SA1 a SA5"

---

## F32 — Reset sessions : shamanes = 1, Patrick = actuel

### Contexte
Recréer la session depuis le début pour toutes les shamanes (sessionNum = "001").
Patrick garde sa session actuelle.

### Ce qu'il faut coder
1. Dans SessionState, ajouter une méthode `resetForShamane()` :
   - sessionNum = "001"
   - Réinitialiser generations, pierres, chakras, scores
   - Conserver patientId (la shamane le choisit)
2. Cette méthode est appelée automatiquement quand le rôle change
   vers une shamane (`.shamane(...)`)
3. Patrick (`.patrick` / code 455000) conserve toujours sa session
4. Menu ⋯ → "Nouvelle session" pour reset manuel

---

## F03 + F06 — textSelection sur définitions et décodage iPad

### Contexte
Résidu des feedbacks v1.4.0 build 14 et 12 :
- F03 : Copier-coller les définitions SLM
- F06 : Copier-coller les décodages depuis iPad

### Ce qu'il faut coder
1. Ajouter `.textSelection(.enabled)` sur :
   - `ScoreDefinitions` dans SLMTab.swift (chaque ScoreDefRow)
   - DecodageTab.swift (labels abuseur, victime, phases, gu, méridiens)
   - SVLBHTab.swift (InfoRow values, méridien dominant, fork)
2. Vérifier que ExportView a déjà `.textSelection(.enabled)` (fait Build 14)

---

## INTERFACE PAR TIER — vérifier l'implémentation v3.0.4

### Vérifier que ces éléments sont en place
Si Claude Code v3.0.5 (prompt précédent) les a implémentés, vérifier.
Sinon les implémenter :

1. **Leads (01-99)** : affichent "Toi", bouton WhatsApp +41798131926
2. **Formation (100-299)** : affichent leur numéro, WhatsApp +41792168200
3. **Certifiées (300-30000)** : affichent numéro certification, WhatsApp +41799302800
4. **Superviseur (455000)** : Patrick, vue complète

### Numéros WhatsApp par tier
| Tier | WhatsApp | Format lien |
|------|----------|-------------|
| Lead | +41 79 813 19 26 | https://wa.me/41798131926 |
| Formation | +41 79 216 82 00 | https://wa.me/41792168200 |
| Certifiée | +41 79 930 28 00 | https://wa.me/41799302800 |

---

## RÈGLES GÉNÉRALES

- Tous les headers Swift : `// v3.0.5`
- Bumper `MARKETING_VERSION` → 3.0.5 dans le pbxproj
- BUILD + TEST simulateur avant archive
- Archive + Upload TestFlight
- Couleurs marque : #8B3A62, #C27894, #F5EDE4, #B8965A. Jamais fond noir.
- `.textSelection(.enabled)` sur TOUT texte que l'utilisateur pourrait copier
- Build visible en entier dans l'app : "3.0.5 (N)" — vérifier F27
- Patrick code superviseur = 455000
