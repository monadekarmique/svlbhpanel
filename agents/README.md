# SVLBH Managed Agents

Définitions versionnées des 3 Managed Agents Anthropic utilisés par SVLBH Panel.

## Vue d'ensemble

| Slug | Caller | Remplace | Skills chargés |
|---|---|---|---|
| `hdom-session-agent` | iOS direct | Décodage manuel en séance | `hdom-decoder`, `sommeil-troubles-nuit`, `endometriose-ferritine` |
| `passeport-ratio-agent` | iOS direct | Make scenario #8999937 (81% erreurs) | — |
| `whatsapp-vlbh-agent` | Make proxy | Router WhatsApp Make #8944541 (108 erreurs) | — |

**Caller** :
- `ios-direct` : l'iPad appelle directement `https://api.anthropic.com/v1/sessions` via `AnthropicClient.swift`. La clé API vit dans `secrets.xcconfig` (non versionné).
- `make-proxy` : l'agent est appelé par un scénario Make dédié (WhatsApp entrant). L'iPad ne voit rien de ce flux.

## Format des fichiers `*.json`

Source de vérité **locale** des agents. Le script `Scripts/sync_agents.swift` lit ces fichiers et les traduit en appels `POST /v1/agents` ou `PATCH /v1/agents/{id}` contre l'API Anthropic.

Schéma (informel) :
```json
{
  "slug": "string — identifiant stable local",
  "name": "string — nom affiché côté Anthropic",
  "description": "string — description longue",
  "model": "string — ex: claude-opus-4-6",
  "system_prompt": "string",
  "skills": ["string"],
  "tools": [{"name": ..., "type": "http_webhook", "url": ..., "input_schema": {...}}],
  "mcp_servers": [],
  "beta_header": "managed-agents-2026-04-01",
  "caller": "ios-direct" | "make-proxy",
  "notes": "string"
}
```

Le mapping exact vers le payload API Anthropic `/v1/agents` se fait dans `sync_agents.swift`. Si Anthropic change le schéma, ajuster uniquement le script — pas les JSON locaux.

## Lockfile `.lockfile.json`

Mappe chaque `slug` local vers l'`agent_id` retourné par Anthropic après création :

```json
{
  "version": 1,
  "agents": {
    "hdom-session-agent": {
      "id": "agent_01ABC...",
      "last_sync": "2026-04-10T12:34:56Z",
      "content_hash": "sha256:..."
    }
  }
}
```

**Versionné dans Git** pour que toutes les machines de dev partagent les mêmes IDs d'agents. Si deux devs patchent un agent en même temps → conflit Git classique sur le lockfile, à résoudre manuellement.

## Workflow de synchronisation

```bash
# 1. Éditer le JSON d'un agent
vi agents/hdom-session-agent.json

# 2. Lancer la sync (requiert ANTHROPIC_API_KEY dans l'env)
export ANTHROPIC_API_KEY=sk-ant-...
swift Scripts/sync_agents.swift

# 3. Commit le lockfile mis à jour
git add agents/.lockfile.json
git commit -m "agents: sync hdom-session-agent"
```

Le script :
1. Lit chaque `agents/*.json` (sauf `.lockfile.json`).
2. Calcule un hash SHA-256 du contenu.
3. Compare avec `content_hash` dans le lockfile.
4. Si absent du lockfile → `POST /v1/agents` → ajoute l'ID au lockfile.
5. Si hash différent → `PATCH /v1/agents/{id}` → met à jour le hash.
6. Si hash identique → skip.

## Skills

Les SKILL.md consommés par `hdom-session-agent` vivent dans `"SVLBH Panel"/Skills/` (non versionné, voir `.gitignore:50`). Des **squelettes de travail** sont versionnés dans `docs/skills-templates/` — à recopier dans `SVLBH Panel/Skills/<slug>/SKILL.md`, compléter, puis uploader via l'endpoint Skills d'Anthropic.

Workflow skill :
```bash
mkdir -p "SVLBH Panel/Skills/hdom-decoder"
cp docs/skills-templates/hdom-decoder.SKILL.md "SVLBH Panel/Skills/hdom-decoder/SKILL.md"
# Éditer et compléter les sections [À REMPLIR par Patrick]
```

L'upload des skills vers Anthropic se fait manuellement via la console ou via un futur `Scripts/upload_skills.swift` (non implémenté en Phase 0).

## Webhooks Make à créer avant Phase 2

- **`fetch_svlbh_ref_21s`** (consommé par `passeport-ratio-agent`) : webhook Make qui reçoit `{ "country_code": "FR" }` et retourne la row correspondante du data store #157532 (svlbh-ref-21s). URL à renseigner dans `passeport-ratio-agent.json` (champ `tools[0].url`, actuellement `TBD_WEBHOOK_REF21S_URL`).
- **`fetch_svlbh_v2_profile`** (consommé par `whatsapp-vlbh-agent`) : webhook Make qui reçoit `{ "phone_e164": "+336..." }` et retourne le profil + segment depuis le data store #155674 (svlbh-v2). URL à renseigner dans `whatsapp-vlbh-agent.json`.

Tant que ces URLs sont `TBD_*`, `sync_agents.swift` refuse de pousser l'agent correspondant (safeguard).

## Accès bêta

Tous les appels incluent le header `anthropic-beta: managed-agents-2026-04-01`. Le compte Anthropic utilisé doit avoir l'accès à la bêta publique Managed Agents (disponible depuis le 8/04/2026). En cas de `403`, vérifier la console Anthropic → Settings → Beta features.

## Coût attendu

Coûts API standards + **0,08 $ par session-heure active** (facturation Anthropic sur les Managed Agents). Une session est "active" tant qu'elle reçoit des messages ; elle est fermée automatiquement après inactivité. Pour limiter les coûts, `AnthropicClient.swift` ferme explicitement les sessions quand le flux iOS est terminé (voir méthode `closeSession(sessionId:)`).
