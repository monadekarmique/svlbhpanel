# SVLBH Panel — Briefing Testeurs
## Builds 8 → 11 · 22 mars 2026

Bonjour à toutes et tous 🙏

Voici les nouveautés depuis le Build 7. Faites **pull-to-refresh dans TestFlight** pour récupérer le **Build 11**.

---

### 🔬 Build 10 — Merge + Suggestions (le gros morceau)

**Fini l'écrasement des données !** Quand Patrick vous envoie son décodage :

- Si un champ était **vide** chez vous → il se remplit automatiquement
- Si un champ est **identique** → rien ne change
- Si un champ est **différent** → une **proposition bleue 🔬** apparaît

Vous pouvez **adopter ou ignorer** chaque proposition individuellement — pas de "tout écraser". Les scores SLA/SLSA/SLM restent en application directe (supervision).

**Où voir les suggestions :**
- **Décodage G.** → badge 🔬 dans le header de chaque génération
- **Pierres** → bord bleu pointillé = pierre proposée, bouton ✓ pour adopter
- **Chakras** → badge 🔬 bleu tapable à côté du checkbox

Le bouton "Importer" dit maintenant **"Fusionner"** — plus de panique 😊

---

### Build 8 — Améliorations visuelles

- Définitions SLM plus grandes (13pt au lieu de 11pt)
- Pierres : layout vertical restructuré, plus de chevauchement
- Icônes pierres → ₩ partout
- KPI Pierres ₩ dans l'onglet SVLBH

---

### Build 9 — Fiabilité

- Les scores SLM se reflètent maintenant **en temps réel** dans l'onglet SVLBH
- Sélection des pierres aussi visible en temps réel dans les KPI
- Obsidienne noire : "G-4" supprimé, durée = 5 jours

---

### 🆕 Build 11 — Nouveautés de la session d'après-midi

**📋 Bouton "Copier"** — L'export ne bloque plus sur WhatsApp !
- Menu ⋯ → "Exporter WhatsApp" → écran avec aperçu
- Bouton principal : **"Copier dans le presse-papier"** (haptic + ✓ vert)
- Bouton secondaire : "Partager…" (l'ancien ShareSheet, si ça marche pour vous)
- Collez ensuite où vous voulez : WhatsApp, iMessage, Notes…

**📊 Tabelle SLSA S1–S5** — Nouveau dans l'onglet SLM
- 5 cases horizontales : S5 | S4 | S3 | S2 | **S1**
- S1 (fond coloré) = le SLSA qui remonte sur l'onglet SVLBH
- Bouton secondaire : "Partager…" (l'ancien ShareSheet)
- S2 à S5 = saisissables, 0–750%

**📥 Scan des sources (Patrick uniquement)**
- Le bouton "Recevoir" est maintenant un **menu déroulant**
- **Badge rouge** avec le nombre de sources en attente
- "Scanner les sources" vérifie toutes les shamanes en parallèle
- Tap sur un nom → réception immédiate de cette source
- Auto-scan au lancement de l'app

**🐛 Bugs corrigés :**
- "Sync Prêt" n'est plus caché par la barre d'onglets
- Log de réception : affiche maintenant le bon nom ("Réception de Flavia" au lieu de "Réception de Patrick")

---

### 🔜 TODO prochaine session

| Prio | Quoi |
|------|------|
| P1 | Texte d'aide patient/groupe (confidentialité, + vert = urgence) |
| P2 | CIM-11 pathologies sélectionnables individuellement |
| P2 | Enrichir définition Tot SLM + voyelles sacrées |

---

Merci pour vos retours, continuez à envoyer vos feedbacks via TestFlight (screenshot + commentaire) 🙏

*Patrick — Digital Shaman Lab*
