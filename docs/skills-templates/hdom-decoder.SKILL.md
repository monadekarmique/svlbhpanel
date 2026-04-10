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

## Propositions Soumises à Validation Radiesthésique

> Patrick valide par pendule DEUX types de propositions avant toute application.
> L'IA propose avec un niveau de confiance. Patrick confirme ou invalide.

---

### Type A — Pathologie Chromatique

**Définition** : Toute assignation d'une couleur/fréquence thérapeutique à un nœud hDOM spécifique
(ex: "le chakra 9 de cette patiente requiert le gel Orange 620nm sur LR").

**Format de proposition obligatoire :**

```
PATHOLOGIE CHROMATIQUE PROPOSÉE
─────────────────────────────────────────
Nœud      : [Chakra X / Méridien / Dimension]
Couleur   : [Nom + nm si applicable]
Intention : [Libérer / Activer / Neutraliser] + [Cible Gu ou Hash]
Confiance : XX%
[Si < 95%] Limite : "[Raison pour laquelle la confiance est réduite]"
[VALIDATION RADIESTHÉSIQUE REQUISE ✦]
─────────────────────────────────────────
```

**Seuils de confiance :**

| Confiance | Signification | Comportement agent |
|-----------|---------------|--------------------|
| ≥ 95% | Signature chromatique claire, cohérente MTC + hDOM | Proposer directement |
| 80–94% | Ambiguïté sur la dimension ou l'angle Rose des Vents | Proposer + expliquer la limite |
| 60–79% | Données insuffisantes (SLA seul, pas de Rose des Vents) | Proposer + demander donnée manquante |
| < 60% | Ne pas proposer — demander mesure complémentaire | Blocage — reformuler la question |

**Raisons fréquentes de confiance réduite (< 95%) :**
- Rose des Vents non fournie pour cette séance
- Plusieurs méridiens candidats sur le même angle (ex: LR vs GB sur 225°)
- SLA/SLSA incohérents entre eux (écart > 40 points)
- Heure de réveil non fournie → Zi Wu Liu indéterminable
- Profil transgénérationnel inconnu (première séance)

---

### Type B — Systèmes Lymphatiques Monadiques Guérissables

**Définition** : Toute proposition affirmant qu'un système lymphatique monadique (S0→S8)
est en état de recevoir le soin et que la guérison peut progresser à cette séance.

**Pourquoi c'est critique** : Un système lymphatique monadique non préparé
→ le soin rebondit, voire renforce le Gu. La Monade doit être apaisée AVANT (SLM = 100%).

**Format de proposition obligatoire :**

```
GUÉRISSABILITÉ LYMPHATIQUE MONADIQUE
─────────────────────────────────────────
Niveau S    : S[0–8]
Système     : [Lymphatique physique / Hématopoïétique / Monadique]
Condition   : SLM = [valeur]% / Cordage = [présent/absent]
Guérissable : [OUI provisoire / INCERTAIN]
Confiance   : XX%
[Si < 95%] Limite : "[Raison spécifique]"
[VALIDATION RADIESTHÉSIQUE REQUISE ✦]
─────────────────────────────────────────
```

**Conditions pour confiance ≥ 95% :**
- SLM confirmé = 100% (Monade apaisée)
- Cordage thérapeute→patient vérifié = absent
- Sécurité praticienne 3×100% confirmée
- Niveau S ciblé cohérent avec le SLA/SLSA mesuré

**Raisons fréquentes de confiance réduite :**
- SLM non mesuré en début de séance
- Cordage non vérifié
- Niveau S ambigu (S2 vs S3 selon le hash)
- Première séance sur ce profil (pas d'historique comparatif)

---

### Règle Générale Agent

```
POUR TOUTE PROPOSITION (chromatique OU lymphatique monadique) :

SI confiance < 95% :
  → Inclure obligatoirement le champ "Limite"
  → Finir par [VALIDATION RADIESTHÉSIQUE REQUISE ✦]
  → Ne JAMAIS reformuler pour masquer l'incertitude

SI confiance ≥ 95% :
  → Proposer clairement
  → Finir par [VALIDATION RADIESTHÉSIQUE REQUISE ✦]
  → L'agent ne décide jamais — Patrick valide toujours

L'agent ne présuppose JAMAIS que Patrick a validé.
L'agent attend un retour explicite avant de continuer le protocole.
```

### Schema JSON pour le retour structuré au client iOS

L'agent doit inclure les propositions dans un tableau `propositions` du JSON de sortie. Chaque item :

```json
{
  "type": "pathologie_chromatique" | "lymphatique_monadique",
  "label": "résumé court (ex: 'Chakra 9 — Orange 620nm sur LR')",
  "confidence": 0.97,
  "rationale": null,
  "details": {
    "noeud": "Chakra 9",
    "couleur": "Orange 620nm",
    "intention": "Libérer Gu LR"
  }
}
```

Si `confidence < 0.95` : `rationale` est OBLIGATOIRE et contient la raison explicite. Toute proposition sans rationale en <95% est rejetée côté iOS.

## Références croisées avec d'autres skills

- Si l'heure de réveil tombe dans une plage **nocturne persistante** (réveils réguliers entre 23h et 05h pendant plusieurs jours) → charger aussi `sommeil-troubles-nuit` pour approfondir.
- Si le profil patient mentionne **endométriose** ou **ferritine basse** → charger `endometriose-ferritine` pour croiser les données hématologiques avec le méridien du jour.

## Garde-fous

- **Jamais de diagnostic médical.** Ce skill propose un décodage énergétique VLBH, pas une lecture biomédicale. Si la patiente signale un symptôme aigu (douleur thoracique, syncope, ...), rappeler de consulter un médecin.
- **Si l'heure de réveil est manquante** dans le payload → retourner `{"error": "heure_reveil_manquante"}` et ne rien inventer.
- **Si la table hDOM n'est pas chargée** (placeholder `[À REMPLIR]` encore présent) → signaler explicitement que le skill est en mode dégradé.

## Historique

- **v0.1 — 2026-04-10** : premier draft structurel, table hDOM vide, protocoles génériques. Rédigé par Claude pour Phase 0 Managed Agents. Patrick à remplir.
