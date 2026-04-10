---
name: endometriose-ferritine
description: Croise les données hormonales (endométriose, cycles menstruels) et hématologiques (ferritine, hémoglobine) avec le cadre VLBH. À charger quand le profil patiente mentionne endométriose, règles abondantes, fatigue chronique inexpliquée, ou valeurs de ferritine connues.
---

# Skill — Endométriose & Ferritine

## Objet

Ce skill accompagne l'analyse VLBH des patientes présentant :

- un diagnostic ou une suspicion d'**endométriose**,
- des **règles abondantes** (ménorragies) ou douloureuses (dysménorrhées),
- une **ferritine basse** (< 30 ng/mL chez la femme, voire < 50 pour un seuil clinique fonctionnel),
- une **fatigue chronique** sans cause identifiée,
- des **symptômes cycliques** (aggravation prémenstruelle, douleurs d'ovulation).

Il s'articule avec `hdom-decoder` (lecture de l'heure de réveil sur un fond de fatigue ferriprive) et `sommeil-troubles-nuit` (sueurs nocturnes / réveils liés aux fluctuations hormonales).

## Quand utiliser ce skill

Charge ce skill dès que l'un des éléments suivants apparaît dans le payload patient ou la conversation :

- Mention explicite d'**endométriose** (diagnostiquée ou suspectée).
- Valeur de ferritine < 50 ng/mL communiquée par la patiente.
- Plainte de fatigue associée à un cycle menstruel douloureux ou abondant.
- Symptômes cycliques rapportés sur plusieurs séances.
- Tag de programme de recherche mentionnant « hormonal » ou « cycle ».

## Cadre clinique général

Ces éléments sont de **connaissance médicale standard** — ils servent de toile de fond. La lecture **VLBH** spécifique reste à définir par Patrick dans les sections marquées.

### Endométriose — rappels cliniques

- Présence de tissu endométrial en dehors de l'utérus (ovaires, péritoine, parfois plus loin).
- Symptômes : dysménorrhée sévère, douleurs pelviennes chroniques, dyspareunie, troubles digestifs cycliques, infertilité.
- Diagnostic : clinique + échographie pelvienne / IRM + parfois laparoscopie.
- Lien avec la ferritine : les règles abondantes liées à l'endométriose entraînent souvent une **anémie ferriprive** ou une **ferritine basse fonctionnelle**.

### Ferritine — seuils de référence

- **< 15 ng/mL** : carence martiale avérée, souvent associée à une anémie.
- **15–30 ng/mL** : déplétion des réserves sans anémie franche (symptômes déjà fréquents : fatigue, chute de cheveux, jambes sans repos).
- **30–50 ng/mL** : « zone grise » clinique. Beaucoup de cliniciens considèrent que < 50 chez une femme en âge de procréer justifie une supplémentation.
- **> 100 ng/mL** en contexte inflammatoire → attention, la ferritine est une protéine de phase aiguë, elle monte avec l'inflammation et peut masquer une carence.

### Impact sur l'état général

- Fatigue diurne, coup de barre d'après-midi.
- Difficulté de concentration, « brain fog ».
- Chute de cheveux, ongles cassants.
- Jambes sans repos en soirée.
- Réveils nocturnes vers 03h–05h (à croiser avec `sommeil-troubles-nuit`).
- Sensation de froid permanent.

## Lecture VLBH

> **[À REMPLIR par Patrick]** — Correspondances entre :
>
> - endométriose et système méridien / chakras (quel chakra est systématiquement impliqué ? quelle(s) porte(s) énergétique(s) ?)
> - ferritine basse et scores de lumière (corrélation observée SLA / SLSA ? quel pattern de Rose des Vents ?)
> - cycle menstruel et hDOM (certaines plages horaires sont-elles plus sensibles en phase lutéale ?)
>
> Ces correspondances sont au cœur du skill — sans elles, l'agent ne peut produire qu'un résumé clinique générique sans valeur VLBH ajoutée.

## Processus d'analyse

Quand tu es invoqué en complément de `hdom-decoder` :

1. **Vérifie les données disponibles** :
   - Le profil mentionne-t-il l'endométriose ?
   - Une valeur de ferritine récente est-elle connue ?
   - Phase du cycle actuelle (si communiquée) ?
2. **Si données manquantes → pose les questions** avant de produire une analyse. Ne jamais inventer une ferritine ou une phase de cycle.
3. **Croise avec `hdom-decoder`** : l'heure de réveil tombe-t-elle dans une plage connue pour être sensible en contexte ferriprive ? (typiquement 03h–05h).
4. **Enrichis les blocs `decodage` et `protocole`** du JSON principal avec une sous-section **« Contexte hormonal / hématologique »**.
5. **Propose une adaptation du protocole** si pertinente (exemples : travailler le chakra racine en phase lutéale, adapter la chromothérapie aux couleurs « soutien-ferritine » [À REMPLIR]).

## Format de sortie

Exemple de sous-section ajoutée au JSON principal :

```markdown
### Contexte hormonal / hématologique (skill endometriose-ferritine)

- Endométriose : [oui/non/suspectée]
- Ferritine connue : [valeur ng/mL | inconnue]
- Phase du cycle : [folliculaire / ovulatoire / lutéale / règles / inconnue]
- Lecture VLBH : [À REMPLIR]
- Adaptation protocole : [étape additionnelle ou ajustement de chromothérapie]
```

## Questions à poser au praticien si le payload est incomplet

- « La patiente a-t-elle une ferritine récente (< 6 mois) ? Quelle valeur ? »
- « Est-elle en phase lutéale, prémenstruelle, ou en règles aujourd'hui ? »
- « Les douleurs pelviennes sont-elles cycliques ou permanentes ? »
- « Y a-t-il une supplémentation en fer en cours ? »

## Garde-fous

- **Jamais de prescription** de fer ou de complément. Même pas de posologie suggérée. C'est le médecin traitant qui prescrit, le praticien VLBH accompagne.
- **Jamais de diagnostic médical.** Si la patiente rapporte des symptômes compatibles avec une endométriose non diagnostiquée, orienter vers un gynécologue.
- **Si la ferritine est < 15 ng/mL**, rappeler explicitement de consulter un médecin pour un bilan (NFS, bilan martial complet, recherche d'étiologie).
- **Grossesse** : si la patiente est enceinte ou en projet, l'adaptation VLBH est différente — le skill doit signaler le point et renvoyer vers un protocole « grossesse » spécifique (à créer ultérieurement).

## Historique

- **v0.1 — 2026-04-10** : draft initial avec cadre clinique général + sections VLBH à remplir. Rédigé par Claude pour Phase 0 Managed Agents.
