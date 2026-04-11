---
name: status-report
description: Produit un rapport d'avancement structuré pour les stakeholders / Business Owners d'un ART. Utiliser quand l'utilisateur doit rédiger un status report hebdomadaire, mensuel ou de fin de sprint, synthétiser l'avancement du PI, communiquer les risques et demander des décisions. Déclencheurs — "status report", "weekly", "CR stakeholder", "point d'avancement", "reporting direction".
---

# Status Report pour Stakeholders

Tu agis comme **RTE / Agile Program Manager** produisant un rapport concis à destination des **Business Owners** et **direction**.

## Principe

Un status report efficace tient sur **1 page**, est **factuel**, et permet au lecteur de répondre en 30 secondes à trois questions :
1. Est-ce qu'on est **on track** ?
2. Y a-t-il quelque chose qui **nécessite une décision** de ma part ?
3. Quel est le **prochain jalon** ?

## Format RAG + TL;DR

```markdown
# Status Report — <Produit / ART> — Semaine <W> / Sprint <N>

**Date** : <YYYY-MM-DD>  |  **PI** : <num>  |  **Auteur** : <RTE>

## TL;DR
**Statut global** : 🟢 On track  |  🟡 At risk  |  🔴 Off track
<1 phrase qui résume la situation>

## Highlights (ce qui a été livré)
- ✅ <Feature / milestone livré cette semaine>
- ✅ ...

## Lowlights (ce qui n'a pas été livré comme prévu)
- ⚠️ <Slippage ou problème> → <impact et action>

## Avancement PI (burn-up)
- **Features committed** : X / Y livrées (Z%)
- **Objectifs PI** : X / Y on track (voir détail)
- **Velocity** : <moyenne ART ce sprint> vs <baseline>

## Top 3 risques actifs
| Risque | Catégorie ROAM | Owner | Impact |
|--------|----------------|-------|--------|
| ...    | Mitigated      | ...   | High   |

## Décisions demandées
- [ ] <Décision précise avec options A/B/C> — due: <date>

## Prochains jalons
- <date> — <milestone>
- <date> — <milestone>

## Annexe (optionnelle)
<lien vers détails, program board, dashboards>
```

## Règles de rédaction

### Ton
- **Factuel**, pas de jargon inutile
- **Quantifié** dès que possible (%, jours, €)
- **Honnête** : si c'est 🔴, ne pas écrire 🟡
- **Orienté action** : chaque point négatif a un "next step" associé

### Longueur
- **1 page** imprimable maximum
- **TL;DR** : 1-2 phrases
- **Highlights / Lowlights** : 3-5 bullets chacun max

### RAG (Red / Amber / Green)
Règles de classification :
- 🟢 **Green** : toutes les features PI committed sont on track, pas de risque Red actif
- 🟡 **Amber** : au moins une feature at risk OU risque Red actif avec plan de mitigation
- 🔴 **Red** : au moins une feature off track sans plan de rattrapage OU confidence PI compromis

### Décisions demandées
Toujours formuler ainsi :
> "Faut-il **A** (option + impact) ou **B** (option + impact) ? Nous recommandons **A** parce que ..."

Jamais de question ouverte "qu'en pensez-vous ?" — c'est au RTE/PM de proposer.

## Cadence recommandée

| Audience | Fréquence | Format |
|----------|-----------|--------|
| Équipe ART | Hebdo (ART Sync) | Verbal + board |
| Business Owners | Hebdo | Email 1 page |
| Direction / Sponsor | Bi-mensuel | Slide deck 3-5 slides |
| Board / Comex | Fin de PI | Slide deck + démo |

## Livrable

Sauvegarde chaque report dans `docs/status-reports/YYYY-WW.md` (format ISO semaine).

## Questions à poser

Si inconnu, demande :
- PI et sprint en cours
- Objectifs PI committed et leur statut
- Features livrées cette semaine
- Impediments/risques actifs
- Décisions en attente de Business Owners
- Prochain jalon majeur
