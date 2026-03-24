# HANDOFF — 23 MARS 2026
## SVLBH Panel v3.0.2 — Architecture Rôles + Shamanes + Distribution + Systèmes de référence

**Machine** : MacBook Pro (`patricktest@macbookpro.home`)
**Source** : `/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0/`
**Version** : 3.0.2 (déployée TestFlight le 23 mars 2026)
**Drive** : `monade.karmique@gmail.com`

---

## CE QUI A ÉTÉ FAIT CETTE SESSION

### Chantier 3 — Refactoring PractitionerRole → ActiveRole
**Avant** : Enum hardcodé `PractitionerRole` avec 4 cas fixes (cornelia, anne, flavia, patrick) et codes en dur (25, 26, 27, 01).

**Après** : `ActiveRole` enum dynamique :
- `.patrick` → code "01" (superviseur fixe)
- `.shamane(ShamaneProfile)` → code dérivé du tier (2/3/4 chiffres)
- Plus de limite à 3 shamanes — nombre illimité
- Menu rôle dans SyncBar : Patrick + toutes les shamanes enregistrées
- `pullSource` est maintenant `ShamaneProfile?`
- `pendingSources` dans MakeSyncService : `[ShamaneProfile]`
- `scanSources()` itère dynamiquement `shamaneProfiles`

**Fichiers modifiés** : SessionData.swift, MakeSyncService.swift, SyncBar.swift, SVLBHTab.swift, SLMTab.swift, MainTabView.swift

---

### Chantier 4 — Module Shamane minimum
**Avant** : `CertifiedTherapist` avec seulement `name` + `code` (4 chiffres).

**Après** : `ShamaneProfile` struct complet :
- `code` (String) — généré par tier
- `prenom`, `nom` (String)
- `whatsapp`, `email` (String)
- `abonnement` (String)
- `prochainFacturation` (Date?)
- `tier` (computed) → `PractitionerTier.from(code:)`

**PractitionerTier** enum :
- `.lead` (01-99) → badge rouge "LEAD"
- `.formation` (100-299) → badge orange "EN FORMATION"
- `.certifiee` (300-30000) → badge vert "CERTIFIÉE"

**TherapistManagerView** refait : formulaire complet avec Picker tier, liste groupée par tier avec badges colorés.

**Migration** : ancien format `svlbh_certified` → `ShamaneProfile` automatique.

---

### Chantier 5 — Listes de distribution et groupes thématiques

**Nouveaux modèles** :
- `ResearchProgram` (id, nom, actif, shamaneCodes) — 3 programmes par défaut :
  1. Scleroses chromatiques transgenerationnelles multiples
  2. Accumulations masculines sur l'endometre
  3. Glycemies I, II et III
- `ThematicGroup` (id, nom, shamaneCodes) — manuels, créés par Patrick
- `BroadcastTarget` enum : `.allCertifiees` / `.program(...)` / `.group(...)`

**CRUD complet** : add/remove programmes et groupes, add/remove shamane à un programme/groupe.

**DistributionView** (nouveau fichier) : onglet segmenté Programmes / Groupes, vue dépliable, gestion membres.

**Broadcast ciblé** dans SyncBar : menu 3 niveaux (Toutes certifiées / Par programme / Par groupe).

---

### Systèmes de référence (groupes d'images)

**Modèle** : `ReferenceImageSet` (id, nom, description, imageFileNames, createdAt)
- Pointe vers le Drive local : `mft-2022-04-11-magnetic-field-light/` (229 images)
- CRUD complet + persistence UserDefaults

**ReferenceSystemView** (nouveau fichier) :
- Liste des systèmes avec preview 6 thumbnails
- Composer : grille de 229 images du Drive, sélection tap, boutons Tout/Rien
- Éditer un système existant
- Bouton Broadcast prêt (câblage Make.com à brancher)

**Accès** : Menu "..." → "Systèmes de référence" (Patrick only)

---

