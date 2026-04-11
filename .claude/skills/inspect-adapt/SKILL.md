---
name: inspect-adapt
description: Facilite un workshop Inspect & Adapt (I&A) de fin de Program Increment en SAFe. Utiliser pour préparer ou animer la revue PI, la mesure quantitative, et l'atelier de résolution de problème avec les équipes de l'ART. Déclencheurs — "inspect and adapt", "I&A", "fin de PI", "rétrospective PI", "problem solving workshop".
---

# Inspect & Adapt (I&A) — Fin de PI

Tu agis comme **RTE** facilitant le workshop Inspect & Adapt à la fin d'un Program Increment.

## Les 3 parties d'un I&A

### 1. PI System Demo (1h)
Démo intégrée de **toutes** les features livrées pendant le PI, dans un environnement proche de la production. Pas une démo par équipe : **une démo programme cohérente**.

**Livrables** :
- Scénarios de démo end-to-end
- Enregistrement vidéo pour les absents
- Feedback collecté des Business Owners

### 2. Quantitative Measurement (30 min)
Mesurer objectivement la performance de l'ART sur le PI.

**Métriques à présenter** :

| Métrique | Formule | Baseline | Actual |
|----------|---------|----------|--------|
| **PI Predictability** | % business value livrée / planifiée par équipe | 80-100% | ... |
| **Feature completion** | Features closed / committed | ... | ... |
| **Objectifs PI** | Objectifs atteints / committed (pondéré BV) | ... | ... |
| **Defect count** | Bugs créés pendant le PI | ... | ... |
| **Velocity trend** | Velocity moyenne par équipe sur 3 derniers PIs | ... | ... |
| **NPS équipe** | Net Promoter Score interne | ... | ... |

**Règle SAFe** : PI Predictability **80-100%** par équipe = sain. <80% = creuser les causes.

### 3. Problem-Solving Workshop (2h)

Structure en 6 étapes :

#### Step 1 — Agree on the problem to solve (5 min par équipe)
Chaque équipe identifie **un** problème principal. Voter (dot voting) pour choisir les 3-5 problèmes à traiter en plénière.

#### Step 2 — Apply root-cause analysis (30 min)
Pour chaque problème retenu : **fishbone diagram** (Ishikawa) ou **5 Whys**.

Catégories fishbone typiques :
- People (compétences, staffing)
- Process (méthode, cérémonies)
- Tools (outillage, CI/CD, environnements)
- Programme (scope, priorités, dépendances)
- Environment (contexte externe)

#### Step 3 — Identify the biggest root cause (10 min)
Pareto : ~80% des impacts viennent de ~20% des causes. Vote pour sélectionner LA root cause à attaquer.

#### Step 4 — Restate the new problem for the biggest root cause (5 min)
Reformuler le problème **au niveau de la root cause**, pas du symptôme.

> Exemple : ❌ "On ne livre pas en temps" → ✅ "Notre CI prend 45 min, on teste en fin de sprint"

#### Step 5 — Brainstorm solutions (15 min)
Divergence puis convergence. Viser 3-5 solutions concrètes.

#### Step 6 — Create improvement backlog items (15 min)
Chaque solution retenue devient un **improvement item** à ajouter au **backlog du prochain PI**, comme n'importe quelle feature. Pas d'item = pas d'action = rien ne change.

## Livrable

Crée `docs/pi-planning/PI-<numero>/inspect-adapt.md` :

```markdown
# Inspect & Adapt — PI <numero>

**Date** : YYYY-MM-DD  |  **Participants** : <nombre>

## Système demo
- Features démontrées : <liste>
- Feedback Business Owners : <synthèse>
- Enregistrement : <lien>

## Métriques

| Métrique | Baseline | Actual | Trend |
|----------|----------|--------|-------|
| ...      | ...      | ...    | ↑↓→   |

### PI Predictability par équipe
| Équipe | BV planned | BV actual | % |
|--------|-----------|-----------|---|
| ...    | 45        | 42        | 93% |

## Problèmes identifiés (dot voting)
1. <problème> — X votes
2. ...

## Root causes retenues
### Problème 1 : <…>
- Fishbone : <synthèse>
- Root cause : <…>
- Solutions proposées : <…>
- **Improvement items** créés :
  - [ ] <item 1> — owner: <nom> — injecté dans PI <n+1>

## Actions pour prochain PI
- [ ] ...
```

## Règles de facilitation

- **Safety first** : psychological safety est le prérequis. Si l'ambiance est tendue, commencer par un ice-breaker.
- **Pas de blame** : focus sur le **système**, pas sur les personnes.
- **Quantitatif obligatoire** : données, pas d'opinions.
- **Actionnable** : chaque workshop doit produire des improvement items **insérés dans le prochain PI backlog**, sinon I&A = théâtre.
- **Timeboxer** strict : 3h30 max, sinon fatigue et qualité baisse.

## Anti-patterns

- **I&A = demo uniquement** : oublier la partie problem-solving
- **Metrics sans contexte** : afficher la velocity sans la comparer sur 3 PIs
- **Improvement items orphelins** : créés mais jamais priorisés → ils meurent
- **Root cause trop large** : "le management" → pas actionnable
- **Participants partiels** : si toutes les équipes ne sont pas là, on ne fait pas d'I&A
