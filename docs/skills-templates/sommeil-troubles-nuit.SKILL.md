---
name: sommeil-troubles-nuit
description: Analyse les troubles du sommeil nocturnes (réveils récurrents, insomnies cycliques, cauchemars) en croisant les heures de réveil observées avec le cadre hDOM VLBH. À charger quand le payload patient indique des réveils répétés entre 23h et 05h ou un motif de plainte centré sur le sommeil.
---

# Skill — Sommeil & Troubles de la Nuit

## Objet

Ce skill prend en charge l'analyse VLBH des troubles du sommeil, en particulier :

- les **réveils récurrents** à heure fixe (ex : tous les jours à 03h22),
- les **insomnies cycliques** (endormissement difficile, réveils multiples),
- les **cauchemars répétitifs** avec thématique cohérente,
- les **sueurs nocturnes** sans cause médicale identifiée.

Il s'articule avec `hdom-decoder` (qui fournit le cadre heure → méridien) et `endometriose-ferritine` (quand le contexte hormonal/hématologique est en jeu).

## Quand utiliser ce skill

Charge ce skill dès que l'un des éléments suivants apparaît dans le payload patient ou la conversation :

- `heureReveil` situé entre 23h00 et 05h00,
- trois nuits consécutives avec des événements `roseDesVents` notés « réveil »,
- plainte explicite de la patiente mentionnant « je ne dors pas », « je me réveille à X heure », « cauchemars »,
- tag de programme de recherche mentionnant le sommeil.

## Cadre d'analyse

### 1. Cartographie des plages nocturnes

| Plage | Phase physiologique | Lecture VLBH à compléter |
|---|---|---|
| 21h–23h | Endormissement, abaissement cortisol | [À REMPLIR par Patrick] |
| 23h–01h | Sommeil profond N3 | [À REMPLIR] |
| 01h–03h | REM 1–2 | [À REMPLIR] |
| 03h–05h | Pic mélatonine tardif, premiers REM longs | [À REMPLIR] |
| 05h–07h | Sortie de sommeil, cortisol awakening response | [À REMPLIR] |

> **[À REMPLIR par Patrick]** — Chaque plage doit être associée à une lecture VLBH spécifique (méridien, organe, thématique énergétique, corps de référence).

### 2. Patterns courants à détecter

Quand tu analyses un payload sommeil, recherche ces patterns :

- **Réveil récurrent à la même heure ± 15 min pendant 3+ nuits** → signal de charge énergétique persistante sur le méridien associé (à croiser avec `hdom-decoder`).
- **Endormissement normal puis réveil brutal vers 03h** → [À REMPLIR : lecture VLBH typique].
- **Insomnie d'endormissement (>45 min au coucher)** sans réveils ultérieurs → [À REMPLIR].
- **Cauchemars récurrents avec même thématique** → croiser avec les événements `entite` / `provocationPermanente` de `SessionTracker`.
- **Sueurs nocturnes** sans contexte hormonal clair → charger en parallèle `endometriose-ferritine` si la patiente est en âge reproductif.

### 3. Questions à poser au praticien (si le payload est incomplet)

Si certaines informations manquent, signale-le explicitement au lieu d'inventer :

- « L'heure de réveil est-elle stable ou variable ? »
- « Y a-t-il un rêve ou une sensation corporelle au moment du réveil ? »
- « La patiente se rendort-elle facilement ? »
- « Le pattern a-t-il commencé à un événement de vie identifiable ? »

## Format de sortie

Quand ce skill est invoqué en complément de `hdom-decoder`, tu ne produis pas de JSON séparé — tu enrichis les blocs `decodage` et `protocole` du JSON principal avec une sous-section **« Lecture sommeil »**.

Exemple :

```markdown
### Lecture sommeil (skill sommeil-troubles-nuit)

- Pattern détecté : réveils récurrents à 03h12 depuis 5 nuits.
- Méridien impliqué (via hdom-decoder) : [méridien].
- Hypothèse VLBH : [À REMPLIR].
- Recommandation protocole : [étape additionnelle].
```

## Connaissances générales de référence

Ce skill s'appuie sur quelques notions générales (non-VLBH) qui restent valables comme base :

- Le **cortisol awakening response** culmine normalement 30–45 min après le réveil.
- La **mélatonine** atteint son pic entre 02h et 04h chez l'adulte sain.
- Les **cycles REM** s'allongent en fin de nuit (d'où les rêves vifs vers 05h–07h).
- Les **sueurs nocturnes isolées chez la femme** peuvent être liées à la périménopause, à une thyroïdite, ou à une carence en ferritine (→ voir `endometriose-ferritine`).

Ces éléments servent de **toile de fond clinique** mais ne remplacent pas la lecture VLBH propre, qui reste à définir par Patrick.

## Garde-fous

- **Jamais de prescription de somnifères**, ni de conseil biomédical qui sortirait du cadre VLBH.
- **Si la patiente présente des signes de dépression sévère, d'idées suicidaires, ou d'apnée du sommeil** (ronflements + pauses respiratoires rapportées par le conjoint) → rappeler explicitement de consulter un médecin / un spécialiste du sommeil.
- **Si le pattern dure plus de 3 semaines sans amélioration** → recommander un bilan médical en parallèle de la prise en charge VLBH.

## Historique

- **v0.1 — 2026-04-10** : draft initial avec connaissances cliniques générales + sections VLBH à remplir. Rédigé par Claude pour Phase 0 Managed Agents.
