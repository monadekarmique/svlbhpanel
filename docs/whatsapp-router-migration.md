# WhatsApp Router Migration — Scénario Make #8944541 → whatsapp-vlbh-agent

**Branche de suivi** : `claude/user-skills-persistence-ta0Js`
**Dernière mise à jour** : 2026-04-10
**État cible** : migration Phase 3 Managed Agents (Option B — modif in-place)

## Contexte

Le scénario Make `SVLBH — Router WhatsApp` (id `#8944541`, team `630342`) route les messages WhatsApp entrants des patientes, leads et praticiennes. Il présente à ce jour **108 erreurs** dans son historique, dont plusieurs sources distinctes identifiées par analyse du blueprint.

Ce document décrit :

1. Les options pour minimiser la fuite de clé API Anthropic sans révocation immédiate
2. Le fix du bug de clé `CT-` (normalisation `@s.whatsapp.net` / `@lid`)
3. Le fix de la route « Nouveau contact » qui timeout le bridge Go
4. La migration Option B : remplacement du module HTTP 4 par un appel Managed Agents
5. Le test plan
6. La procédure de rollback

Il s'articule avec :
- `agents/whatsapp-vlbh-agent.json` (v0.2, tool retiré, système prompt conversationnel)
- `docs/whatsapp-agent-module4-blueprint.json` (snippet module HTTP 4 prêt à coller)
- `docs/watchdog-make-infra.md` (règles API Make découvertes lors du Watchdog)

---

## 1. Minimisation de la fuite clé API Anthropic sans révocation

> La clé `sk-ant-api03-2TXpSYfha-Ul50dREMu1TlI...` est présente en clair dans
> le blueprint actuel du module HTTP 4. Patrick a choisi de ne pas révoquer
> immédiatement (périmètre de sécurité mono-utilisateur assumé). Cette section
> liste les options de mitigation possibles.

### 1.1 Sources d'exposition actuelles

La clé est présente dans au moins ces endroits :

1. **Blueprint Make** — module HTTP 4 en dur dans les headers, visible à tout export JSON du scénario
2. **Logs d'exécution Make** — chaque run passé contient les headers envoyés, conservés selon la rétention Make (~15-30 jours selon plan)
3. **Backups Make** — Make garde des snapshots internes non purgeables par l'utilisateur
4. **Contexte de conversations IA** — cette conversation Claude Code et la session Claude.ai où la clé a transité
5. **Presse-papiers / historique terminal** — si la clé a été copiée-collée à un moment

### 1.2 Options de minimisation (sans révocation immédiate)

#### Option 1 — Team Variable Make + purge logs *(recommandée minimum)*

**Action** :
1. Make → Team Settings (team `630342`) → Team Variables → Add
2. Name: `ANTHROPIC_API_KEY` · Type: `secret` · Value: coller la clé
3. Éditer le module HTTP 4 : remplacer le header `x-api-key` en dur par `{{getVariable("ANTHROPIC_API_KEY")}}`
4. Sauvegarder le scénario
5. Make → scénario #8944541 → History → Purger l'historique d'exécutions

**Contraintes techniques** :
- Les Team Variables `secret` sont masquées dans le blueprint exporté (seul le nom apparaît)
- La purge d'historique ne supprime **pas** les backups internes de Make (cycle interne à Make, non documenté publiquement)
- Tout export blueprint **déjà téléchargé** contient toujours la clé — à supprimer manuellement

**Bénéfice** : la clé disparaît du blueprint exporté et des logs futurs. Les logs passés déjà purgés de l'UI sont inaccessibles en pratique sans support Make.

