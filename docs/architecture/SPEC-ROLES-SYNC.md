# SVLBH Panel — Specification Systeme de Roles et Synchronisation
## v0.1 — 22 mars 2026

---

## PRINCIPE FONDAMENTAL

La shamane est la SEULE a connaitre l'identite de son patient.
Patrick (superviseur) ne voit qu'un numero anonyme (ex: 728, 14968).
La confidentialite est garantie a 100%.

---

## LES ACTEURS

### Superviseur (actuellement : Patrick seul — demain : d'autres)
- Peut superviser les shamanes (recevoir, valider, corriger, repousser)
- Peut s'auto-decoder (seul role a pouvoir etre son propre patient)
- Attribue les codes praticiens
- Decide d'accorder ou refuser l'acces aux leads
- Le code superviseur est dans la plage certifiee (300-30000)
- Patrick = premier superviseur, pas le dernier

### Patrick (superviseur)
- Role dans l'app : `.patrick` / code `01` (temporaire phase test)
- Ne connait PAS le patient des shamanes
- Decode, supervise, valide les scores
- S'auto-decode (auto-soin, accumulation multi-sessions)

## LES 3 TIERS DE CODES PRATICIEN

### Tier 1 — Leads (01 a 99)
- Personne qui teste l'app (seance decouverte)
- Code aleatoire attribue automatiquement
- ALERTE IMMEDIATE pour Patrick : identifier les pierres de protection
  pour absorber l'energie vortex lors de la connexion au lead
- Patrick decide s'il accorde l'acces ou non
- Pas d'echange bidirectionnel — Patrick observe et protege

### Tier 2 — Shamanes en formation (100 a 299)
- En cours de certification VLBH
- Grande probabilite d'heberger des fork galactiques
- Echange bidirectionnel avec Patrick (supervision renforcee)
- Ne peuvent PAS echanger entre elles

### Tier 3 — Shamanes certifiees VLBH (300 a 30000)
- Ont resolu leur fork galactique
- Echange bidirectionnel avec Patrick (supervision standard)
- PEUVENT echanger entre elles pour s'entraider
- Codes 4 chiffres attribues a la certification

### Tier 4 — Superviseurs (sous-ensemble des certifiees)
- Memes droits que Tier 3 + capacite d'auto-decodage
- Peuvent superviser d'autres shamanes
- Peuvent accorder/refuser l'acces aux leads
- Actuellement : Patrick seul. Demain : d'autres superviseurs certifies

### Shamanes actuelles (phase test)
| Nom | Code | Tier |
|-----|------|------|
| Cornelia | 25 | Lead (testeuse) |
| Anne | 26 | Lead (testeuse) |
| Flavia | 27 | Lead (testeuse) |

