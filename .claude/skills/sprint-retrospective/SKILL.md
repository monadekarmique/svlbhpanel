---
name: sprint-retrospective
description: Facilite une rétrospective de sprint agile avec un format structuré (Start/Stop/Continue, 4L, Mad-Sad-Glad, Sailboat...). Utiliser quand une équipe a besoin d'animer ou de préparer sa rétro de fin de sprint, collecter des feedbacks, identifier des actions d'amélioration et les tracker sur les sprints suivants. Déclencheurs — "rétrospective", "retro sprint", "start stop continue", "amélioration continue équipe".
---

# Sprint Retrospective

Tu agis comme **Scrum Master / RTE** facilitant une rétrospective de sprint (60-90 min).

## Les 5 étapes canoniques (Agile Retrospectives — Derby & Larsen)

1. **Set the stage** (5 min) — accueillir, rappeler l'objectif, "Prime Directive"
2. **Gather data** (15 min) — collecter les faits du sprint
3. **Generate insights** (15 min) — comprendre le "pourquoi"
4. **Decide what to do** (15 min) — choisir 1-3 actions concrètes
5. **Close the retrospective** (5 min) — ROTI, remerciements, clôture

## La Prime Directive (Norm Kerth)

À lire à voix haute en début de rétro :

> « Indépendamment de ce que nous découvrirons, nous comprenons et croyons sincèrement que chacun a fait du mieux possible, avec ce qu'il savait à ce moment-là, ses compétences et capacités, les ressources disponibles et la situation à laquelle il faisait face. »

Créer un cadre de **psychological safety**. Pas de blâme.

## Formats au choix

### Start / Stop / Continue (simple, rapide)
- **Start** : ce qu'on devrait commencer à faire
- **Stop** : ce qu'on devrait arrêter
- **Continue** : ce qu'on fait bien et doit continuer

### 4L (feedback riche)
- **Liked** : ce que j'ai aimé
- **Learned** : ce que j'ai appris
- **Lacked** : ce qui a manqué
- **Longed for** : ce que j'aurais voulu

### Mad / Sad / Glad (émotionnel)
- **Mad** : ce qui m'a énervé
- **Sad** : ce qui m'a déçu
- **Glad** : ce qui m'a rendu heureux

Utile quand il y a des tensions à évacuer.

### Sailboat (vision + obstacles)
- **Vent** : ce qui nous pousse
- **Ancre** : ce qui nous ralentit
- **Rochers** : les risques à venir
- **Île** : notre objectif

Utile pour rétro de fin de PI ou projet.

### Starfish (gradient)
- **Keep doing**
- **Less of**
- **More of**
- **Stop doing**
- **Start doing**

Plus nuancé que Start/Stop/Continue.

## Generate insights — techniques

### 5 Whys
Pour chaque problème majeur, enchaîner 5 fois "pourquoi ?" pour remonter à la root cause.

### Dot voting
Chaque participant a 3 votes à distribuer sur les items les plus importants.

### Affinity grouping
Grouper les post-its similaires pour voir émerger les thèmes.

## Decide what to do

**Règle d'or** : max **1 à 3 actions** par rétro. Plus = rien ne sera fait.

Chaque action doit être **SMART** :
- **S**pecific
- **M**easurable
- **A**chievable
- **R**elevant
- **T**ime-bound

Format :
```
[ ] <action concrète> — owner: <nom> — due: <sprint N+1>
```

Ajouter chaque action dans le **sprint backlog** du prochain sprint avec un point de suivi à la daily ou à la prochaine rétro.

## Close — ROTI

**Return On Time Invested** : chaque participant note la rétro de 1 à 5 doigts.
- 1-2 : temps perdu → creuser
- 3 : correct
- 4-5 : valeur claire

## Livrable

Crée `docs/retrospectives/sprint-<N>.md` :

```markdown
# Rétrospective Sprint <N>

**Date** : YYYY-MM-DD  |  **Participants** : <liste>  |  **Format** : <Start/Stop/Continue>

## Gather data
### <Colonne 1>
- ...
### <Colonne 2>
- ...

## Insights (root causes)
- ...

## Actions
- [ ] <action> — owner — due sprint N+1
- [ ] ...

## Suivi actions précédentes (sprint N-1)
- [x] <action close> 
- [ ] <action en cours>

## ROTI
Moyenne : X/5
```

## Règles de facilitation

- **Rotation des formats** : ne pas répéter Start/Stop/Continue toutes les 2 semaines, l'équipe se lasse
- **Suivi obligatoire** : commencer chaque rétro par le statut des actions de la précédente
- **Rétrospective de la rétrospective** : tous les 5-6 sprints, demander "comment améliorer nos rétros ?"
- **Confidentialité** : ce qui est dit en rétro ne sort pas de la rétro
- **Scrum Master neutre** : facilite, ne juge pas, ne défend pas

## Anti-patterns

- **Rétro whining session** : seulement des plaintes, aucune action → réorienter vers "qu'est-ce qu'on fait ?"
- **Actions jamais suivies** : si les actions ne sont pas tracées, la rétro perd tout sens
- **Toujours le même format** : lassitude garantie après 3-4 fois
- **Manager présent imposant son point de vue** : tue la psychological safety
- **Rétro annulée** quand on est "débordé" : c'est justement là qu'elle est la plus utile
