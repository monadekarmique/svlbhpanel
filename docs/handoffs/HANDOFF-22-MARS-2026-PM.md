# HANDOFF — 22 MARS 2026 (Session 2 — apres-midi)
## SVLBH Panel v1.4.0 — Builds 11-14 + Spec Roles/Sync

**Machine** : MacBook Pro (`patricktest@macbookpro.home`)
**Source** : `/Users/patricktest/Developer/SVLBHPanel-source-v1.4.0/`

---

## BUILDS DEPLOYES CETTE SESSION

| Build | Heure | Contenu |
|-------|-------|---------|
| **11** | 12:16 | ExportView P0 (Copier+Partager), Tabelle SLSA SA1-SA5, Sync Pret visible, Bug label reception, Scan sources + badge |
| **12** | 13:20 | SA1-SA5 renomme, SLSA auto-calc (100+SA2+SA3+SA4+SA5), TotSLM voyelles sacrees |
| **13** | 14:14 | Bug broadcastKeys corrige, Debug cles Push/Pull visibles, Log sync avec cle |
| **14** | 14:18 | .textSelection(.enabled) sur ExportView (copier-coller fonctionnel) |

---

## SPEC ROLES ET SYNC (document de reference)

Fichier : `SPEC-ROLES-SYNC.md` (projet + gdrive-pb68)

### Points valides radiesthesiquement :

1. **Confidentialite 100%** — shamane seule connait le patient
2. **3 tiers de codes praticien** :
   - 01-99 : Leads (alerte vortex, Patrick decide l'acces)
   - 100-299 : Formation (fork galactique probable, pas d'echange pairs)
   - 300-30000 : Certifiees (fork resolu, echange pairs autorise)
3. **Cle complete** : `PP-patientId-sessionNum-codePraticien`
   - 00 = non classifie (defaut, SVLBH Panel)
   - 01 = Recherche (attribue par Patrick dans SVLBH Panel)
   - 03/05 = Epidemie/Gradients (attribues dans App Admin)
4. **Code 01 = porte d'entree vers App Admin Recherche**
5. **Code programme sticky** : une fois attribue, herite par les seances suivantes
6. **Pas de shamane multi-recherche** (simplifie le routage)
7. **SMS individuel incremente TOUJOURS la seance**
8. **3 types de broadcast** : Normal / Urgence / Soin matinal
9. **Soin matinal** : redistribuable aux patientes (WhatsApp/screenshot)
10. **2 apps** : SVLBH Panel (terrain) + App Admin (vue transversale)
11. **Repository partage** (Make.com) entre les 2 apps
12. **Module Shamane minimum** : code, tier, prenom, nom, WhatsApp, email, abo, facturation
13. **Listes distribution automatiques** (par programme) + groupes thematiques (par pathologie)
14. **3 programmes de recherche actifs** :
    - Scleroses chromatiques transgenerationnelles multiples
    - Accumulations masculines sur l'endometre
    - Glycemies I, II et III

---

## USE CASE VALIDE — Anne (code 104, formation)

```
Anne push        → 00-731-001-104  (non classifie)
Patrick recoit   → 00-731-001-104
Patrick tagge    → 01-731-001-104  (Recherche)
Patrick renvoie  → 01-731-002-104  (SMS + increment, 01 sticky)
App Admin        → Patrick classe dans programme Glycemie
Anne revient     → 01-731-003-104  (meme patient, 01 herite)
Anne new patient → 00-xxx-001-104  (nouveau patient, 00 defaut)
```

---

## TODO PROCHAINE SESSION — ARCHITECTURE

| Prio | Quoi |
|------|------|
| **ARCH** | Architecture Make.com Data Store (repository partage) |
| **ARCH** | Schema cles PP-patientId-sessionNum-code dans le Data Store |
| **ARCH** | Refactoring PractitionerRole → systeme dynamique par plage de codes |
| **ARCH** | Module Shamane minimum (lien CRM) |
| **ARCH** | Listes de distribution / groupes thematiques |
| P0 | Texte d'aide patient/groupe dans l'app |
| P1 | Mode auto-soin (Patrick = patient) |
| P1 | Persistance locale multi-sessions |
| P2 | CIM-11 pathologies selectionnables |
| BUG | TestFlight "Elements a tester" rejette les emojis/Unicode |

---

*Relai prepare le 22 mars 2026 a 15h00 — Patrick Bays / Digital Shaman Lab*
