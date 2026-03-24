# CLAUDE CODE — PROMPT SESSION v3.0.3
## 5 feedbacks TestFlight à traiter

**Projet** : `/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0/`
**Version actuelle** : 3.0.2 (TestFlight)
**Spec de référence** : `SPEC-ROLES-SYNC.md` dans le projet — LIS-LE D'ABORD
**Handoff** : `HANDOFF-23-MARS-2026.md` dans le projet — LIS-LE AUSSI
**Cible** : Build v3.0.3, deploy TestFlight après chaque fix

---

## F01 — Cap leads + liste d'attente (SPEC + FEAT)

### Contexte
Les leads (codes 01-99) sont des personnes qui testent l'app.
Patrick ne peut gérer que MAX 5 leads simultanément.
Quand il est au max, les nouveaux leads doivent être mis en liste d'attente.
Quand sa sécurité et celle de Cornelia sont assurées, il libère 5 places.

### Ce qu'il faut coder
1. Dans `SessionState` : ajouter `maxActiveLeads = 5`
2. Nouveau modèle `LeadSlot` :
   - `shamaneCode` (String)
   - `status` : `.active` / `.waiting` / `.completed`
   - `createdAt` (Date)
3. Dans `SessionState` : `@Published var leadSlots: [LeadSlot]` (persisté UserDefaults)
4. Computed : `activeLeadCount`, `waitingLeads`, `canAcceptLead`
5. Quand Patrick scanne et reçoit d'un code 01-99 :
   - Si `activeLeadCount < 5` → accepter, badge LEAD rouge
   - Sinon → ajouter en liste d'attente, badge orange "EN ATTENTE"
6. Vue : dans `SVLBHTab` ou section dédiée, afficher :
   - "Leads actifs : 3/5"
   - Liste des leads en attente avec bouton "Activer" (si place dispo)
7. Quand Patrick active un lead → pierres de protection vortex rappelées

### Fichiers à modifier
- `SessionData.swift` : LeadSlot, leadSlots, persistence
- `SVLBHTab.swift` : section leads visible uniquement pour Patrick
- `SyncBar.swift` : alerte quand réception d'un lead

---

## F02 — Shamane Profile enrichi (FEAT)

### Contexte
Le profil shamane doit montrer les 5 zones déséquilibrées
et permettre d'uploader un set de photos persistantes multi-session.

### Ce qu'il faut coder
1. Dans `ShamaneProfile` : ajouter
   - `zones: [String]` (max 5 zones déséquilibrées, texte libre)
   - `photoSetId: String?` (lien vers un `ReferenceImageSet`)
2. Dans `TherapistManagerView` (le formulaire shamane existant) :
   - Section "Zones déséquilibrées" : 5 champs texte
   - Section "Photos" : bouton pour lier un ReferenceImageSet existant
     ou en créer un nouveau (redirige vers ReferenceSystemView)
3. Les photos sont persistantes multi-session (déjà géré via UserDefaults
   dans ReferenceImageSet — vérifier que ça marche)
4. Dans la vue profil shamane (visible par Patrick) :
   - Afficher les 5 zones sous le nom
   - Miniature du set de photos

### Fichiers à modifier
- `SessionData.swift` : ShamaneProfile (champs zones + photoSetId)
- `SVLBHTab.swift` : TherapistManagerView (formulaire enrichi)

---

## F05 — Documentation calcul charges méridiens (DOC)

### Contexte
Patrick demande "Comment sont calculées les charges sur les méridiens ?"
La réponse doit être visible dans l'app sous forme de définitions.

### Ce qu'il faut coder
1. Dans `SVLBHTab.swift`, sous la section méridien dominant :
   - Ajouter un bouton "?" ou texte d'aide dépliable
2. Texte d'aide :
   ```
   Charges méridiens : comptage du nombre de fois qu'un méridien
   apparaît dans les générations validées (✓). Le méridien dominant
   est celui avec le plus d'occurrences. Méridiens observés :
   SP, KI, LR, HT, PC, LU, GB.
   Référence : `Meridian.observed` dans le code.
   ```
3. Style : même que ScoreDefinitions dans SLMTab (fond gris léger, 13pt)

### Fichiers à modifier
- `SVLBHTab.swift` : section info méridiens

---

## F07 — Vérifier la fusion (BUG)

