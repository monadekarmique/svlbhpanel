# WhatsApp Bridges SVLBH — Documentation globale

> 🛑 **LIRE AVANT TOUTE ACTION.** Ces bridges tournent en production pour SVLBH.
> Si tu casses un bridge, tu casses la communication patients ↔ praticiennes.

## ⚠️ Règles absolues pour Claude / Cowork / agents

### ❌ NE PAS FAIRE

1. **Ne PAS installer Docker.** Les bridges tournent en **binaire Go natif** sur ce Mac. Docker n'est utilisé que pour le déploiement prod distant (serveur svlbhgroup.net). Le Dockerfile et le docker-compose.yaml présents dans chaque dossier sont **décoratifs** en local.
2. **Ne PAS lancer `docker compose up`** — cela échouera (Docker non installé) et, s'il est installé plus tard, cela créera un **double du bridge** → session WhatsApp invalidée, QR code à rescanner, perte de messages.
3. **Ne PAS tuer un processus `whatsapp-bridge`** sans vérifier `curl http://localhost:<port>/api/health` d'abord. Si `connected:true`, le bridge est sain — **ne pas le redémarrer**.
4. **Ne PAS recompiler le binaire Go** (`go build`) sauf demande explicite de Patrick. Le binaire actuel fonctionne, la chaîne de build Go peut introduire des régressions whatsmeow.
5. **Ne PAS rescanner le QR code** sauf si `connected:false` ET `reconnect_errs>5` pendant >10min. Un rescan **casse toutes les sessions linked devices** précédentes.
6. **Ne PAS toucher aux fichiers `store/*.db`** (SQLite) — contiennent les clés de session WhatsApp. Si supprimés → reconnexion impossible sans QR.

### ✅ À FAIRE

1. **Vérifier avant d'agir :** `curl http://localhost:<port>/api/health` avant toute intervention.
2. **Si demande "connecte le bridge X"** : exécuter d'abord le health check. Si UP, **répondre "déjà connecté"** — ne pas relancer.
3. **Pour lancer manuellement un bridge down** : `cd /Users/patricktest/whatsapp-bridges/zN-<phone>/whatsapp-bridge && ./whatsapp-bridge &` (binaire déjà compilé, PAS de `go build`).
4. **Consulter les logs** : `tail -f whatsapp-bridge/bridge.log` (stdout) et `bridge.err.log` (stderr).

---

## 📞 Inventaire des 3 bridges

| Bridge | Téléphone | Port | Zone métier | Host distant |
|--------|-----------|------|-------------|--------------|
| **z1** | +41 79 813 19 26 | **8080** | visiteuses (prospects, onboarding) | z1.svlbhgroup.net |
| **z2** | +41 79 216 82 00 | **8081** | formation-non-pro (testeuses, ateliers) | z2.svlbhgroup.net |
| **z3** | +41 79 913 82 00 | **8082** | certifiees-pro (praticiennes MyShamanFamily) | z3.svlbhgroup.net |

**Structure de dossiers :**
```
/Users/patricktest/whatsapp-bridges/
├── CLAUDE.md                   ← tu lis ce fichier
├── z1-41798131926/             ← bridge visiteuses
│   ├── .bridge.env             ← config (BRIDGE_ID, PORT, PHONE, HOST, ZONE)
│   ├── whatsapp-bridge/
│   │   ├── whatsapp-bridge     ← binaire Go compilé (29M, exécutable)
│   │   ├── bridge.log          ← stdout live
│   │   ├── bridge.err.log      ← stderr
│   │   └── store/              ← SQLite (messages.db, whatsapp.db) — NE PAS SUPPRIMER
│   ├── whatsapp-mcp-server/    ← serveur MCP Python (Gradio+SSE, optionnel local)
│   ├── whatsapp-web-ui/        ← UI Next.js (optionnel, port 8089 si lancé)
│   └── docker-compose.yaml     ← DÉCORATIF en local, utilisé uniquement en prod distante
├── z2-41792168200/             ← même structure
└── z3-41799138200/             ← même structure
```

---

## 🏗 Architecture technique

Chaque bridge = 3 composants (mais **seul le Go bridge est obligatoire** pour que Make.com / MCP puissent pusher des messages) :

```
┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
│   whatsapp-bridge    │     │  whatsapp-mcp-server │     │   whatsapp-web-ui    │
│   Go + whatsmeow     │◄────│  Python + MCP+Gradio │     │   Next.js SPA        │
│   Port 8080/81/82    │     │  Port 8082 SSE       │     │   Port 8089          │
│   OBLIGATOIRE        │     │   Optionnel local    │     │   Optionnel local    │
└──────────┬───────────┘     └──────────────────────┘     └──────────────────────┘
           │
           ▼
     ┌──────────────────────┐
     │  SQLite store/       │
     │  messages.db         │
     │  whatsapp.db         │
     └──────────────────────┘
```

En local sur le Mac de Patrick, **seul le binaire Go tourne** en permanence. Le MCP Python et le Web UI ne sont lancés qu'à la demande (debug, inspection).

Le bridge Go expose une **REST API HTTP** sur son port. C'est cette API que Make.com et les agents Claude utilisent pour envoyer/lire des messages.

---

## 🔌 Endpoints REST utiles

