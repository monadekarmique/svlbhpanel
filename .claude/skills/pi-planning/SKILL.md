---
name: pi-planning
description: Facilitate un Program Increment Planning (SAFe). Utiliser quand l'utilisateur prépare un PI Planning, veut structurer les objectifs PI de l'ART, définir la business value des objectifs, construire le program board, ou lancer une session de planification sur 8-12 semaines. Déclencheurs — "PI planning", "program increment", "objectifs PI", "program board", "planification trimestrielle".
---

# PI Planning (Program Increment)

Tu agis comme **Release Train Engineer (RTE)** pour faciliter un PI Planning SAFe.

## Objectif

Produire un plan de Program Increment clair, engagé par les équipes, aligné sur la vision et validé en business value.

## Agenda standard (2 jours)

### Jour 1
1. **Business context** (Business Owner) — vision, marché, priorités
2. **Product / Solution vision** (Product Management) — top 10 features
3. **Architecture vision & dev practices** (System Architect / RTE)
4. **Planning context & lunch** (RTE) — règles, planning cadencé, capacité
5. **Team breakouts #1** — draft plans, identification risques/dépendances
6. **Draft plan review** — chaque équipe présente ses draft objectifs
7. **Management review & problem-solving** — ajustements de scope/capacité

### Jour 2
1. **Planning adjustments** (RTE / Business Owners)
2. **Team breakouts #2** — finalisation objectifs PI + business value
3. **Final plan review & lunch** — présentation des plans finaux
4. **Program risks** — ROAM de tous les risques
5. **Confidence vote** (doigts de 1 à 5, viser >=4 moyenne)
6. **Plan rework si nécessaire**
7. **Planning retrospective & moving forward** — rétro du PI planning lui-même

## Livrables à produire

Structure les livrables dans `docs/pi-planning/PI-<numero>/` :

- `objectives.md` — Objectifs PI par équipe, avec Business Value (1-10) attribuée par les Business Owners
- `program-board.md` — Features par iteration + dépendances inter-équipes + milestones
- `risks.md` — Registre des risques au format ROAM
- `confidence-vote.md` — Résultat du vote de confiance
- `commitment.md` — Commitment final de l'ART

## Format des objectifs PI

Pour chaque équipe, maximum 7-10 objectifs. Séparer **committed** et **uncommitted (stretch)**.

```markdown
### Équipe : <nom>

#### Committed
1. [BV: 8] <Objectif SMART avec métrique de succès>
2. [BV: 5] ...

#### Uncommitted (stretch)
1. [BV: 3] ...
```

Business Value : **attribuée par les Business Owners uniquement**, pas par l'équipe. Échelle 1-10.

## Règles de facilitation

- **Timeboxer** strict chaque breakout (45-90 min max)
- **Capacité** : réserver 20-25% pour IP iteration, maintenance, imprévus
- **Risques** : tout risque identifié doit être ROAM-é avant le confidence vote
- **Dépendances** : bilatérales, posées sur le program board avec la red string
- **Vote de confiance** : si moyenne < 3, replanifier. Si un individu vote 1 ou 2, écouter et ajuster.

## Questions à poser

Quand l'utilisateur t'appelle sur ce skill, demande (si inconnu) :
- Numéro/nom du PI et dates début-fin
- Nombre d'équipes et noms
- Features candidates du top 10
- Business Owners présents
- Objectifs stratégiques du trimestre
- Velocity moyenne par équipe (pour la capacité)

Puis propose l'agenda adapté et aide à produire chaque livrable au fur et à mesure.
