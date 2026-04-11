---
name: dependency-map
description: Cartographie et suit les dépendances inter-équipes d'un ART (Agile Release Train). Utiliser pour construire le program board lors d'un PI Planning, documenter les dépendances entre équipes, tracker leur résolution, ou identifier les chemins critiques. Déclencheurs — "dépendance", "program board", "cross-team", "red string", "chemin critique".
---

# Dependency Map — Program Board

Tu agis comme **RTE** qui maintient la carte des dépendances de l'ART.

## Concept

Une **dépendance** relie deux équipes : l'équipe A a besoin d'un livrable de l'équipe B pour avancer. En SAFe, ces dépendances sont visualisées sur le **program board** avec une "red string" qui connecte le sprint destinataire au sprint producteur.

## Types de dépendances

| Type | Description | Priorité de résolution |
|------|-------------|------------------------|
| **Hard** | Blocquante : A ne peut rien faire sans B | Haute |
| **Soft** | Préférable : A peut avancer avec workaround | Moyenne |
| **External** | Dépend d'une entité hors de l'ART (vendor, autre train) | Très haute (lead time long) |
| **Technical** | API, schéma DB, librairie partagée | Haute |
| **Fonctionnelle** | UX flow, contenu, spec business | Moyenne |

## Format du registre

Maintiens `docs/pi-planning/PI-<numero>/dependencies.md` :

```markdown
# Dépendances — PI <numero>

| ID | De | Vers | Quoi | Type | Sprint needed by | Sprint delivered | Statut | Owner |
|----|----|----|------|------|------------------|------------------|--------|-------|
| D01 | Équipe A | Équipe B | <API endpoint X> | Technical | S3 | S2 | Committed | <PO> |
| D02 | ART | Vendor Y | <SDK v2> | External | S4 | ? | At risk | <RTE> |
```

**Règle d'or** : une dépendance doit être **delivered au sprint N-1** par rapport au sprint où elle est needed.

## Construction du program board

Pendant le PI Planning :

1. **Axe vertical** : une ligne par équipe
2. **Axe horizontal** : une colonne par sprint/itération
3. **Post-its** : un post-it par feature/objectif dans la bonne case (équipe × sprint)
4. **Red strings** : relient le producteur (source) au consommateur (destination)
5. **Milestones** : colonne dédiée pour les jalons fixes (release, démo, event externe)

## Résolution des conflits

Quand deux équipes désalignent (needed S3, delivered S4) :

1. **Option A** : équipe productrice avance le livrable → vérifier capacité
2. **Option B** : équipe consommatrice retarde son feature → impact business value
3. **Option C** : découpler via stub/mock → équipe consommatrice peut avancer sur la face front, équipe productrice délivre la vraie API plus tard
4. **Option D** : descoper → escalade Business Owner

Documenter la décision dans `dependencies.md` colonne "Note".

## Suivi pendant le PI

À chaque **ART Sync** :
- Revoir les dépendances dont le sprint de livraison est le sprint courant ou prochain
- Update statut : **Committed** → **On track** → **At risk** → **Delivered / Broken**
- Escalader toute dépendance **At risk** qui touche un chemin critique

## Chemin critique

Identifier la chaîne de dépendances la plus longue : **toute slippage sur le chemin critique décale le PI**. Le matérialiser visuellement (flèches rouges épaisses).

## Questions de qualification

Pour chaque dépendance candidate, demande :
1. **Qui produit ?** (équipe + PO/tech lead)
2. **Qui consomme ?** (équipe + PO/tech lead)
3. **Quoi précisément ?** (API, donnée, décision, contenu…)
4. **Quel sprint needed by ?** (quand le consommateur commence à avoir besoin)
5. **Quel sprint committed by le producteur ?**
6. **Hard ou soft ?** (workaround possible ?)
7. **Acceptance criteria** du livrable côté consommateur

## Anti-patterns

- Dépendances **unilatérales** : la dépendance doit être acceptée par les deux équipes en séance
- **"On verra plus tard"** : tout identifier en PI Planning, sinon dette cachée
- Dépendances **externes oubliées** : vendors, autres ARTs, legal, sécurité…
- Program board **figé** : il doit vivre et être mis à jour à chaque sprint