### Contexte
Cornelia a reporté "Reçu de Patrick sans fusion" sur le Build 12.
Le bug broadcastKeys (qui poussait vers les mauvaises clés) a été corrigé
dans le Build 13 et porté dans v3.0.2. MAIS il faut vérifier que :

### Ce qu'il faut vérifier
1. `broadcastKeys(target:)` dans SessionState retourne bien `[pushKey]`
   → C'est le cas (ligne 522: `return [pushKey]`)
2. `applyPayload` fait bien du MERGE et pas du RESET
   → Vérifier que les generations ne sont pas réinitialisées
3. Le `pullKey` côté shamane pointe bien vers Patrick (code "01")
   → Vérifier `pullKey` computed property
4. TEST MANUEL : faire un push depuis Patrick, puis un pull depuis une shamane
   - Utiliser curl pour simuler :
   ```bash
   # Push test
   curl -X POST "https://hook.eu2.make.com/1xhfk4o1l5pu4h23m0x26zql6oe8c3ns" \
     -H "Content-Type: application/json" \
     -d '{"session_id":"14968-001-01","payload":"SVLBH test merge\nSLA_T:89 SLSA_T:100 SLM_T:50 TotSLM_T:200\nG15|✓|ab:s|Câlins|vi:a|Choix de mes rêves|ph:Survie|gu:Core Wound|mt:SP KI|st:O"}'

   # Pull test (simule Cornelia)
   curl -X POST "https://hook.eu2.make.com/n00qt5bxbemy49l3woix0xaopltg8sas" \
     -H "Content-Type: application/json" \
     -d '{"session_id":"14968-001-01"}'
   ```
5. Si le merge ne fonctionne toujours pas, ajouter du logging :
   - Logger chaque ligne parsée dans diffLog
   - Logger le nombre de générations matchées

### Fichiers à vérifier/modifier
- `MakeSyncService.swift` : applyPayload, mergeGeneration, mergePierre, mergeChakra
- `SessionData.swift` : pullKey, broadcastKeys

---

## F16 — CIM-11 pathologies sélectionnables (FEAT)

### Contexte
Dans ChakrasTab, certains chakras ont des codes CIM-11 associés
(champ `cimCodes` dans `ChakraInfo`, et `hasCIM` booléen).
Actuellement les codes sont affichés mais pas sélectionnables.

### Ce qu'il faut coder
1. Dans `DimensionsData.swift` : vérifier et compléter les `cimCodes`
   pour les chakras qui en ont (D1-D3 principalement).
   Structure existante : `cimCodes: [(code: String, label: String)]`
2. Dans `ChakrasTab.swift` : pour chaque chakra avec `hasCIM == true`,
   afficher les codes CIM-11 comme des toggles individuels (pas un bloc)
3. Nouveau dans `SessionState` :
   - `@Published var selectedCIM: [String: Set<String>]` = [:]
     Clé = chakra key (ex: "d1_1"), Valeur = Set de codes CIM sélectionnés
4. UI : sous chaque chakra avec CIM, liste dépliable de codes
   - Chaque code = toggle ON/OFF
   - Badge compteur de codes sélectionnés sur le chakra
5. Export : ajouter les codes CIM sélectionnés dans `SessionExporter.export()`
   Format : `CIM|D1|C1|BA80.0 Endometriose,BA80.1 ...`
6. Import : parser les lignes CIM dans PasteParser

### Fichiers à modifier
- `DimensionsData.swift` : compléter cimCodes
- `SessionData.swift` : selectedCIM
- `ChakrasTab.swift` : toggles CIM par chakra
- `SessionExporter.swift` : export CIM
- `PasteParser.swift` : import CIM

---

## RÈGLES GÉNÉRALES

- Lire SPEC-ROLES-SYNC.md et HANDOFF-23-MARS-2026.md AVANT de coder
- Tous les headers Swift : `// v3.0.3`
- Bumper `MARKETING_VERSION` → 3.0.3 dans le pbxproj
- BUILD + TEST dans le simulateur avant archive
- Archive + Upload TestFlight après tous les fixes
- Les couleurs de marque : #8B3A62 (rose profond), #C27894 (rose moyen),
  #F5EDE4 (beige), #B8965A (or). Jamais de fond noir.
- Méridiens toujours en anglais : SP, LR, LU, LI, ST, KI, HT, PC, TE, GB, GV, CV
- `.textSelection(.enabled)` sur tout texte que l'utilisateur pourrait vouloir copier
