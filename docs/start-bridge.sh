#!/bin/bash
# start-bridge.sh — Lanceur anti-zombie pour les WhatsApp bridges
# Usage: start-bridge.sh <bridge-dir> <port>
# Appelé par le LaunchAgent — tue les doublons avant de lancer

BRIDGE_DIR="$1"
PORT="$2"

# Tuer tout processus whatsapp-bridge qui écoute sur ce port SAUF notre PID parent
EXISTING_PID=$(lsof -iTCP:"$PORT" -sTCP:LISTEN -t 2>/dev/null)
if [ -n "$EXISTING_PID" ]; then
    kill "$EXISTING_PID" 2>/dev/null
    sleep 1
fi

# Tuer les orphelins whatsapp-bridge dans ce dossier (pas sur le bon port)
pgrep -f "$BRIDGE_DIR/whatsapp-bridge" | while read pid; do
    kill "$pid" 2>/dev/null
done
sleep 1

# Lancer le bridge (exec remplace le shell — pas de process orphelin)
cd "$BRIDGE_DIR"
exec ./whatsapp-bridge
