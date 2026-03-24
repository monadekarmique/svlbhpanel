# Spec HistoryTab — VIFA v0.5.x
# SVLBHPanel — 24 mars 2026

## Terminologie

**VIFA** = Vibration Intervalle Fréquences Accumulation
- ≠ identifiant personne
- = code d'un pattern vibratoire familial / séphirothique / pathologique
- associé à des images de soin spécifiques (mapping interne)
- partagé entre tous les praticiens qui traitent ce pattern
- plusieurs porteurs humains peuvent avoir le même VIFA

---

## Structure de la clé SVLBH — nomenclature définitive

```
{prog}-{VIFA}-{sessionNum}-{codePraticien}

prog         = programme de soin
                00 = soin standard
                01 = programme recherche (SCT, AME, GLY...)

VIFA         = identifiant du pattern vibratoire (ex: 345, 12, 14968)
               ≥ 12 (codes 1-11 réservés aux praticiens)

sessionNum   = numéro de session CHOISI LIBREMENT par le praticien
               → jamais auto-incrémenté de façon transparente
               → Patrick peut sauter des slots (001, 002, 004...)
               → Cornelia s'aligne sur la session transmise par Patrick

codePraticien = qui réalise le soin
                0300   = Cornelia
                455000 = Patrick (superviseur)
                0301   = Flavia
                0302   = Anne
```

---

## Use Case jour 1 — VIFA 345, soin 21 jours

```
1. Cornelia réalise → PUSH  00-345-001-0300
2. Patrick reçoit (PULL), décide :
     ├─ Pas de programme → 00-345-001-0300 inchangé
     └─ Élève en recherche → PUSH 01-345-001-0300 (nouveau prog)
3. Patrick fait N opérations dans la journée :
     01-345-002-455000   (opération 1)
     01-345-004-455000   (opération 2, slots libres)
4. Patrick transmet → Cornelia via PIN iMessage
```

## Use Case jour 2 — Cornelia consulte l'historique

```
1. Cornelia ouvre HistoryTab
2. Choisit VIFA dans sa liste connue (ou saisit librement)
3. Query datastore → toutes clés contenant -{VIFA}-
4. Affichage empilé (plus récent en haut) :
     01 · S004 · 🔬 Patrick  · J+1 09:08  SLA:24
     01 · S002 · 🔬 Patrick  · J+1 08:51  SLA:24
     00 · S001 · 🐱 Cornelia · J+0 16:36  READ
5. Cornelia tape S004 (dernier soin Patrick)
   → lazy PULL payload complet
   → pré-remplit programCode = 01, sessionNum = 005
6. Stepper rapide [−] 005 [+]
   → si plusieurs soins dans la journée : 005, 006, 007...
7. PUSH → 01-345-005-0300
```

---

## HistoryTab — spec technique

### Liste VIFA connus
- Source : `fetchAllRecordKeys()` → filtre `codePraticien = role.code`
- Extrait les VIFA distincts depuis les clés
- Affichage : `code VIFA + image associée` (mapping interne VIFARegistry)
- + champ recherche libre

### Vue historique d'un VIFA
- Query : toutes clés contenant `-{VIFA}-` (tous praticiens)
- Parse depuis la clé : prog, VIFA, sessionNum, codePraticien
- Parse depuis le payload header : date, praticien emoji, SLA_T, SLSA_T
- Tri : sessionNum DESC (plus récent en haut), praticien comme secondary sort
- Marqueur READ = consommé, jamais effacé — fait partie de l'historique
- Tap sur une ligne = lazy PULL du payload complet dans un sheet

### Pré-remplissage après sélection
- programCode = depuis la session sélectionnée
- sessionNum = maxSessionNum + 1 parmi toutes les clés de ce VIFA
- Stepper [−] [+] sur sessionNum
- PUSH direct depuis ce sheet (sans quitter HistoryTab)

---

## Mapping VIFA → image (VIFARegistry)

À construire — format JSON interne dans le bundle app :
```json
{
  "345": { "label": "Glycémie lignée paternelle", "image": "vifa_glycemie" },
  "12":  { "label": "Diabète T2 complications",  "image": "vifa_diabete_t2" },
  ...
}
```
Si VIFA absent du mapping → affiche uniquement le code numérique.

---

## Ce qui NE change PAS (décisions stables)

- `deleteReadKey()` et `doRelayRepeat()` → REVERTÉS (mauvaise approche)
- READ = marqueur de consommation, jamais écrasé ni effacé
- sessionNum = choix libre du praticien, pas auto-incrémenté
- Le datastore svlbh-v2 est la source de vérité historique permanente

---

## Roadmap

| Version | Feature |
|---|---|
| v4.3.0 | Sélecteur programCode + sessionNum manuel dans SyncBar |
| v0.5.x | HistoryTab complet (liste VIFA + vue sessions + lazy PULL + PUSH) |
| v0.6.x | VIFARegistry avec images (mapping interne) |

---

*Spec rédigée 24 mars 2026 — Patrick Bays / Digital Shaman Lab*