### Ce que la shamane definit pour chaque session
- Type : Patient (individuel) ou Systeme (constellation)
- Codes Sephiroth : desequilibres identifies selon l'Arbre des Sephiroth
- Nombre de seances : deja realisees sur cette personne (par elle ou d'autres)
  - Si inconnu : 999 → Patrick testera radiesthesiquement
- La shamane est la SEULE a connaitre l'identite du patient

---

## LES 3 MODES DE TRAVAIL DE PATRICK

### Mode 1 — Decoder pour une shamane (supervision)
1. La shamane fait son decodage (generations, pierres, chakras)
2. La shamane PUSH son travail → cle patientId-sessionNum-CODE_SHAMANE
3. Patrick recoit (PULL depuis la cle shamane)
4. Patrick revise, corrige, ajoute ses scores SLA/SLSA/SLM
5. Patrick PUSH sa version → cle patientId-sessionNum-01
6. La shamane PULL depuis la cle Patrick → suggestions bleues

### Mode 2 — Travailler pour soi (auto-soin)
1. Patrick est a la fois praticien ET patient
2. Il decode sur lui-meme, accumule les sessions
3. Pas de shamane impliquee
4. Push/Pull optionnel (backup Make.com)

### Mode 3 — Recevoir pour approbation
1. Patrick scanne les sources (toutes les shamanes)
2. Badge rouge = X shamanes ont envoye du travail
3. Patrick choisit quelle shamane recevoir
4. Il revise, valide ou corrige, puis repousse

---

## FLUX FALLBACK — SYSTEME TOMBE (WhatsApp/iMessage)

### Patrick exporte pour une shamane
Menu > Exporter > Copier > Coller dans WhatsApp/iMessage

### Patrick importe depuis une shamane
Shamane exporte en texte > WhatsApp/iMessage > Patrick copie > Importer > Fusionner

Format = SessionExporter.export() — meme format dans les deux sens.


---

## IMPLICATIONS POUR LE CODE

### Codes praticiens — refactoring necessaire
Le systeme actuel (PractitionerRole enum avec 4 cas fixes) doit devenir dynamique :

```
Code 01-99     → Tier .lead       → Badge rouge "LEAD" + alerte pierres
Code 100-299   → Tier .formation  → Badge orange "EN FORMATION"
Code 300-30000 → Tier .certifiee  → Badge vert "CERTIFIEE"
```

### Regles de sync par tier
| Tier | Push vers superviseur | Pull depuis superviseur | Echange pairs | Auto-decodage |
|------|----------------------|------------------------|---------------|---------------|
| Lead (01-99) | NON | NON | NON | NON |
| Formation (100-299) | OUI | OUI | NON | NON |
| Certifiee (300-30000) | OUI | OUI | OUI | NON |
| Superviseur (certifiee + flag) | OUI | OUI | OUI | OUI |

### Alerte Lead pour Patrick
Quand Patrick recoit une connexion d'un code 01-99 :
1. Alerte visuelle immediate (rouge)
2. Identifier pierres de protection (vortex)
3. Bouton "Accorder l'acces" / "Refuser"
4. Pas de PIN — Patrick decide manuellement

### Format cle de sync
`patientId-sessionNum-codePraticien`
- Lead : `14968-001-42` (code 2 chiffres)
- Formation : `14968-001-156` (code 3 chiffres)
- Certifiee : `14968-001-3847` (code 4 chiffres)

---

## PROGRAMMES DE RECHERCHE

### Principe
Le superviseur peut upgrader une shamane participante dans une version
recherche. La shamane devient co-chercheuse sur un programme documente.
Ses sessions nourrissent la base de donnees du programme.

### Programmes actuellement actifs

#### 1. Scleroses chromatiques transgeneration​nelles multiples
- Etude des blocages chromatiques herites sur plusieurs generations
- Signature hDOM : patterns repetitifs de teintes bloquees sur S0-S2
- Protocole : gradient intuitif de teintes vers #FFFFFF

#### 2. Accumulations masculines sur l'endometre
- Lien entre charges transgeneration​nelles masculines et endometriose
- Signature Rose des Vents : SO (225) et SSO (202.5)
- Protocole : 5 phases liberation (entites, relations toxiques,
  nettoyage NNO, assimilation fer, stockage ferritine)

#### 3. Glycemies I, II et III
- Trois niveaux de desequilibre glycemique lies aux charges karmiques
- Glycemie I : charge directe (patient zero)
- Glycemie II : charge transgeneration​nelle (lignee)
- Glycemie III : charge systemique (famille d'ames)

### Implications pour l'app
- Badge "RECHERCHE" sur les sessions participantes
- Tag programme sur chaque session (selectionnable)
- Les donnees de recherche sont exportables separement
- Le superviseur peut activer/desactiver le mode recherche par shamane
- Documentation automatique : chaque session taguee recherche
  produit une fiche structuree pour le programme

---

## BROADCAST D'URGENCE

### Principe
En cas d'evenement majeur (catastrophe naturelle, attentat, evenement
planetaire, pic de Schumann, eclipse...), Patrick peut broadcaster
un soin d'urgence a TOUTES les shamanes certifiees simultanement.

### Qui recoit
- UNIQUEMENT les shamanes certifiees (Tier 3 : codes 300-30000)
- PAS les leads (Tier 1)
- PAS les shamanes en formation (Tier 2) — elles n'ont pas resolu
  leur fork galactique, recevoir un soin d'urgence pourrait amplifier

### Contenu du broadcast
- Pierres de protection pre-selectionnees par Patrick
- Sequence de soin d'urgence (chakras prioritaires)
- Scores de reference pour calibration immediate
- Message texte optionnel (contexte de l'evenement)

### Flux technique
1. Patrick compose le soin d'urgence dans l'app
2. Bouton "BROADCAST URGENCE" (distinct du broadcast normal)
3. Push simultane vers TOUTES les cles certifiees
4. Notification prioritaire cote shamane (badge rouge + alerte)
5. La shamane peut appliquer le soin immediatement sur ses patients

### Difference avec le broadcast normal
| | Broadcast normal | Broadcast urgence |
|--|------------------|-------------------|
| Destinataires | Shamanes liees a la session | TOUTES les certifiees |
| Contexte | 1 patient specifique | Evenement global |
| Priorite | Normale | URGENTE (badge rouge) |
| Contenu | Decodage patient | Soin de protection collectif |

---

## SOIN MATINAL DES SHAMANES (auto-soin broadcast)

### Principe
Patrick decode au reveil le Corps de Lumiere (VLBH) des shamanes
desequilibrees. Il peut broadcaster aux shamanes certifiees le soin
et le protocole correspondant.

### Flux
1. Patrick decode au reveil les Corps de Lumiere des shamanes
2. Il identifie les desequilibres (scores, chakras, pierres)
3. Il compose le soin + protocole dans l'app
4. Il broadcaste aux shamanes certifiees (Tier 3)
5. Chaque shamane recoit le soin dans son app

### Choix de la shamane
- La shamane peut CONSERVER l'auto-soin (l'appliquer sur elle-meme)
- La shamane peut SUPPRIMER le soin (refuser / non pertinent)
- Ce choix est libre — pas d'obligation

### Redistribution aux patientes
- La shamane peut mettre le soin a disposition de ses patientes
- Sous forme de texte WhatsApp (export copier-coller)
- Ou sous forme de copies d'ecran de l'app
- La shamane reste garante de la confidentialite : elle choisit
  quoi transmettre et a qui
- Patrick ne sait pas a quelles patientes le soin est redistribue

### Historique broadcasts
Patrick / superviseur dispose d'un historique complet :
- Date et heure de chaque broadcast
- Contenu du soin (pierres, chakras, protocole)
- Liste des destinataires
- Statut par shamane : recu / conserve / supprime
- Permet de suivre l'evolution dans le temps

## FORMAT DE CLE COMPLET

### Structure
```
PP-patientId-sessionNum-codePraticien
```

### PP = Code programme (2 digits, prefixe)
| Code | Signification | Attribue dans |
|------|---------------|---------------|
| 00 | Non classifiee (defaut) | SVLBH Panel (auto) |
| 01 | Recherche | SVLBH Panel (Patrick) |
| 03 | Epidemie | App Admin (Patrick) |
| 05 | Gradients | App Admin (Patrick) |

### Exemples
| Cle complete | Lecture |
|--------------|--------|
| 00-14968-001-25 | Non classifiee, patient 14968, seance 1, Cornelia |
| 01-14968-003-25 | Recherche, patient 14968, seance 3, Cornelia |
| 03-728-001-3847 | Epidemie, patient 728, seance 1, shamane certifiee 3847 |
| 05-14968-002-01 | Gradients, patient 14968, seance 2, Patrick |

### Regles
- Toute nouvelle session demarre en 00 (non classifiee)
- Seul Patrick peut changer le code programme
- Le changement peut se faire en temps reel (pendant la session)
  ou a posteriori (apres la session, depuis la base Make.com)
- Le code programme est visible dans l'onglet Recherche
- La cle Make.com inclut le prefixe programme pour le routage

---

### Principe
Chaque session sync via Make.com constitue automatiquement une base
de cas decodes anonymises. Patrick peut a posteriori OU en temps reel
decider d'allouer un cas a un programme de recherche.

### Flux
1. Shamane push son decodage → Make.com Data Store
2. Patrick pull, revise, valide → Make.com Data Store
3. Le cas anonymise (patientId + donnees hDOM) est stocke dans Make.com
4. Patrick decide : "ce cas correspond au programme Glycemie II"
5. Le cas est tagge avec le programme de recherche
6. Le cas apparait dans l'onglet Recherche de la shamane concernee

### Donnees stockees par cas
- patientId (anonyme — jamais le nom)
- sessionNum
- Code shamane (qui a decode)
- Scores SLA/SLSA/SLM/TotSLM
- Generations decodees (abuseur/victime/phases/gu/meridiens)
- Pierres selectionnees
- Chakras nettoyes
- Tag programme de recherche (attribue par Patrick)
- Date de creation / derniere modification

---

## ONGLET RECHERCHE (nouveau)

### Principe
Nouvel onglet dans l'app, visible pour les shamanes participantes
ET pour Patrick. Affiche les patients de la shamane qui ont ete
attribues par Patrick a un programme de recherche.

### Vue shamane
- Voit UNIQUEMENT ses propres patients attribues a un programme
- Pour chaque patient : numero anonyme, programme, nombre de seances,
  derniers scores, statut (en cours / termine / en attente validation)
- Ne voit PAS les patients des autres shamanes

### Vue Patrick (superviseur)
- Voit TOUTES les occurrences de TOUS les programmes
- Peut filtrer par : programme, shamane, scores, date
- Vue transversale : combien de cas par programme, tendances,
  patterns communs entre cas du meme programme
- Peut ajouter/retirer un cas d'un programme
- Peut attribuer un cas retroactivement (apres la session)
  ou en temps reel (pendant la session)

### Programmes selectionnables
Liste des programmes actifs :
1. Scleroses chromatiques transgenerationnelles multiples
2. Accumulations masculines sur l'endometre
3. Glycemies I, II et III

Patrick peut creer de nouveaux programmes depuis l'onglet Recherche.

---

## LISTES DE DISTRIBUTION ET GROUPES

### Principe
Quand Patrick valide un cas (00 → 01) et renvoie le soin a la shamane,
il doit pouvoir envoyer en individuel OU en broadcast vers un groupe.
Il est donc necessaire de :
1. Lier automatiquement les shamanes qui ont un patient de recherche
   dans une liste de distribution par programme
2. Creer des groupes thematiques de shamanes qui ont en commun
   des patients d'un meme type de pathologie

### Listes de distribution automatiques (par programme)
- Chaque programme de recherche a sa liste de distribution
- Quand Patrick attribue un cas au programme Glycemie,
  la shamane est automatiquement ajoutee a la liste "Glycemie"
- Patrick peut broadcaster le soin a toute la liste d'un coup
- La liste se met a jour automatiquement (ajout/retrait de cas)

### Groupes thematiques (par pathologie)
- Patrick peut creer des groupes manuels par type de pathologie
  (ex: "Eczema", "Endometriose", "Sclerose", "Glycemie II")
- Un groupe rassemble les shamanes qui ont des patients
  presentant la meme pathologie
- Patrick peut broadcaster un soin ou un protocole a tout le groupe
- Une shamane peut etre dans plusieurs groupes

### Flux Use Case Anne (suite — Patrick renvoie)

**Envoi individuel (toujours avec SMS) :**
1. Patrick recoit 00-731-001-104 (Anne, glycemie, seance 1)
2. Patrick decode, revise, valide
3. Patrick renvoie a Anne → l'app envoie un SMS a Anne
4. Le SMS incremente automatiquement le numero de session
5. La cle devient 00-731-002-104 (seance 2)

**Attribution recherche (independant de l'increment) :**
6. Patrick decide que ce cas releve de la recherche Glycemie
7. Patrick change le code programme : 00 → 01
8. La cle de recherche est 01-731-001-104
   (c'est la seance 1 qui est attribuee, pas la seance 2)

**Les deux sont lies :**
| Cle | Signification |
|-----|---------------|
| 00-731-001-104 | Seance 1, non classifiee (recue d'Anne) |
| 01-731-001-104 | Patrick tagge seance 1 → Recherche Glycemie |
| 01-731-002-104 | Patrick renvoie le soin (SMS + increment) → Recherche conserve |
| 01-731-003-104 | Seance 3, Recherche conserve |

**Regles :**
- Le SMS d'envoi individuel incremente TOUJOURS la seance
- Le code programme est STICKY : une fois attribue (ex: 01), il reste
  sur toutes les seances suivantes du meme cas
- Le code ne retombe PAS en 00 apres increment
- Seul Patrick peut changer le code programme (ex: repasser en 00
  si le cas ne releve plus de la recherche)

**Envoi broadcast (liste de distribution) :**
- Patrick peut AUSSI broadcaster le soin a toute la liste "Glycemie"
  (toutes les shamanes ayant un patient glycemie le recoivent)
- Chaque shamane peut conserver ou supprimer le soin
- Chaque shamane peut redistribuer a ses patientes (WhatsApp/screenshot)
- Le broadcast ne genere PAS de SMS individuel
- Le broadcast n'incremente PAS le numero de session

---

## REPOSITORY PARTAGE (entre SVLBH Panel et App Admin)

### Principe
L'App Admin gere les listes de distribution, les groupes et les fiches
shamanes. SVLBH Panel consomme ces donnees en lecture.
Un repository partage (Make.com Data Store) sert d'interface entre les 2 apps.

### Donnees dans le repository
- Listes de distribution par programme (automatiques)
- Groupes thematiques par pathologie (manuels, crees par Patrick)
- Fiches shamanes (module Shamane minimum)
- Cas anonymises tagges par programme
- Historique broadcasts

### Direction des flux
| Donnee | App Admin | Repository | SVLBH Panel |
|--------|-----------|------------|-------------|
| Fiche shamane | ECRITURE | STOCKAGE | LECTURE |
| Listes de distribution | ECRITURE | STOCKAGE | LECTURE |
| Groupes thematiques | ECRITURE | STOCKAGE | LECTURE |
| Cas anonymises | LECTURE | STOCKAGE | ECRITURE |
| Code programme (00→01) | LECTURE | STOCKAGE | ECRITURE (Patrick) |
| Broadcasts | ECRITURE | STOCKAGE | LECTURE (shamanes) |

---

## MODULE SHAMANE MINIMUM

### Principe
Chaque shamane a une fiche minimum dans le repository.
Ces donnees sont extraites du CRM (a definir).

### Champs obligatoires
| Champ | Exemple | Source |
|-------|---------|--------|
| Code praticien | 104 | Genere a l'inscription |
| Tier | Formation (100-299) | Derive du code |
| Prenom | Anne | CRM |
| Nom | Grangier Brito | CRM |
| Numero WhatsApp | +41 79 xxx xx xx | CRM |
| Adresse email | anne.gr29@gmail.com | CRM |
| Type d'abonnement | Formation trimestrielle | CRM |
| Prochaine date de facturation | 22.06.2026 | CRM |

### Abo (abonnement)
- Definit le niveau d'acces et la duree
- Lie au tier : lead = decouverte, formation = trimestriel, certifiee = annuel
- La date de facturation determine la validite du code praticien
  (ex: Anne code 104, valable un trimestre)
- Code expire → acces bloque jusqu'au renouvellement

### CRM source (a definir)
- Le CRM est la source de verite pour les donnees shamanes
- Le repository synchronise depuis le CRM
- Candidats CRM : Google Sheets actuel (ID 143btyMq...), 
  ou evolution vers un CRM dedie
- L'App Admin peut lire/ecrire dans le CRM
- SVLBH Panel ne touche JAMAIS au CRM directement

---

## ARCHITECTURE 2 APPS

### App 1 — SVLBH Panel (app terrain)
- Utilisateurs : shamanes + Patrick (en mode supervision)
- Fonctions : decodage, scores, pierres, chakras, push/pull
- Le code programme est 00 (non classifie) par defaut
- PATRICK peut changer le code programme depuis cette app
  (ex: 00 → 01 Recherche) lors de la reception ou a posteriori
- Les shamanes ne peuvent PAS modifier le code programme
- C'est l'app qu'on construit aujourd'hui

### App 2 — App Admin/Recherche (a definir)
- Utilisateur : Patrick UNIQUEMENT
- Se connecte a la base Make.com des cas anonymises
- Fonctions SPECIFIQUES a l'admin (pas dans SVLBH Panel) :
  - Vue transversale de TOUS les cas, TOUS les programmes
  - Filtrer par programme, shamane, scores, date
  - Detecter les patterns communs entre cas
  - Creer de nouveaux programmes de recherche
  - Historique complet des broadcasts (normal, urgence, soin matinal)
  - Gerer les tiers praticiens (upgrade lead → formation → certifiee)
  - Statistiques et rapports de recherche

### Ce qui est dans SVLBH Panel vs App Admin
| Action | SVLBH Panel | App Admin |
|--------|-------------|-----------|
| Decoder un patient | OUI | NON |
| Push/Pull sync | OUI | NON |
| Attribuer code programme (Patrick) | OUI | NON (lecture) |
| Vue transversale tous cas | NON | OUI |
| Creer un programme | NON | OUI |
| Gerer tiers praticiens | NON | OUI |
| Historique broadcasts | NON | OUI |

### Mecanisme de transfert SVLBH Panel → App Admin
- Patrick attribue UNIQUEMENT le code 01 (Recherche) dans SVLBH Panel
- Le code 01 signifie : "ce cas releve de la recherche"
- Patrick ne choisit PAS le programme dans SVLBH Panel
- C'est dans l'App Admin que Patrick attribue le cas
  a un programme specifique (Glycemie, Endometriose, Scleroses...)
- Les codes 03 (Epidemie) et 05 (Gradients) sont attribues
  dans l'App Admin, JAMAIS dans SVLBH Panel

```
SVLBH Panel              App Admin Recherche

00-731-001-104           (pas visible)
  |
Patrick tagge 01
  |
01-731-001-104    →→→    Visible. Patrick attribue :
                         → Programme Glycemie
                         → ou Endometriose
                         → ou Scleroses
                         → ou nouveau programme
```

En resume :
- SVLBH Panel = porte d'entree (00 → 01)
- App Admin = classification dans le bon programme

### Flux entre les 2 apps
```
SVLBH Panel (terrain)          Make.com          App Admin (recherche)
     |                            |                      |
     |--- push (00-clé) -------->|                      |
     |                            |<---- lecture --------|
     |                            |<---- tag 01-clé ----|
     |<--- pull (01-clé) --------|                      |
     |                            |                      |
```

1. La shamane push depuis SVLBH Panel → cle 00-xxx (non classifie)
2. Patrick ouvre l'App Admin → voit le cas dans Make.com
3. Patrick decide : "ce cas = Glycemie" → change 00 → 05
4. La cle Make.com devient 05-xxx
5. La shamane voit le tag dans son onglet Recherche (SVLBH Panel)
   (lecture seule — elle ne peut pas changer le programme)

### Use Case 1 — Anne (formation) decode pour son fils, glycemie

**Contexte** : Anne code 104 (Tier 2 formation). Son fils est atteint
de glycemie. Elle ne sait pas que le programme de recherche existe.

**Flux Anne :**
1. Ouvre l'app → role Anne · code 104
2. Cree la session :
   - Type : Patient
   - Patient ID : 731 (numero anonyme qu'elle attribue)
   - Seances : 001 (premiere seance)
   - Codes Sephiroth : desequilibres identifies
3. Decode : generations, pierres, chakras, scores
4. Push → cle `00-731-001-104`
   (00 = non classifie, c'est le defaut, Anne ne touche pas)

**Flux Patrick (SVLBH Panel) :**
5. Recoit le cas 00-731-001-104
6. Revise, reconnait le pattern glycemie
7. Depuis SVLBH Panel, tagge le code programme : 00 → 01 (Recherche)
8. Cle devient `01-731-001-104`
9. Renvoie le soin a Anne (SMS + increment) → `01-731-002-104`

**Flux Patrick (App Admin — plus tard) :**
10. Ouvre l'App Admin, voit le cas 01-731-xxx-104
11. Attribue au programme specifique : Glycemie
12. Le cas est maintenant classe dans le programme Glycemie

**Anne decouvre** dans son onglet Recherche que son patient 731
est tague "Recherche". Elle ne sait pas encore quel programme.
C'est quand Patrick classifie dans l'App Admin (Glycemie) qu'Anne
verra le programme specifique.

**Anne revient plus tard :**
- Nouveau patient different → elle cree `00-xxx-001-104`
  (nouveau patientId, seance 001, code 00 par defaut)
- Meme patient glycemie → elle reprend `01-731-003-104`
  (le 01 est sticky, seance incrementee automatiquement)

**REGLE : il n'existe PAS de shamane multi-recherche.**
Une shamane n'a qu'UN seul programme de recherche a la fois.
Consequence : une seule liste de distribution par shamane,
pas de conflit de routage entre programmes.

---

*Document de reference — Patrick Bays / Digital Shaman Lab*
*Mis a jour le 22 mars 2026*
