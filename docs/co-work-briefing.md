---
title: "Co-Work Briefing — Phase 3 Production Rollout"
status: draft
version: 1.0
last_updated: 2026-04-10
author: Patrick Bays (pb@vlbh.energy)
audience: Co-Work operator executing handoff from claude/user-skills-persistence-ta0Js
source_branch: claude/user-skills-persistence-ta0Js
source_commits:
  - ec603a4  # Phase 0 scaffold
  - b68085f  # migration doc WA
related_docs:
  - docs/whatsapp-router-migration.md
  - agents/README.md
  - agents/hdom-session-agent.json
  - agents/passeport-ratio-agent.json
  - agents/whatsapp-vlbh-agent.json
---

# Co-Work Briefing — 6 actions de passage en production

> Branche source : `claude/user-skills-persistence-ta0Js` sur `monadekarmique/svlbhpanel`
> Commits clés : `ec603a4` (Phase 0 scaffold) → `b68085f` (migration doc WA)
> Document pivot : [`docs/whatsapp-router-migration.md`](./whatsapp-router-migration.md)

Ordre logique de dépendances, pas forcément l'ordre de la liste d'origine. Chaque briefing est auto-contenu : Co-Work peut en prendre un sans avoir lu les autres.

## Table des matières

- [Points de contrôle (à valider avec Patrick)](#points-de-contrôle-à-valider-avec-patrick)
- [Briefing 1 — Sécurité clé API Anthropic](#briefing-1--sécurité-clé-api-anthropic)
- [Briefing 2 — xcconfig iOS + wiring Xcode](#briefing-2--xcconfig-ios--wiring-xcode)
- [Briefing 3 — Skills VLBH à compléter](#briefing-3--skills-vlbh-à-compléter)
- [Briefing 4 — `sync_agents.swift` premier run live](#briefing-4--sync_agentsswift-premier-run-live)
- [Briefing 5 — Make scénario #8944541 : §2 → §3 → §4](#briefing-5--make-scénario-8944541--2--3--4)
- [Briefing 6 — Tests T1-T10](#briefing-6--tests-t1-t10)
- [Ordre d'exécution recommandé](#ordre-dexécution-recommandé)

---

## Points de contrôle (à valider avec Patrick)

À confirmer explicitement avec Patrick avant de passer au briefing suivant :

- [ ] **Après Briefing 1** : clé plus visible dans le blueprint export, purge history OK, budget Anthropic + alertes actives
- [ ] **Après Briefing 3** : au moins un SKILL.md de référence validé par Patrick côté contenu VLBH
- [ ] **Après Briefing 4** : `agents/.lockfile.json` committé avec les 3 IDs (ou mention explicite des agents bloqués par safeguard TBD)
- [ ] **Après Briefing 5 §2 + §3** : run test avec numéro connu OK sans toucher au module HTTP 4
- [ ] **Après Briefing 5 §4** : premier vrai message WA répondu par l'agent managé, feature flag toujours reversible
- [ ] **Après Briefing 6** : 10/10 tests PASS + 7 jours de monitoring stable avant suppression du `4_legacy`

---

## Briefing 1 — Sécurité clé API Anthropic

**Dépendances** : aucune. À faire en premier ou en parallèle de tout le reste.

**Objectif** : sortir la clé `sk-ant-api03-2TXpSYfha-Ul50dREMu1TlI...` du blueprint Make et de l'historique d'exécutions, sans révocation immédiate.

**Contexte** : la clé est actuellement en clair dans le module HTTP 4 du scénario `#8944541`, visible dans tout export blueprint. Patrick est seul utilisateur de Make, risque assumé. On applique la mitigation minimale Option 1 + Option 3 du doc de migration (cf. [`docs/whatsapp-router-migration.md`](./whatsapp-router-migration.md) §1).

**Pré-requis** :

- Accès admin Make team `630342`
- Accès `console.anthropic.com` avec droits workspace admin
- La clé actuelle encore en clair dans le scénario (la nouvelle Team Variable la remplace)

**Étapes** :

1. Make → Team Variables (settings de la team `630342`) → Add
   - Name: `ANTHROPIC_API_KEY`
   - Type: `secret`
   - Value: copier la clé actuelle depuis le module HTTP 4 du scénario
2. Make → scénario #8944541 → module HTTP 4 → Headers : remplacer la valeur du header `x-api-key` par `{{getVariable("ANTHROPIC_API_KEY")}}`
3. Sauvegarder le scénario
4. Make → scénario #8944541 → History : purger l'historique d'exécutions (bouton Purge history ou équivalent)
5. `console.anthropic.com` → Settings → Usage limits :
   - Définir un budget mensuel strict sur le workspace SVLBH (ex: 50 $/mois — à calibrer selon le trafic estimé)
   - Activer les alertes email à 50 % / 80 % / 100 %

**Critères de succès** :

- L'export blueprint du scénario ne contient plus la clé en clair (juste `{{getVariable("ANTHROPIC_API_KEY")}}`)
- Un run test du scénario passe correctement avec l'appel à Anthropic
- L'historique d'exécutions ancien est vidé côté UI
- Les alertes budget sont visibles dans le dashboard Anthropic

**Pièges** :

- ⚠️ Ne **PAS** supprimer la clé actuelle sur `console.anthropic.com` — ce n'est pas une révocation, c'est une remise dans une variable secrète
- Si Team Variables `secret` indisponibles sur le plan Make actuel, utiliser une variable normale (moins propre, mais mieux que la clé en clair)
- La purge d'historique Make peut prendre plusieurs secondes sur les gros historiques (108 erreurs + runs nominaux = plusieurs centaines d'entrées probablement)

**Pointeurs doc** : [`docs/whatsapp-router-migration.md`](./whatsapp-router-migration.md) §1 (toutes les options détaillées avec contraintes techniques)

---

## Briefing 2 — xcconfig iOS + wiring Xcode

**Dépendances** : aucune côté config. Mais bloquant pour le build iOS qui consomme les agents (Phase 1 hdom + Phase 2 passeport).

**Objectif** : injecter la clé API Anthropic et les IDs d'agents dans l'`Info.plist` généré, via `.xcconfig` non versionnés.

**Contexte** : `secrets.xcconfig` et `Config.xcconfig` sont déjà dans `.gitignore` (lignes 41-42). Deux templates `.example` sont committés comme source de vérité. `AnthropicConfig.swift` lit les valeurs depuis `Bundle.main.object(forInfoDictionaryKey:)`.

**Pré-requis** :

- Clone local du repo, branche `claude/user-skills-persistence-ta0Js` checkout
- Xcode ouvert sur `SVLBH Panel.xcodeproj`
- Une clé API Anthropic distincte de celle utilisée côté Make (recommandation : `SVLBH-iOS-Direct` vs `SVLBH-Make-Router` sur `console.anthropic.com`)
- Les IDs d'agents seront disponibles après le [Briefing 4](#briefing-4--sync_agentsswift-premier-run-live) — ce briefing peut donc être fait en deux passes

**Étapes** :

1. Au niveau racine du repo :

    ```bash
    cp secrets.xcconfig.example secrets.xcconfig
    cp Config.xcconfig.example Config.xcconfig
    ```

2. Éditer `secrets.xcconfig` et remplir :

    ```text
    ANTHROPIC_API_KEY = sk-ant-api03-<la nouvelle clé iOS dédiée>
    ANTHROPIC_AGENT_HDOM_SESSION = <ID rempli après Briefing 4>
    ANTHROPIC_AGENT_PASSEPORT_RATIO = <ID rempli après Briefing 4>
    ANTHROPIC_AGENT_WHATSAPP_VLBH = <ID rempli après Briefing 4>
    ```

3. Xcode → Project navigator → projet `SVLBH Panel` → onglet `Info` → section `Configurations` :
   - Pour chaque configuration (Debug, Release) :
     - Ligne `SVLBH Panel` → cliquer sur le dropdown `None` → sélectionner `Config.xcconfig`
4. Sauvegarder le projet Xcode (⌘S) — le `project.pbxproj` reçoit les `baseConfigurationReference` mises à jour. Ne pas committer ces modifs du `.pbxproj` sans avoir relu (le reste du projet ne doit pas avoir changé).
5. Build → s'assurer que :
   - Aucun warning « configuration reference not found »
   - L'`Info.plist` généré (visible dans `DerivedData/.../Info.plist`) contient bien les clés `ANTHROPIC_API_KEY`, `ANTHROPIC_AGENT_HDOM_SESSION`, etc.
6. Au runtime, `AnthropicConfig.isConfigured` doit retourner `true` quand l'app démarre.

**Critères de succès** :

- Le build compile sans erreur de config
- `AnthropicConfig.apiKey != nil` dans le debugger au premier lancement
- `git status` montre `secrets.xcconfig` et `Config.xcconfig` comme ignorés (pas dans untracked)

**Pièges** :

- ⚠️ Ne **JAMAIS** committer `secrets.xcconfig` ou `Config.xcconfig`. Vérifier `git status` avant tout add.
- Le `#include? "secrets.xcconfig"` dans `Config.xcconfig.example` utilise le `?` pour ne pas crasher si le fichier est absent — mais cela masque aussi les erreurs de chemin si le fichier n'est pas à la racine. Garder les deux fichiers au même niveau que `SVLBH Panel.xcodeproj`.
- Si l'`Info.plist` est auto-généré (`GENERATE_INFOPLIST_FILE = YES` dans le projet), il faut bien utiliser le pattern `INFOPLIST_KEY_*` dans `Config.xcconfig` (déjà le cas dans le template). Ne pas essayer de créer un `Info.plist` manuel.
- Si Xcode ne reconnaît pas les xcconfig après l'assignation, Product → Clean Build Folder (⇧⌘K) puis rebuild.
- La clé iOS doit être différente de la clé Make même si techniquement ça peut marcher — c'est pour isoler les compromissions.

**Pointeurs doc** :

- `secrets.xcconfig.example` + `Config.xcconfig.example` (templates à la racine)
- `SVLBH Panel/Services/AnthropicConfig.swift` (lecture côté Swift)

---

## Briefing 3 — Skills VLBH à compléter

**Dépendances** : aucune pour l'écriture. Bloquant pour que `hdom-session-agent` fonctionne en mode nominal (il marche en mode dégradé sans skills, mais avec un signal explicite d'insuffisance).

**Objectif** : remplir les placeholders `[À REMPLIR par Patrick]` dans les 3 SKILL.md puis les mettre à disposition côté Anthropic.

**Contexte** : les templates sont dans `docs/skills-templates/` (versionnés, skeleton + connaissance clinique générale). Les vrais SKILL.md doivent vivre dans `SVLBH Panel/Skills/<slug>/SKILL.md` (dossier gitignoré par convention — contenu propriétaire VLBH). Les skills seront chargés par `hdom-session-agent` via sa liste déclarée dans `agents/hdom-session-agent.json`.

**Pré-requis** :

- Accès en écriture au repo local
- Session Claude.ai ouverte en parallèle (elle a déjà commencé à produire les fichiers `hdom-session-agent-system-prompt.md` et `hdom-radiesthesie-patch.md` — elle peut aussi produire les SKILL.md)
- Savoir VLBH/hDOM propriétaire de Patrick (terminologie, protocoles, correspondances méridiens/couleurs/pierres)

**Étapes** :

1. Pour chacun des 3 skills :

    ```bash
    mkdir -p "SVLBH Panel/Skills/hdom-decoder"
    mkdir -p "SVLBH Panel/Skills/sommeil-troubles-nuit"
    mkdir -p "SVLBH Panel/Skills/endometriose-ferritine"
    cp docs/skills-templates/hdom-decoder.SKILL.md "SVLBH Panel/Skills/hdom-decoder/SKILL.md"
    cp docs/skills-templates/sommeil-troubles-nuit.SKILL.md "SVLBH Panel/Skills/sommeil-troubles-nuit/SKILL.md"
    cp docs/skills-templates/endometriose-ferritine.SKILL.md "SVLBH Panel/Skills/endometriose-ferritine/SKILL.md"
    ```

2. Ouvrir chaque fichier et remplacer tous les blocs `[À REMPLIR par Patrick]` par le contenu VLBH réel :
   - `hdom-decoder` : table hDOM complète 24 h → méridien → organe → zone de décharge → observations ; interprétations SLA/SLSA bas/haut sur méridiens yin/yang ; protocoles-types associés à chaque méridien
   - `sommeil-troubles-nuit` : lecture VLBH spécifique des plages nocturnes (21-23h, 23-01h, 01-03h, 03-05h, 05-07h) → méridien / organe / corps de référence / thématique énergétique ; 5 patterns détectés (réveil récurrent, endormissement, insomnie, cauchemars, sueurs) avec interprétation VLBH
   - `endometriose-ferritine` : correspondances endométriose ↔ chakras / portes énergétiques ; corrélation ferritine ↔ SLA/SLSA observée ; couleurs « soutien-ferritine » spécifiques ; adaptation protocole phase lutéale
3. Uploader côté Anthropic :
   - **Option A (manuelle)** : `console.anthropic.com` → Workspace → Skills → Upload → un fichier par skill (slug + contenu SKILL.md)
   - **Option B (scriptée)** : créer `Scripts/upload_skills.swift` (non implémenté en Phase 0, à écrire) qui parcourt `SVLBH Panel/Skills/*/SKILL.md` et POSTe vers l'endpoint Skills Anthropic — nécessite de connaître l'API exacte (à vérifier sur la doc)
4. Vérifier côté console Anthropic que les 3 skills apparaissent et sont référençables par l'agent
5. **Optionnel mais recommandé** : synchroniser ces fichiers avec le repo privé `svlbhpanel-private` (ligne 48 du `.gitignore`) pour que d'autres postes de dev puissent les récupérer.

**Critères de succès** :

- Les 3 SKILL.md dans `SVLBH Panel/Skills/` ne contiennent plus aucun `[À REMPLIR]`
- Les 3 skills apparaissent dans la console Anthropic Skills
- `git status` montre que `SVLBH Panel/Skills/` reste ignoré (pas de fuite de contenu propriétaire dans le repo public)
- Un test manuel via l'agent (Briefing 4 + Briefing 6) retourne une réponse qui cite les connaissances des skills (ex : méridien actif précis selon l'heure de réveil réelle)

**Pièges** :

- ⚠️ `SVLBH Panel/Skills/` est dans `.gitignore:50`. Ne **JAMAIS** forcer l'add de ces fichiers dans ce repo public.
- Les templates contiennent déjà de la connaissance clinique générale (physiologie du sommeil, seuils ferritine, rappels endométriose). Patrick doit la garder et compléter avec le VLBH propre — pas tout réécrire de zéro.
- La section « Historique » au bas de chaque SKILL.md doit être mise à jour avec la nouvelle version (v0.2, v1.0...) et la date, pour que Patrick trace ses itérations.
- Si la session Claude.ai a déjà commencé à produire ces skills (elle a déjà produit le system prompt hdom-session-agent v0.1), récupérer son travail et merger plutôt que de repartir de zéro.
- Le skill `hdom-decoder` contient le schema JSON de sortie attendu pour les propositions Type A/B (ajouté dans le patch radiesthésique). Cette partie ne doit pas être modifiée — elle est alignée sur le code iOS (`HDOMPreparationResult.Proposition`).

**Pointeurs doc** :

- `docs/skills-templates/*.SKILL.md` (sources à copier et remplir)
- `agents/hdom-session-agent.json` → champ `skills` (liste des skills attendus par l'agent)
- `SVLBH Panel/Models/HDOMPayload.swift` → struct `Proposition` (schema que les skills doivent respecter en sortie JSON)

---

## Briefing 4 — `sync_agents.swift` premier run live

**Dépendances** :

- [Briefing 1](#briefing-1--sécurité-clé-api-anthropic) (clé API Anthropic valide avec accès bêta `managed-agents-2026-04-01`)
- [Briefing 3](#briefing-3--skills-vlbh-à-compléter) idéalement fait avant (sinon `hdom-session-agent` sera créé mais ne pourra pas charger ses skills)
- Les 3 fichiers `agents/*.json` dans leur état final

**Objectif** : créer les 3 Managed Agents sur Anthropic, récupérer leurs IDs, remplir `agents/.lockfile.json`.

**Contexte** : le script `Scripts/sync_agents.swift` est Foundation-pur, lit `agents/*.json`, calcule un hash SHA-256 de chaque définition, compare au lockfile, POST `/v1/agents` si absent, PATCH `/v1/agents/{id}` si modifié. Safeguard : refuse de pousser un agent dont un tool a une URL `TBD_*`. Mode `--dry-run` disponible.

**Pré-requis** :

- macOS ou Linux avec `swift` installé (vérifier `swift --version` → ≥ 5.5)
- Clé API Anthropic avec accès bêta Managed Agents dans l'env
- Repo checkout à la racine

**Étapes** :

1. Export de la clé API :

    ```bash
    export ANTHROPIC_API_KEY=sk-ant-api03-<ta clé dédiée Managed Agents>
    ```

2. Dry run d'abord — ne touche à rien, imprime juste ce qu'il ferait :

    ```bash
    swift Scripts/sync_agents.swift --dry-run
    ```

    Sortie attendue :

    ```text
    → hdom-session-agent
      [dry-run] would CREATE agent
    → passeport-ratio-agent
      ❌ Agent passeport-ratio-agent a un tool `fetch_svlbh_ref_21s` avec URL TBD
    → whatsapp-vlbh-agent
      [dry-run] would CREATE agent
    ```

3. Si `passeport-ratio-agent` est bloqué par le safeguard TBD : soit créer le webhook Make `fetch_svlbh_ref_21s` (data store #157532) et remplacer `TBD_WEBHOOK_REF21S_URL` par sa vraie URL dans `agents/passeport-ratio-agent.json`, soit retirer le tool du JSON si on décide de ne pas l'utiliser (cf. discussion Option A vs B du chat).
4. Sync réel des agents qui passent :

    ```bash
    swift Scripts/sync_agents.swift
    ```

5. Vérifier `agents/.lockfile.json` — il contient maintenant les IDs retournés :

    ```json
    {
      "version": 1,
      "agents": {
        "hdom-session-agent": {
          "id": "agent_01ABC...",
          "last_sync": "2026-04-10T14:32:01Z",
          "content_hash": "sha256:..."
        }
      }
    }
    ```

6. Commit le lockfile (versionné, partagé entre machines de dev) :

    ```bash
    git add agents/.lockfile.json
    git commit -m "agents: initial sync — hdom-session + passeport-ratio + whatsapp-vlbh"
    git push
    ```

7. Recopier les IDs dans `secrets.xcconfig` (côté iOS — [Briefing 2](#briefing-2--xcconfig-ios--wiring-xcode)) et dans les Team Variables Make (côté Make — [Briefing 5](#briefing-5--make-scénario-8944541--2--3--4)).

**Critères de succès** :

- `agents/.lockfile.json` rempli avec 1 à 3 entrées (selon combien d'agents passent le safeguard)
- Un appel direct curl à `https://api.anthropic.com/v1/sessions` avec l'ID d'un agent retourne une réponse 200 (sanity test)

**Pièges** :

- ⚠️ Le mapping local → API payload dans `sync_agents.swift` (fonction `agentJSONToAPIPayload`) est une hypothèse raisonnable basée sur les notes CLAUDE.md, pas validée contre la doc officielle Managed Agents. Si l'API retourne un 4xx au premier run, lire le body d'erreur, ajuster `agentJSONToAPIPayload()` dans le script, re-run.
- L'accès bêta `managed-agents-2026-04-01` doit être effectivement activé sur le workspace. En cas de 403 → `console.anthropic.com` → Settings → Beta features → activer. Sans ça, pas de sync possible.
- `swift` en ligne de commande sur macOS nécessite Xcode Command Line Tools (`xcode-select --install`). Sur Linux, installer Swift depuis swift.org.
- Le script utilise `CommonCrypto` pour SHA-256 via `#if canImport(CommonCrypto)` — dispo nativement sur macOS, à vérifier sur Linux. Si absent, le script échoue au calcul du hash.
- Ne **PAS** re-run `sync_agents.swift` à chaque commit sans raison — le hash prévient les PATCH inutiles, mais en cas de collision de hash (improbable), un agent pourrait être patché en boucle.

**Pointeurs doc** :

- `Scripts/sync_agents.swift` (le script lui-même, lire la docstring en tête)
- `agents/README.md` (workflow et format des JSON)

---

## Briefing 5 — Make scénario #8944541 : §2 → §3 → §4

**Dépendances** :

- [Briefing 1](#briefing-1--sécurité-clé-api-anthropic) (Team Variable `ANTHROPIC_API_KEY` créée)
- [Briefing 4](#briefing-4--sync_agentsswift-premier-run-live) (ID `whatsapp-vlbh-agent` disponible dans `agents/.lockfile.json`)

**Objectif** : stabiliser le scénario Router WhatsApp puis le migrer vers `whatsapp-vlbh-agent` via Option B (modif in-place du module HTTP 4).

**Contexte** : le scénario a 108 erreurs historiques dues à deux bugs (normalisation CT + Nouveau contact sans WebhookRespond), identifiés et documentés. La migration vers l'agent managé remplace uniquement le module HTTP 4 — le trigger `gateway:CustomWebHook` (hook `4000349`), le lookup svlbh-v2, le bridge Go, tout le reste est préservé.

**Pré-requis** :

- Sécurité §1 appliquée ([Briefing 1](#briefing-1--sécurité-clé-api-anthropic))
- ID agent `whatsapp-vlbh-agent` connu ([Briefing 4](#briefing-4--sync_agentsswift-premier-run-live))
- Export du blueprint actuel du scénario #8944541 sauvegardé hors-ligne (pour rollback)
- Une fenêtre de maintenance de ~1 h avec trafic WhatsApp faible (idéalement tôt le matin ou tard le soir CH)

**Étapes** :

1. **Backup** : Make → scénario #8944541 → Menu ⋯ → Export blueprint → sauvegarder en local sous `backup-8944541-YYYY-MM-DD.json`
2. **Créer la Team Variable ID agent** : Make → Team Variables → Add
   - Name: `ANTHROPIC_AGENT_WHATSAPP_VLBH`
   - Type: `text`
   - Value: `agent_01...` (copié depuis `agents/.lockfile.json` après Briefing 4)
3. **§2 — Fix bug CT (normalisation numéro)** :
   - *Approche minimale* : éditer le module 2 (datastore GetRecord svlbh-v2), remplacer la formule de clé par :

        ```text
        CT-{{replace(replace(1.from; "@s.whatsapp.net"; ""); "@lid"; "")}}
        ```

   - *Approche DRY recommandée* : ajouter un module `util:SetVariable` juste après le trigger (nouveau module #1b) :

        ```text
        name: senderPhone
        value: + + {{replace(replace(1.from; "@s.whatsapp.net"; ""); "@lid"; "")}}
        ```

     Puis remplacer tous les `{{1.from}}` en aval par `{{senderPhone}}`.
   - Sauvegarder.
4. **§3 — Fix Route Nouveau contact** :
   - Ajouter un module `gateway:WebhookRespond` après le module 10 (save nouveau contact), avec body :

        ```json
        {
          "type": "new_contact_registered",
          "reply": "Bonjour, merci pour votre message ! Patrick (Digital Shaman Lab) va prendre connaissance de votre demande et vous répondra dès que possible.",
          "meta": {
            "phone": "{{senderPhone}}",
            "registered_at": "{{now}}"
          }
        }
        ```

   - Sauvegarder.
5. **Run de test intermédiaire avant de toucher au module 4** :
   - Envoyer un WA depuis un numéro connu du datastore svlbh-v2 (avec segment défini)
   - Envoyer un WA depuis un numéro inconnu (test de la route Nouveau contact)
   - Vérifier dans l'historique Make que les deux runs se terminent proprement (pas de timeout)
   - **Ne pas continuer** tant que §2 et §3 ne sont pas verts.
6. **§4 — Migration du module HTTP 4** :
   - Approche recommandée : duplication du module 4 en `4_legacy`, création d'un nouveau `4_agent` à côté
   - Configurer `4_agent` en copiant le contenu de `docs/whatsapp-agent-module4-blueprint.json` :
     - URL: `https://api.anthropic.com/v1/sessions`
     - Method: POST
     - Headers: voir blueprint (5 headers dont `x-api-key` via `getVariable`, `anthropic-version`, `anthropic-beta: managed-agents-2026-04-01`)
     - Body (jsonString): le payload avec `agent_id` + `messages` contenant le bloc PROFIL PATIENTE + MESSAGE ENTRANT (mapping de `{{senderPhone}}`, `{{2.segment}}`, `{{2.display_name}}`, `{{2.last_seen}}`, `{{2.notes}}`, `{{1.text}}`)
     - `parseResponse: true`, `timeout: 60`
   - Ajouter un `flow:Router` en amont du module 4 conditionné par une Team Variable `WHATSAPP_AGENT_ENABLED` :
     - Si `true` → route vers `4_agent`
     - Si `false` → route vers `4_legacy`
   - Créer la Team Variable `WHATSAPP_AGENT_ENABLED = false` initialement.
7. **Parsing réponse agent** : module `util:ParseJSON` (module 5) prenant `{{4_agent.body.content[0].text}}` en input, type structure `agent_response_v0_2`.
8. **Brancher** `5.reply` vers le `gateway:WebhookRespond` existant (module 6) qui renvoie au bridge Go.
9. **Branche alert** : `flow:Router` conditionné par `{{5.alert_patrick}} = true`, sur la branche true, un `http:MakeRequest` qui POST sur `https://hook.eu2.make.com/lllo1g6btuv4e3qjt4qvpj8fjwyd663s` avec body `{"message": "🚨 Alert patiente {{senderPhone}} ({{5.segment_detected}}): {{5.alert_reason}}\n\nMessage: {{1.text}}"}`.
10. **Activer le switch** : Team Variable `WHATSAPP_AGENT_ENABLED` → passer à `true`.
11. **Test unitaire** avec un numéro test → vérifier que la réponse arrive côté WhatsApp, que la mémoire de session agent se construit, que `alert_patrick=false` par défaut.
12. **Monitoring 24 h** avant de supprimer `4_legacy` définitivement.

**Critères de succès** :

- Taux d'erreur scénario < 1 % sur 24 h (vs 108 erreurs historiques)
- Aucun timeout bridge Go signalé
- Les patientes reçoivent des réponses cohérentes par segment
- Le budget Anthropic progresse à un rythme compatible avec les alertes fixées en Briefing 1
- Un alert Patrick déclenché si une patiente mentionne un symptôme aigu (cas T6 du test plan)

**Pièges** :

- ⚠️ Ne **PAS** oublier le backup blueprint initial avant toute modif — sans ça, pas de rollback possible
- Le feature flag `WHATSAPP_AGENT_ENABLED` permet de revenir au legacy en 1 clic en cas de problème. À garder en place au moins 7-14 jours avant suppression du legacy.
- Les headers `anthropic-beta` et `User-Agent` Mozilla sont critiques : le premier pour activer le bêta Managed Agents, le second pour passer Cloudflare (leçon du watchdog Make infra).
- Si `util:ParseJSON` échoue parce que l'agent a dévié du format JSON strict → c'est le system prompt qui n'est pas assez contraignant, ne pas bricoler côté Make, retourner le problème au system prompt `agents/whatsapp-vlbh-agent.json` + re-run `sync_agents`.
- Le chemin `{{4_agent.body.content[0].text}}` est une hypothèse sur le format de réponse Managed Agents — à valider au premier vrai run, ajuster si différent (ex : `{{4_agent.body.messages[0].content}}` ou autre).
- La clé API Make est désormais `{{getVariable("ANTHROPIC_API_KEY")}}` — ne **JAMAIS** la remettre en clair dans un fix rapide.

**Pointeurs doc** :

- [`docs/whatsapp-router-migration.md`](./whatsapp-router-migration.md) §2, §3, §4 (plan détaillé complet avec formules exactes)
- `docs/whatsapp-agent-module4-blueprint.json` (snippet copiable du module)
- `agents/whatsapp-vlbh-agent.json` (system prompt v0.2 qui définit le contrat de réponse JSON)

---

## Briefing 6 — Tests T1-T10

**Dépendances** : tous les autres Briefings (1 à 5) complets.

**Objectif** : valider que la migration Phase 3 est stable et que chaque segment/cas d'usage fonctionne comme spécifié.

**Contexte** : 10 cas de test obligatoires définis dans le §5 du migration doc, couvrant les 3 segments, les nouveaux contacts, les bugs corrigés, les symptômes aigus, la mémoire de session, le parsing robuste, les erreurs infra.

**Pré-requis** :

- Scénario #8944541 en mode agent actif (`WHATSAPP_AGENT_ENABLED = true`)
- Au moins 3 numéros WhatsApp test dans svlbh-v2 : un `patient_actif`, un `lead`, un `praticien`
- Un 4ᵉ numéro non inscrit dans svlbh-v2 pour tester la route Nouveau contact
- Accès admin Make pour consulter History et logs
- Patrick disponible pour valider les réponses manuellement

### Cas de test

Exécuter chaque cas en notant le résultat dans ce tableau :

| #   | Scénario              | Input                                                                                                               | Résultat attendu                                                                                                                         | PASS/FAIL |
| :-- | :-------------------- | :------------------------------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------- | :-------- |
| T1  | `patient_actif` connu | « Coucou, comment je dois utiliser la pierre que tu m'as donnée la dernière fois ? »                                | `reply` familier, référence éventuelle à la mémoire, `alert_patrick=false`                                                               |           |
| T2  | `lead` connu          | « Bonjour, j'ai entendu parler de vous et je voudrais savoir comment ça marche »                                    | `reply` empathique + lien discovery, aucun contenu thérapeutique                                                                         |           |
| T3  | `praticien` connu     | « J'ai une patiente avec SLA 85, SLSA 200, comment tu interprètes ? »                                               | Ton confraternel, aide technique, pas de données sur la patiente tierce                                                                  |           |
| T4  | Nouveau contact       | Depuis un numéro non inscrit, « Bonjour »                                                                           | Réponse d'accueil, record créé dans #157329, aucun timeout bridge Go                                                                     |           |
| T5  | Suffixe `@lid`        | Simuler `1.from = "+33612345678@lid"` (via module Postman ou second compte test)                                    | Module 2 trouve le record, pas de fallback nouveau_contact erroné                                                                        |           |
| T6  | Symptôme aigu         | Depuis un numéro `patient_actif` endo/ferritine : « J'ai mal au ventre depuis cette nuit, très intense »            | `alert_patrick=true`, `alert_reason` non vide, POST vers WA Router pour notifier Patrick, `reply` rassurant vers la patiente             |           |
| T7  | Mémoire de session    | Envoyer 3 messages successifs à 5 min d'intervalle depuis le même numéro, le 3ᵉ faisant référence au 1ᵉʳ            | L'agent répond en faisant le lien (« comme tu me disais tout à l'heure... »)                                                             |           |
| T8  | Parsing robuste       | Provoquer une réponse agent avec fences de code (balises `` ```json `` ) ou texte parasite autour du JSON           | Le parseur extrait le JSON, pas de crash du scénario                                                                                     |           |
| T9  | Erreur 403            | Désactiver temporairement le header `anthropic-beta` dans le module 4                                               | Scénario log HTTP 403, feature flag `WHATSAPP_AGENT_ENABLED=false` déclenché si rollback auto                                            |           |
| T10 | Variable Make vide    | Vider temporairement `ANTHROPIC_API_KEY`                                                                            | HTTP 401, erreur visible dans logs Make, pas de crash                                                                                    |           |

### Après T1-T10

1. **Monitoring 7 jours** — ouvrir Make → scénario → History quotidiennement, vérifier :
   - Taux d'erreur < 1 %
   - Distribution `5.segment_detected` cohérente
   - Alertes Patrick déclenchées justifiées (pas de faux positifs massifs)
   - Latence module HTTP 4 : p50 < 3 s, p95 < 8 s
   - Consommation Anthropic dans le budget défini
2. **Désactivation `4_legacy`** après la semaine de monitoring sans incident.
3. **Documentation** d'un éventuel incident dans une section « Incidents » de [`docs/whatsapp-router-migration.md`](./whatsapp-router-migration.md).

**Critères de succès** :

- 10/10 tests PASS
- 7 jours de monitoring sans rollback nécessaire
- Taux d'erreur stable < 1 %
- Budget Anthropic maîtrisé
- `4_legacy` supprimé proprement

**Pièges** :

- ⚠️ T6 (symptôme aigu) doit être testé avec un numéro qui ne va pas vraiment aux urgences en vrai — utiliser un numéro test dédié.
- T7 (mémoire de session) suppose que la mémoire se construit à partir du 1ᵉʳ message, donc tester uniquement sur un numéro qui n'a aucun historique antérieur avec l'agent. Si tu testes plusieurs fois avec le même numéro, le 3ᵉ run aura une mémoire polluée par les 2 précédents.
- T9 et T10 nécessitent de toucher au scénario actif — faire pendant la fenêtre de maintenance, revenir à l'état nominal immédiatement après.
- Les tests consomment du budget Anthropic réel — environ 0,10 $ pour les 10 tests, à garder en tête.
- Si un test FAIL, ne pas bricoler côté Make — remonter le problème au bon endroit :
  - Problème de format JSON en réponse → system prompt `agents/whatsapp-vlbh-agent.json`
  - Problème de routing segment → module 2 ou module 4 body
  - Problème d'alert → parsing `5.alert_patrick`
  - Problème de bridge Go → en dehors du scope de cette migration, remonter côté bridge Go

**Pointeurs doc** :

- [`docs/whatsapp-router-migration.md`](./whatsapp-router-migration.md) §5 (test plan complet) et §6 (rollback)

---

## Ordre d'exécution recommandé

```text
Jour 1 matin
├─ Briefing 1 (Sécurité clé API) ........... ~20 min
├─ Briefing 2 (xcconfig iOS — partiel,
│              sans les IDs agents) ........ ~15 min
└─ Briefing 3 (Skills VLBH — rédaction) .... ~2-4 h

Jour 1 après-midi
├─ Briefing 4 (sync_agents.swift) .......... ~30 min
│    └─ nécessite Briefing 3 terminé au moins pour hdom
└─ Retour sur Briefing 2 (compléter les 3
   IDs agents dans secrets.xcconfig) ....... ~5 min

Jour 2 matin (fenêtre de maintenance)
└─ Briefing 5 (Make §2 → §3 → §4) .......... ~1 h
    ├─ §2 + §3 + test intermédiaire
    ├─ §4 avec duplication feature flag
    └─ Activation WHATSAPP_AGENT_ENABLED=true

Jour 2-8 (monitoring)
└─ Briefing 6 (Tests T1-T10 puis monitoring
               7 jours) ................... ~1 h tests + suivi

Jour 9
└─ Suppression module 4_legacy, désactivation
   scénario #8999937 (passeport remplacé iOS)
```

**Total effort** : ~8-10 h de travail Patrick/Co-Work sur 9 jours, dont 1 h de vrai travail Make concentré + ~2-4 h de rédaction SKILL.md VLBH (c'est cette dernière qui est le vrai bottleneck).

---

*Document généré le 2026-04-10. À déposer dans `docs/co-work-briefing.md` sur la branche `claude/user-skills-persistence-ta0Js`.*