### Version et déploiement
- Rebase propre depuis build 11 (fixes 12-14 cherry-pickés)
- Version bumped : 1.4.0 → **3.0.2**
- `MARKETING_VERSION = 3.0.2` (6 occurrences pbxproj)
- Headers Swift tous alignés v3.0.2
- Archive + upload App Store Connect : **OK**
- TestFlight : **déployée**

---

## ARCHITECTURE ACTUELLE DES FICHIERS

```
SVLBH Panel/
├── Models/
│   ├── SessionData.swift          ← ActiveRole, PractitionerTier, ShamaneProfile,
│   │                                 ResearchProgram, ThematicGroup, BroadcastTarget,
│   │                                 ReferenceImageSet, SessionState
│   └── DimensionsData.swift       ← Dimensions/Chakras (inchangé)
├── Services/
│   ├── MakeSyncService.swift      ← Push/Pull/Scan/Broadcast ciblé
│   ├── SessionExporter.swift      ← Export texte (inchangé)
│   └── PasteParser.swift          ← Import texte (inchangé)
├── Views/
│   ├── MainTabView.swift          ← TabView principal
│   ├── SVLBHTab.swift             ← Dashboard + TherapistManagerView
│   ├── SyncBar.swift              ← Rôles dynamiques + broadcast menu
│   ├── SLMTab.swift               ← Scores SLA/SLSA/SLM
│   ├── DecodageTab.swift          ← Générations (inchangé)
│   ├── PierresTab.swift           ← Pierres (inchangé)
│   ├── ChakrasTab.swift           ← Chakras (inchangé)
│   ├── DistributionView.swift     ← Programmes + Groupes thématiques
│   ├── ReferenceSystemView.swift  ← Systèmes de référence (images)
│   ├── ExportView.swift           ← Export WhatsApp
│   ├── PasteImportView.swift      ← Import collé
│   └── DiffLogView.swift          ← Log de sync
```

---

## SPEC DE RÉFÉRENCE

Le document `SPEC-ROLES-SYNC.md` dans le projet définit :
- Confidentialité 100% (shamane seule connaît le patient)
- 4 tiers de codes praticien (Lead/Formation/Certifiée/Superviseur)
- Clé complète : `PP-patientId-sessionNum-codePraticien`
- 3 modes de travail Patrick (supervision, auto-soin, réception)
- 3 types broadcast (normal, urgence, soin matinal)
- 2 apps : SVLBH Panel (terrain) + App Admin (vue transversale)
- Repository partagé Make.com entre les 2 apps

---

## TODO PROCHAINE SESSION

| Prio | Quoi | Notes |
|------|------|-------|
| **ARCH 1** | Architecture Make.com Data Store | Repository partagé entre Panel et App Admin |
| **ARCH 2** | Schéma clés PP-patientId-sessionNum-code | Préfixe programme dans le Data Store |
| **FEAT** | Broadcast images via Make.com | Câbler ReferenceImageSet → webhook |
| P0 | Texte d'aide patient/groupe dans l'app | |
| P1 | Mode auto-soin (Patrick = patient) | |
| P1 | Persistance locale multi-sessions | |
| P2 | CIM-11 pathologies sélectionnables | |
| BUG | TestFlight "Éléments à tester" rejette emojis/Unicode | |
| **FEEDBACK** | Feedback TestFlight v3.0.2 | À traiter — Patrick a un retour |

---

## DONNÉES DE RÉFÉRENCE

- **Make.com Push** : `https://hook.eu2.make.com/1xhfk4o1l5pu4h23m0x26zql6oe8c3ns`
- **Make.com Pull** : `https://hook.eu2.make.com/n00qt5bxbemy49l3woix0xaopltg8sas`
- **Team ID** : NKJ86L447D
- **Signing** : Apple Development: Patrick Bays (VQ5VP5JJ6G)
- **Drive images** : `monade.karmique@gmail.com` → `palettemulticouleur/mft-2022-04-11-magnetic-field-light/` (229 fichiers)
- **Shamanes phase test** : Cornelia (25), Anne (26), Flavia (27) — maintenant dynamiques via ShamaneProfile

---

*Relai préparé le 23 mars 2026 — Patrick Bays / Digital Shaman Lab*