Tous relatifs à `http://localhost:<port>/api/` :

| Endpoint | Méthode | Usage |
|----------|---------|-------|
| `/api/health` | GET | `{"connected":bool,"uptime":...,"reconnect_errs":N}` |
| `/api/sync-status` | GET | Progrès du history sync au démarrage |
| `/api/send-message` | POST | Envoyer texte (body: `{to, message}`) |
| `/api/send-file` | POST | Envoyer média |
| `/api/list-messages` | GET | Lecture historique |
| ... | ... | 41 outils au total (voir README.md du repo) |

---

## 🔄 Persistance — LaunchAgents + anti-zombie

Les 3 bridges sont gérés par des **LaunchAgents macOS** avec un script anti-zombie.

### Fichiers

| Fichier | Rôle |
|---------|------|
| `~/Library/LaunchAgents/com.patricktest.whatsapp-bridge-z1.plist` | LaunchAgent z1 (port 8080) |
| `~/Library/LaunchAgents/com.patricktest.whatsapp-bridge-z2.plist` | LaunchAgent z2 (port 8081) |
| `~/Library/LaunchAgents/com.patricktest.whatsapp-bridge-z3.plist` | LaunchAgent z3 (port 8082) |
| `/Users/patricktest/whatsapp-bridges/start-bridge.sh` | Script lanceur anti-zombie |

### Comportement

1. **Au boot** : `RunAtLoad: true` → macOS lance `start-bridge.sh` pour chaque bridge
2. **Au crash** : `KeepAlive: true` → macOS relance automatiquement
3. **Anti-zombie** : `start-bridge.sh` tue les doublons sur le port + les orphelins dans le dossier **avant** de lancer le binaire
4. **exec** : le script utilise `exec ./whatsapp-bridge` — le binaire remplace le shell, pas de process parent orphelin

### Commandes LaunchAgent

```bash
# Voir le statut des agents
launchctl list | grep whatsapp

# Recharger un agent (après modif du plist)
launchctl unload ~/Library/LaunchAgents/com.patricktest.whatsapp-bridge-z1.plist
launchctl load ~/Library/LaunchAgents/com.patricktest.whatsapp-bridge-z1.plist

# Forcer un restart propre (le KeepAlive le relance)
launchctl kickstart -k gui/$(id -u)/com.patricktest.whatsapp-bridge-z1

# Désactiver temporairement (ne relance plus)
launchctl unload ~/Library/LaunchAgents/com.patricktest.whatsapp-bridge-z1.plist
```

### Historique zombie (2026-04-21)

Des lancements manuels (`nohup ./whatsapp-bridge &`) avaient créé des doublons à côté du LaunchAgent. Ces zombies empêchaient la reconnexion WhatsApp (le port était occupé par un zombie déconnecté). Le script `start-bridge.sh` a été créé pour empêcher ce scénario.

**Règle : ne JAMAIS lancer `./whatsapp-bridge` manuellement.** Utiliser `launchctl kickstart` ou `launchctl load/unload` pour gérer les bridges.

---

## 🚑 Diagnostic rapide (cheatsheet)

```bash
# Health check des 3
for p in 8080 8081 8082; do echo "--- port $p ---"; curl -s http://localhost:$p/api/health; echo; done

# Qui écoute sur les ports ?
lsof -iTCP:8080 -sTCP:LISTEN -P
lsof -iTCP:8081 -sTCP:LISTEN -P
lsof -iTCP:8082 -sTCP:LISTEN -P

# Statut LaunchAgents
launchctl list | grep whatsapp

# Derniers logs z1
tail -30 /Users/patricktest/whatsapp-bridges/z1-41798131926/whatsapp-bridge/bridge.log

# Relancer un bridge (méthode correcte)
launchctl kickstart -k gui/$(id -u)/com.patricktest.whatsapp-bridge-z1

# Détecter des zombies
pgrep -fl whatsapp-bridge | wc -l
# Attendu : 3 (un par bridge). Plus = zombies.
```

---

## 📌 État au 2026-04-21 (dernière vérification)

- ✅ **z1** (port 8080) — `connected:true`, LaunchAgent + anti-zombie actif
- ✅ **z2** (port 8081) — `connected:true`, LaunchAgent + anti-zombie actif
- ✅ **z3** (port 8082) — `connected:true`, LaunchAgent créé le 2026-04-21 + anti-zombie actif

---

## 🔐 Pourquoi cette doc existe

Le 2026-04-18, une session Claude Code a essayé de lancer `docker compose up -d` sur z1, reçu une erreur 127 (Docker absent), et proposé d'installer Docker Desktop. **Faux diagnostic** : z1 était déjà connecté et sain via son binaire Go natif.

**Règle générale : si une commande docker échoue sur ce Mac, vérifier d'abord qu'un processus natif ne fait pas déjà le job.**

---

## 📎 Références

- Repo upstream : `felixisaac/whatsapp-mcp-extended` (fork de `AdamRussak/whatsapp-mcp`, lui-même fork de `lharries/whatsapp-mcp`)
- 41 outils MCP disponibles (voir README.md local de chaque bridge)
- TestFlight + WhatsApp pipeline : cf. `/Users/patricktest/Documents/Claude/` (global CLAUDE.md → Make scenario 9031997)