**Limite** : la clé reste pleinement valide et full-access sur le workspace Anthropic. Si elle est capturée par un autre canal (IA, capture d'écran, backup cloud), elle est exploitable sans restriction.

**Effort** : ~15 minutes.

#### Option 2 — Restriction IP côté Anthropic console

**Action** :
1. console.anthropic.com → Settings → API Keys → sélectionner la clé → Security
2. Activer la restriction d'IP si la fonctionnalité est proposée
3. Ajouter les IPs de sortie Make pour la région EU2 (à récupérer dans la documentation Make : `https://www.make.com/en/help/eu2-region` ou support)

**Contraintes techniques** :
- **Vérification nécessaire côté console** : à la dernière connaissance disponible, Anthropic ne proposait pas encore de restriction IP par clé. La fonctionnalité peut avoir été ajoutée avec le bêta Managed Agents — à confirmer en allant sur la console.
- Si non disponible → option **inapplicable**, passer à l'Option 1 ou 4.
- Si disponible → Make peut changer ses IPs de sortie sans préavis → risque de breaking du scénario si la whitelist n'est pas mise à jour à temps.

**Bénéfice** : clé inutilisable en dehors des IPs Make, même si capturée ailleurs.

**Limite** : dépend d'une feature peut-être indisponible.

**Effort** : ~10 minutes si feature dispo.

#### Option 3 — Budget + alertes Anthropic

**Action** :
1. console.anthropic.com → Settings → Usage limits
2. Définir un budget mensuel strict pour le workspace SVLBH (ex: 50 $/mois)
3. Activer les alertes email à 50 % / 80 % / 100 %

**Contraintes techniques** :
- Ne prévient **pas** une fuite : détecte uniquement l'abus *après* qu'il a commencé
- Granularité limitée au workspace, pas à la clé individuelle
- Faux positifs possibles les jours de forte activité légitime (ex: onboarding d'une nouvelle patiente sur WhatsApp)

**Bénéfice** : mitigation asymétrique — on voit si un tiers consomme la clé même sans savoir d'où.

**Effort** : ~5 minutes.

#### Option 4 — Rotation douce avec deux clés en parallèle

**Action** :
1. Créer une **nouvelle** clé Anthropic `SVLBH-Make-Router` (distincte de celle exposée)
2. La placer dans la Team Variable Make (Option 1)
3. Laisser l'ancienne clé exposée active 7-14 jours pour permettre le debug / rollback
4. Après confirmation que tous les runs passent par la nouvelle clé → **révoquer** l'ancienne sur la console

**Contraintes techniques** :
- C'est formellement une révocation *différée* — donc pas strictement « sans révoquer », mais permet une transition sans interruption de service
- Patrick doit se rappeler de révoquer l'ancienne à échéance (risque d'oubli → l'exposition persiste)
- Les deux clés consomment sur le même budget workspace pendant la transition

**Bénéfice** : risque résiduel ramené à zéro à terme, sans coupure.

**Effort** : ~30 minutes + rappel à 7-14 jours.

#### Option 5 — Statu quo (acceptation du risque)

**Action** : ne rien faire.

**Contraintes techniques** : aucune mitigation active. La clé reste pleinement opérationnelle et exposée dans le blueprint et les logs actuels.

**Limite** : si un jour la clé fuite par un autre canal (partage blueprint, capture d'écran diffusée, compromission du poste), il n'y a aucun moyen de détecter ou bloquer l'usage en dehors de la facturation Anthropic.

**Recommandation minimum si choisi** : activer **au moins l'Option 3** (budget + alertes) pour avoir un filet de détection asymétrique.

### 1.3 Tableau de synthèse

| Option | Effort | Interruption service | Risque résiduel | Cumulable |
|---|---|---|---|---|
| 1 — Team Variable + purge logs | 15 min | 0 | Moyen (clé valide mais invisible dans blueprint) | ✅ |
| 2 — Restriction IP | 10 min si dispo | 0 | Faible si dispo | ✅ |
| 3 — Budget + alertes | 5 min | 0 | Haut (détection post-fuite uniquement) | ✅ |
| 4 — Rotation douce 2 clés | 30 min + rappel | 0 | Nul après révocation différée | partiel |
| 5 — Statu quo | 0 min | 0 | Haut (exposition permanente) | — |

### 1.4 Recommandation concrète pour Patrick

**Combo minimum raisonnable** : **Option 1 + Option 3**.

- Option 1 sort la clé du blueprint et des logs futurs (95 % de la surface d'exposition courante)
- Option 3 pose un garde-fou financier pour détecter un usage anormal

**Coût total** : 20 minutes, zéro interruption, zéro révocation.

Si Patrick veut un cran de plus sans révocation immédiate : ajouter **Option 4** (rotation douce sur 14 jours) qui ramène le risque à zéro en fin de transition. Et c'est terminé.

---

## 2. Fix bug CT — Normalisation du numéro de téléphone

### 2.1 Diagnostic

Dans l'état actuel du scénario, **deux modules** utilisent le numéro de l'expéditeur mais **l'un le normalise et pas l'autre** :

- **Module 8** (lookup bridge Go) :
  ```
  replace(1.from; "@s.whatsapp.net"; "")  →  "+33612345678"
  ```
  ✅ Correct — strip du suffixe `@s.whatsapp.net`.

- **Module 2** (lookup svlbh-v2) :
  ```
  CT-{{1.from}}  →  "CT-+33612345678@s.whatsapp.net"
  ```
  ❌ **Bug** — le suffixe n'est pas strippé, la clé n'existe pas dans svlbh-v2 (qui contient `CT-+33612345678` sans suffixe), `datastore:GetRecord` retourne vide, le routing part en erreur.

**Sources** :
- Les messages WA classiques arrivent avec le suffixe `@s.whatsapp.net`
- Les comptes business ou récemment créés utilisent `@lid` (identifiant masqué Meta)
- Les groupes utilisent `@g.us` (non pertinent pour un router 1-to-1 mais à connaître)

### 2.2 Fix minimal en place

**Éditer le module 2** (datastore lookup svlbh-v2) → remplacer la formule de clé :

Avant :
```
CT-{{1.from}}
```

Après :
```
CT-{{replace(replace(1.from; "@s.whatsapp.net"; ""); "@lid"; "")}}
```

Ce double `replace` strip les deux suffixes WA possibles. La clé devient alors exactement `CT-+33612345678`, compatible avec le format de svlbh-v2.

### 2.3 Fix recommandé (DRY — single source of truth)

Pour éviter que le bug ne réapparaisse dans un autre module qui utiliserait `1.from` directement, **introduire un module `util:SetVariable` en tout début de scénario** (juste après le trigger `gateway:CustomWebHook`, nouveau module #1b) :

```
name: senderPhone
value: + + {{replace(replace(1.from; "@s.whatsapp.net"; ""); "@lid"; "")}}
```

Attention : `1.from` chez WABA contient déjà le `+` ou pas selon la config Meta. Vérifier avec un run réel ; si `1.from = "33612345678@s.whatsapp.net"` sans `+`, alors l'expression devient :
```
"+" + replace(replace(1.from; "@s.whatsapp.net"; ""); "@lid"; "")
```

Ensuite, **tous les modules en aval** utilisent `{{senderPhone}}` à la place de `{{1.from}}` :
- Module 2 (svlbh-v2 lookup) : clé = `CT-{{senderPhone}}`
- Module 8 (bridge Go lookup) : `{{senderPhone}}`
- Module HTTP 4 (appel agent) : `{{senderPhone}}` dans le user message
- Module 10 (nouveau contact) : `{{senderPhone}}` dans le record

**Bénéfice** : single source of truth, impossible de dériver la normalisation dans un module isolé.

⚠️ Attention : le module `util:SetVariables` (pluriel) peut déclencher un `BundleValidationError` dans certains cas API-created (voir `docs/watchdog-make-infra.md` §Key Technical Decisions). Si tu as ce bug, utilise `util:SetVariable` (singulier) ou garde la formule inline dans chaque module au lieu de factoriser.

### 2.4 Vérification

Après le fix, tester avec un numéro connu du datastore svlbh-v2 :

1. Envoyer un WA test depuis un téléphone dont le numéro est présent dans svlbh-v2
2. Vérifier dans Make → History que le module 2 retourne bien un record (pas vide)
3. Vérifier que le routing aval (vers l'agent ou vers la branche Nouveau contact) est cohérent avec le segment attendu

---

## 3. Fix Route « Nouveau contact » — WebhookRespond manquant

### 3.1 Diagnostic

Le module 10 enregistre un nouveau contact dans le datastore `#157329` mais **n'appelle jamais** `gateway:WebhookRespond`. Conséquence :

- Le bridge Go fait un POST synchrone vers le webhook `4000349`
- Il attend une réponse HTTP pour savoir quoi renvoyer à WhatsApp
- Make traite les modules 1 → 2 → 10 sans jamais appeler `WebhookRespond`
- Le scénario Make termine « successfully » (tous les modules OK)
- Le bridge Go reste bloqué en lecture sur la socket jusqu'à son `http.Client.Timeout` (30 s ou 60 s selon sa config)
- **Côté patiente** : elle écrit, aucune réponse, elle ré-écrit, nouveau timeout, etc.

### 3.2 Fix

Ajouter un module `gateway:WebhookRespond` **après** le module 10, avec un body JSON minimum :

**Option A — Réponse vide silencieuse** (le bridge Go décide quoi en faire, probablement ne rien envoyer à WhatsApp) :
```json
{
  "status": 200,
  "body": {
    "type": "new_contact_registered",
    "reply": "",
    "meta": {
      "phone": "{{senderPhone}}",
      "registered_at": "{{now}}"
    }
  }
}
```

**Option B — Accueil automatique** (plus sympa pour le premier contact patient) :
```json
{
  "status": 200,
  "body": {
    "type": "new_contact_registered",
    "reply": "Bonjour, merci pour votre message ! Patrick (Digital Shaman Lab) va prendre connaissance de votre demande et vous répondra dès que possible. En attendant, vous pouvez consulter https://digitalshaman.lab ou prendre un premier échange via [lien discovery].",
    "meta": {
      "phone": "{{senderPhone}}",
      "registered_at": "{{now}}"
    }
  }
}
```

Le bridge Go lit `body.reply` : si non vide, il envoie le texte à WhatsApp via WABA. Si vide, il ferme la connexion proprement sans message.

### 3.3 Alternative — Router vers l'agent même pour Nouveau contact

Si tu préfères que l'agent réponde aussi aux nouveaux contacts (avec le segment `nouveau_contact` défini dans le system prompt v0.2), il suffit de **ne plus brancher le module 10 sur une route isolée** : router tout vers le module HTTP 4 (appel agent) avec un `segment` manquant ou mis à `"nouveau_contact"` dans le user message.

Dans ce cas :
- Module 2 retourne vide
- Module 10 enregistre le nouveau contact (persistance)
- **En parallèle** (router Make), le flux continue vers module HTTP 4 avec `{{ifempty(2.segment; "nouveau_contact")}}`
- L'agent répond selon les instructions du segment `nouveau_contact` du system prompt v0.2
- Un seul `WebhookRespond` final après le parsing de la réponse de l'agent

**Bénéfice** : la patiente reçoit une vraie réponse contextualisée dès le premier message, et le profil est enregistré en parallèle.

**Contrainte** : le premier message ne bénéficie pas encore de la mémoire de session agent (elle se construit à partir de ce message).

---

## 4. Migration Option B — Remplacement du module HTTP 4

### 4.1 Pourquoi Option B plutôt que Option A

**Option A** envisagée initialement : créer un nouveau scénario `WA → managed-agents → WA` et désactiver #8944541.

**Option B** retenue : modifier in-place le scénario existant, ne remplacer que le module HTTP 4.

| Critère | Option A (nouveau scénario) | Option B (modif in-place) |
|---|---|---|
| Changement côté bridge Go | URL webhook à mettre à jour | Aucun (hook 4000349 inchangé) |
| Changement côté Meta WABA | Aucun (Meta → bridge Go → Make) | Aucun |
| Routing segment existant | À recréer intégralement | Préservé (modules 2, 8, 10) |
| Fix bug CT | À refaire | Corrigé en place (section 2) |
| Fix Nouveau contact | À refaire | Corrigé en place (section 3) |
| Surface de test | Nouveau scénario complet | Uniquement le module 4 |
| Rollback | Désactiver nouveau + réactiver ancien | Revert du seul module 4 |
| Risque de régression | Moyen (tout est nouveau) | Faible (un seul module change) |

Option B gagne sur tous les axes dans ce cas.

### 4.2 Prérequis avant le changement

1. **Section 1 appliquée** — Team Variable `ANTHROPIC_API_KEY` créée dans Make et renseignée (au moins Option 1 du plan de minimisation)
2. **Section 2 appliquée** — bug CT corrigé dans le module 2 (senderPhone normalisé)
3. **Section 3 appliquée** — `WebhookRespond` ajouté après module 10
4. **Agent créé côté Anthropic** :
   ```bash
   export ANTHROPIC_API_KEY=sk-ant-...
   swift Scripts/sync_agents.swift --dry-run
   swift Scripts/sync_agents.swift whatsapp-vlbh-agent
   ```
   Cela crée l'agent et remplit `agents/.lockfile.json` avec l'ID retourné (format `agent_01XXXXXXXX...`).
5. **Team Variable agent ID** — dans Make → Team Variables → créer :
   ```
   ANTHROPIC_AGENT_WHATSAPP_VLBH = <id du lockfile>
   ```
6. **Accès bêta Managed Agents confirmé** sur le compte Anthropic — header `managed-agents-2026-04-01` accepté par l'API. Vérifier via un dry-run de `sync_agents.swift`.

### 4.3 Diff détaillé du module HTTP 4

**Avant** (blueprint actuel, schématisé — appel direct `messages` ou `complete` avec clé en clair) :

```jsonc
{
  "id": 4,
  "module": "http:MakeRequest",
  "version": 4,
  "mapper": {
    "url": "https://api.anthropic.com/v1/messages",
    "method": "post",
    "headers": [
      { "name": "x-api-key", "value": "sk-ant-api03-2TXpSYfha-..." },  // ❌ en clair
      { "name": "anthropic-version", "value": "2023-06-01" },
      { "name": "Content-Type", "value": "application/json" }
    ],
    "inputMethod": "jsonString",
    "jsonStringBodyContent": "{ \"model\": \"claude-...\", \"messages\": [...] }",
    "parseResponse": true
  }
}
```

**Après** (voir `docs/whatsapp-agent-module4-blueprint.json` pour la version complète copiable) :

```jsonc
{
  "id": 4,
  "module": "http:MakeRequest",
  "version": 4,
  "mapper": {
    "url": "https://api.anthropic.com/v1/sessions",   // ← changé
    "method": "post",
    "headers": [
      { "name": "Content-Type", "value": "application/json" },
      { "name": "x-api-key", "value": "{{getVariable(\"ANTHROPIC_API_KEY\")}}" },  // ← variable
      { "name": "anthropic-version", "value": "2023-06-01" },
      { "name": "anthropic-beta", "value": "managed-agents-2026-04-01" },         // ← nouveau
      { "name": "User-Agent", "value": "Mozilla/5.0 (compatible; SVLBHMakeRouter/1.0)" }
    ],
    "inputMethod": "jsonString",
    "jsonStringBodyContent": "{ \"agent_id\": \"{{getVariable(\\\"ANTHROPIC_AGENT_WHATSAPP_VLBH\\\")}}\", \"messages\": [ { \"role\": \"user\", \"content\": \"PROFIL PATIENTE ...\\n\\nMESSAGE ENTRANT:\\n{{1.text}}\" } ] }",
    "parseResponse": true,
    "timeout": 60
  }
}
```

### 4.4 Construction du user message — contexte profil

Le user message envoyé à l'agent doit **embedder le profil** looked-up par le module 2 pour que l'agent n'ait pas à faire de round-trip. Format exact (conforme au system prompt v0.2) :

```
PROFIL PATIENTE (lookup svlbh-v2 #155674):
- phone: {{senderPhone}}
- segment: {{ifempty(2.segment; "nouveau_contact")}}
- display_name: "{{ifempty(2.display_name; "")}}"
- last_seen: "{{ifempty(2.last_seen; "")}}"
- notes: "{{ifempty(2.notes; "")}}"

MESSAGE ENTRANT:
{{1.text}}
```

**Mapping des champs** (à adapter si les noms réels côté svlbh-v2 diffèrent) :

| Placeholder Make | Source | Fallback |
|---|---|---|
| `{{senderPhone}}` | Variable Make définie en §2.3 | — (requis) |
| `{{2.segment}}` | datastore GetRecord svlbh-v2 — champ `segment` | `"nouveau_contact"` |
| `{{2.display_name}}` | svlbh-v2 — champ `display_name` ou équivalent | `""` |
| `{{2.last_seen}}` | svlbh-v2 — champ `last_seen` ou timestamp | `""` |
| `{{2.notes}}` | svlbh-v2 — champ notes libre | `""` |
| `{{1.text}}` | trigger `gateway:CustomWebHook` — texte brut du message | — (requis) |

⚠️ Les guillemets et retours à la ligne dans `jsonStringBodyContent` doivent être échappés selon la syntaxe Make/JSON. Voir `docs/whatsapp-agent-module4-blueprint.json` qui a le JSON escape complet prêt à coller.

### 4.5 Parsing de la réponse de l'agent

L'agent retourne un objet Anthropic dont le contenu texte est le JSON produit par le system prompt v0.2 :

```json
{
  "id": "session_01ABC...",
  "type": "session",
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "{\"reply\": \"Bonjour Marie...\", \"segment_detected\": \"patient_actif\", \"alert_patrick\": false, ...}"
    }
  ]
}
```

**Chemin d'accès côté Make** : `4.body.content[0].text`

C'est une **string JSON** qu'il faut parser avec un second module `util:ParseJSON` (nouveau module #5 ou réaffecté) :

```jsonc
{
  "id": 5,
  "module": "util:ParseJSON",
  "mapper": {
    "type": "agent_response_v0_2",
    "json": "{{4.body.content[0].text}}"
  }
}
```

Après parsing, les champs utilisables en aval :

| Champ | Type | Utilisation |
|---|---|---|
| `5.reply` | String | Envoi WhatsApp via `WebhookRespond` |
| `5.segment_detected` | String | Log / analytics (peut différer du segment lookup) |
| `5.alert_patrick` | Boolean | Branche conditionnelle vers notification Patrick |
| `5.alert_reason` | String\|null | Contenu de la notification Patrick si alert |
| `5.recommended_follow_up` | String\|null | Log / analytics, pas d'action automatique |

### 4.6 Branches en aval

**Branche principale — réponse WhatsApp** (toujours exécutée) :

```jsonc
{
  "id": 6,
  "module": "gateway:WebhookRespond",
  "mapper": {
    "status": 200,
    "body": "{\"reply\": \"{{5.reply}}\", \"meta\": {\"segment\": \"{{5.segment_detected}}\"}}"
  }
}
```

**Branche conditionnelle — alerte Patrick** (exécutée si `5.alert_patrick == true`) :

Ajouter un `flow:Router` après le module 5, condition : `{{5.alert_patrick}} = true`.

Sur la branche true, un module `http:MakeRequest` qui POST vers le webhook WA Router existant `lllo1g6btuv4e3qjt4qvpj8fjwyd663s` avec :

```json
{
  "message": "🚨 Alert patiente {{senderPhone}} ({{5.segment_detected}}): {{5.alert_reason}}\n\nMessage reçu: {{1.text}}\n\nRéponse auto envoyée: {{5.reply}}"
}
```

Patrick reçoit alors la notification WhatsApp via sa propre mailbox d'envoi (celle du watchdog), tout en laissant la patiente recevoir la réponse automatique rassurante.

### 4.7 Retirer l'ancien module HTTP 4 d'un coup sec ou progressivement

**Approche 1 — Remplacement direct** : éditer le module 4 existant, remplacer tous les champs en place. Activer immédiatement. Simple mais pas de parallèle testing.

**Approche 2 — Duplication puis switch** : dupliquer le module 4, le renommer en `4_legacy`, créer un nouveau `4_agent` à côté, router via un `flow:Router` conditionné par une Team Variable `WHATSAPP_AGENT_ENABLED = true/false`. Permet de basculer instantanément sans rééditer. Plus sûr pour une feature en bêta.

**Reco** : Approche 2 pour les 7-14 premiers jours, puis suppression du module `4_legacy` une fois la confiance acquise.

---

## 5. Test plan

### 5.1 Environnement de test

Idéalement, dupliquer le scénario #8944541 en `#8944541-test` pour les premiers runs, en pointant sur un second webhook `gateway:CustomWebHook` (nouvel hook ID). Le bridge Go peut ensuite être switché temporairement vers ce hook via une variable d'environnement.

Si la duplication est trop lourde, utiliser un numéro WhatsApp de test dédié (second numéro WABA ou un compte Meta sandbox) qui route vers le même scénario — et logger chaque run en mode verbose.

### 5.2 Cas de test obligatoires

| # | Scénario | Input | Résultat attendu |
|---|---|---|---|
| T1 | `patient_actif` connu | Message simple depuis un numéro présent dans svlbh-v2 avec `segment = patient_actif` | `5.reply` cohérent avec le ton patient_actif, `alert_patrick = false` |
| T2 | `lead` connu | Message depuis un numéro présent avec `segment = lead` | Réponse empathique + lien discovery, jamais de contenu thérapeutique |
| T3 | `praticien` connu | Message depuis un numéro présent avec `segment = praticien` | Ton confraternel, aide technique |
| T4 | Nouveau contact (bug #3 corrigé) | Message depuis un numéro inconnu | Reçoit la réponse d'accueil, nouveau record créé dans `#157329`, aucun timeout bridge Go |
| T5 | Numéro avec suffixe `@lid` (bug #1 corrigé) | Simuler un `1.from = "+33612345678@lid"` | Module 2 trouve le record svlbh-v2, pas de fallback nouveau_contact erroné |
| T6 | Symptôme aigu | Message « j'ai mal au ventre depuis ce matin, c'est intense » (patiente connue endo/ferritine) | `alert_patrick = true`, `alert_reason` non vide, branche conditionnelle #7 POST sur WA Router, patiente reçoit réponse rassurante |
| T7 | Mémoire de session | Envoyer 3 messages successifs à 5 min d'intervalle depuis le même numéro, le 3e faisant référence au 1er | Agent répond en faisant le lien (mémoire cross-message persistante) |
| T8 | Parsing robuste | Provoquer un agent qui retourne du texte avec fences ```json``` ou du JSON mal formé | Le parseur extrait le JSON ou logue une erreur explicite, pas de crash du scénario |
| T9 | Erreur 403 (bêta non activée) | Désactiver temporairement le header `anthropic-beta` | Scénario log HTTP 403, rollback automatique ou mode dégradé |
| T10 | Variable Make vide | Vider temporairement `ANTHROPIC_API_KEY` | HTTP 401, pas de crash, erreur remontée dans les logs Make |

### 5.3 Vérifications post-déploiement (première semaine)

À consulter quotidiennement dans Make → scénario #8944541 → History :

1. **Taux d'erreur** doit tomber sous 1 % (vs 108 erreurs historiques)
2. **Distribution des segments détectés** (via logs `5.segment_detected`) — cohérente avec la répartition attendue
3. **Alertes Patrick déclenchées** — vérifier qu'elles correspondent à de vrais cas (pas de faux positifs majeurs)
4. **Latence** du module HTTP 4 — mesurer p50, p95. Cible : p50 < 3 s, p95 < 8 s
5. **Consommation Anthropic** — dashboard Usage, comparer au budget mensuel défini en §1.4
6. **Aucune erreur parse** sur le module `util:ParseJSON` (sinon l'agent dévie du format JSON strict — ajuster le prompt)

### 5.4 Tests côté iOS — non concernés

Rappel : l'iPad n'est **pas** impliqué dans cette migration. `whatsapp-vlbh-agent` est appelé exclusivement par Make. Les tests iOS concernent uniquement `hdom-session-agent` (Phase 1) et `passeport-ratio-agent` (Phase 2), cf. CLAUDE.md et `agents/README.md`.

---

## 6. Rollback

### 6.1 Rollback rapide (urgence — < 1 min)

Si l'agent dévie gravement ou si une patiente reçoit une réponse inappropriée :

**Approche 1 (si Duplication retenue en §4.7)** :
1. Make → Team Variables → `WHATSAPP_AGENT_ENABLED` → passer à `false`
2. Le `flow:Router` en amont bascule vers le module `4_legacy`
3. Les runs en cours finissent sur l'ancien flux, les nouveaux repartent sur legacy
4. **Effet immédiat** sur le message suivant

**Approche 2 (si remplacement direct retenu)** :
1. Make → scénario → Undo (si la modification du module 4 est récente et qu'aucun autre commit scénario n'a eu lieu)
2. Sinon → importer un backup du blueprint pré-migration (Patrick doit **exporter le blueprint avant toute modif** et le garder hors-ligne)
3. Désactiver temporairement le scénario `#8944541` le temps du revert

### 6.2 Rollback ordonné (< 15 min)

Si le problème n'est pas urgent mais nécessite un retour à l'état antérieur :

1. Exporter le scénario actuel (pour garder une trace du dernier état cassé)
2. Restaurer le blueprint pré-migration depuis le backup
3. Réactiver les Team Variables originales (si d'autres ont été supprimées)
4. Faire un run de test manuel avec un message connu pour valider le retour à l'état nominal
5. Documenter la cause du rollback dans `docs/whatsapp-router-migration.md` (nouvelle section « Incidents »)

### 6.3 Rollback côté agent Anthropic

Si le problème vient du system prompt lui-même (et non du routing Make) :

1. Éditer `agents/whatsapp-vlbh-agent.json` pour revenir à une version antérieure
2. `swift Scripts/sync_agents.swift whatsapp-vlbh-agent` → PATCH l'agent côté Anthropic
3. Le PATCH est effectif immédiatement pour toutes les sessions futures
4. Les sessions en cours (mémoire persistante) continuent avec l'ancien prompt jusqu'à leur fermeture
5. Si besoin d'un reset total des sessions : supprimer l'agent et le recréer (nouvel ID → mettre à jour la Team Variable Make `ANTHROPIC_AGENT_WHATSAPP_VLBH`)

### 6.4 Rollback combiné (nucléaire)

Dernier recours si tout est cassé :

1. Make → désactiver le scénario #8944541
2. Bridge Go → passer en mode « maintenance », renvoyer un message fixe à toutes les patientes : « Service temporairement indisponible, Patrick va prendre connaissance de votre message et vous répondra dès que possible »
3. Anthropic → révoquer la clé API si une fuite est suspectée
4. Restaurer le blueprint pré-migration
5. Créer une nouvelle clé, une nouvelle Team Variable
6. Réactiver progressivement

---

## Annexe — Checklist d'exécution

À suivre dans l'ordre lors de l'opération réelle :

- [ ] **Backup** du blueprint actuel de #8944541 (export JSON → fichier local hors-ligne)
- [ ] **§1.4** — Team Variable `ANTHROPIC_API_KEY` créée + budget/alertes Anthropic activés
- [ ] **§2.2 ou §2.3** — Bug CT corrigé (module 2 + idéalement senderPhone factorisé)
- [ ] **§3.2** — `WebhookRespond` ajouté après module 10
- [ ] Run de test avec numéro connu → valide §2 et §3 sans toucher encore au module 4
- [ ] **§4.2** — Agent créé via `sync_agents.swift whatsapp-vlbh-agent`
- [ ] **§4.2** — Team Variable `ANTHROPIC_AGENT_WHATSAPP_VLBH` créée avec l'ID retourné
- [ ] **§4.3 à §4.6** — Module HTTP 4 remplacé (Approche 2 duplication recommandée)
- [ ] **§5.2** — Exécution des cas T1 à T10
- [ ] **§5.3** — Monitoring 7 jours
- [ ] Si tout OK : suppression du module `4_legacy`
- [ ] Désactivation du scénario Make `SVLBH Passeport Ratio 4D #8999937` (remplacé par `passeport-ratio-agent` iOS, Phase 2)
