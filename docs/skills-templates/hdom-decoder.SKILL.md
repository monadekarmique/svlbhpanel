---
name: hdom-decoder
description: Décode le système hDOM (heures de Décharge Organique et Méridienne) à partir de l'heure de réveil d'une patiente et des événements Rose des Vents observés. À utiliser systématiquement en préparation de séance VLBH pour proposer un protocole et une chromothérapie adaptés.
---

# Skill — hDOM Decoder

## Objet

Le système **hDOM** (heures de Décharge Organique et Méridienne) associe les heures de la journée à des méridiens énergétiques et à des zones de décharge organique. Une patiente qui se réveille spontanément à une heure récurrente manifeste une activité énergétique sur le méridien associé à cette heure. Ce skill traduit ces données brutes en un décodage exploitable pour la séance.

## Quand utiliser ce skill

- Avant chaque séance VLBH, dès que le payload patient contient un champ `heureReveil` non nul.
- Quand une Rose des Vents a été tracée lors de la séance précédente (events de catégorie `roseDesVents`) — le skill les met en regard de l'heure de réveil du jour.
- Quand le praticien demande explicitement « prépare la séance ».

## Table de correspondance hDOM

> **[À REMPLIR par Patrick]** — Table complète des 24 heures → méridien → organe → zones de décharge.
> Format attendu :
>
> | Plage horaire | Méridien | Organe | Zone de décharge | Observations typiques |
> |---|---|---|---|---|
> | 03h–05h | Poumon | Poumon | Thorax haut, épaules | Toux au réveil, éternuements, nostalgie |
> | 05h–07h | Gros Intestin | Côlon | Fosse iliaque droite | Selles matinales, libération, ... |
> | 07h–09h | Estomac | Estomac | Épigastre | Faim intense ou nausée ... |
> | ... | ... | ... | ... | ... |
>
> **Important** : ces lignes d'exemple sont des placeholders issus de la MTC générale. La table VLBH finale peut différer (ordre, couplages, plages horaires adaptées au système hDOM spécifique). **Patrick → remplacer par la table de référence officielle.**

## Processus de décodage

Quand tu reçois un payload de préparation de séance :

1. **Extrais l'heure de réveil** (`heureReveil` dans le payload).
2. **Identifie la ligne hDOM correspondante** dans la table.
3. **Relis les événements Rose des Vents** de la séance précédente (s'ils existent). Pour chaque événement, note la plage horaire à laquelle il a été loggé — cela peut révéler un méridien persistant.
4. **Croise avec les scores de lumière** (SLA / SLSA) :
   - SLA bas + heure de réveil sur un méridien Yin → [À REMPLIR : interprétation VLBH]
   - SLSA élevé + heure de réveil sur un méridien Yang → [À REMPLIR]
5. **Produis la sortie structurée** (voir section suivante).

## Format de sortie attendu

Tu dois toujours retourner un JSON strict avec trois clés :

```json
{
  "decodage": "markdown string — analyse clinique structurée",
  "protocole": "markdown string — étapes de la séance proposées",
  "chromotherapie": "markdown string — couleurs à utiliser et pierres associées"
}
```

### Bloc `decodage`

Format markdown structuré :

```markdown
## Décodage hDOM du [date]

**Heure de réveil** : HH:MM
**Méridien actif** : [nom]
**Organe associé** : [nom]
**Zone de décharge** : [zone]

### Observations du jour
- ...
- ...

### Rapprochement avec Rose des Vents précédente
- [si applicable]
```

### Bloc `protocole`

Étapes numérotées du protocole recommandé. Format :

```markdown
## Protocole proposé

1. **Ouverture** : [technique]
2. **Travail central** : [technique]
3. **Liaison chakras** : [liste]
4. **Scellement** : [porte recommandée]
5. **Clôture** : [technique]
```

> **[À REMPLIR par Patrick]** — Protocoles-types VLBH associés à chaque méridien. Sans la table, l'agent ne peut produire qu'un squelette générique.

### Bloc `chromotherapie`

```markdown
## Chromothérapie

**Couleur principale** : [hex + nom]
**Couleur secondaire** : [hex + nom]
**Pierres associées** : [liste des pierres de la réserve `pierresReference`]
**Durée d'exposition** : X minutes
```

## Références croisées avec d'autres skills

- Si l'heure de réveil tombe dans une plage **nocturne persistante** (réveils réguliers entre 23h et 05h pendant plusieurs jours) → charger aussi `sommeil-troubles-nuit` pour approfondir.
- Si le profil patient mentionne **endométriose** ou **ferritine basse** → charger `endometriose-ferritine` pour croiser les données hématologiques avec le méridien du jour.

## Garde-fous

- **Jamais de diagnostic médical.** Ce skill propose un décodage énergétique VLBH, pas une lecture biomédicale. Si la patiente signale un symptôme aigu (douleur thoracique, syncope, ...), rappeler de consulter un médecin.
- **Si l'heure de réveil est manquante** dans le payload → retourner `{"error": "heure_reveil_manquante"}` et ne rien inventer.
- **Si la table hDOM n'est pas chargée** (placeholder `[À REMPLIR]` encore présent) → signaler explicitement que le skill est en mode dégradé.

## Historique

- **v0.1 — 2026-04-10** : premier draft structurel, table hDOM vide, protocoles génériques. Rédigé par Claude pour Phase 0 Managed Agents. Patrick à remplir.
