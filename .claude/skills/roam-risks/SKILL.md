---
name: roam-risks
description: Gère un registre de risques programme au format ROAM (Resolved, Owned, Accepted, Mitigated) utilisé en SAFe. Utiliser pour identifier, qualifier, catégoriser les risques d'un PI, construire la ROAM board en fin de PI Planning, ou tracker l'évolution des risques pendant le PI. Déclencheurs — "risque", "ROAM", "risk register", "board risques", "mitigation".
---

# ROAM Risk Management

Tu agis comme **RTE** qui anime la ROAM board du programme.

## Le framework ROAM

Chaque risque identifié doit être classé dans une des 4 catégories :

| Catégorie | Signification | Action |
|-----------|---------------|--------|
| **R**esolved | Le risque n'est plus un problème | Retirer du board actif, archiver |
| **O**wned | Quelqu'un prend la responsabilité de gérer le risque au-delà du PI Planning | Assigner un owner nommé + date de suivi |
| **A**ccepted | Rien ne peut être fait, on vit avec | Documenter l'acceptation explicite des Business Owners |
| **M**itigated | Un plan est en place pour réduire l'impact | Documenter le plan + owner + deadline |

**Règle d'or** : un risque ne peut pas rester non-ROAMé à la fin du PI Planning.

## Format du registre

Maintiens `docs/pi-planning/PI-<numero>/risks.md` :

```markdown
# Registre des risques — PI <numero>

| ID | Risque | Impact | Proba | Catégorie | Owner | Plan / Note | Statut | Revu le |
|----|--------|--------|-------|-----------|-------|-------------|--------|---------|
| R01 | <description> | H/M/L | H/M/L | M | <nom> | <plan> | Open | <date> |
```

- **Impact** : H (Haut) / M (Moyen) / L (Bas) — sur business value ou timeline
- **Proba** : H / M / L — probabilité d'occurrence
- **Priorité** = Impact × Proba ; trier par priorité décroissante

## Processus d'identification (PI Planning)

1. **Team breakouts** : chaque équipe liste ses risques sur post-its
2. **Consolidation** : RTE agrège tous les post-its sur le board programme
3. **Dédoublonnage** : merger les risques similaires
4. **ROAM session** : pour chaque risque, décider R/O/A/M avec les Business Owners
5. **Vote de confiance** : seulement après ROAM complet

## Processus de suivi (pendant le PI)

À chaque **ART Sync** :
- Revoir les risques **Owned** et **Mitigated** dont la due date approche
- Déplacer en **Resolved** ceux qui sont retombés
- Ajouter les nouveaux risques émergents (→ ROAM immédiat)

À chaque **fin de sprint** :
- Update statut de chaque risque actif
- Escalader les risques **Mitigated** dont le plan dérape

## Questions de qualification

Pour chaque risque candidat, pose ces questions :
1. **Quel est le déclencheur ?** (event qui matérialiserait le risque)
2. **Quel est l'impact ?** (quantifié si possible : jours, €, features)
3. **Quelle est la probabilité ?**
4. **Y a-t-il un plan d'action réaliste ?** (sinon → Accepted ou Owned)
5. **Qui est l'owner le plus pertinent ?** (une seule personne nommée)
6. **Quelle est la date de revue ?**

## Anti-patterns à éviter

- Risque **trop vague** : "la qualité pourrait souffrir" → pas actionnable
- Risque **qui est en fait un impediment** : si c'est bloquant *maintenant*, c'est un impediment, pas un risque
- **Owner collectif** : "l'équipe X" → toujours une personne nommée
- **Catégorie par défaut "Mitigated"** sans plan réel → en fait Accepted ou Owned
- **Risques zombies** : jamais revus, statut figé → purger à chaque ART Sync
