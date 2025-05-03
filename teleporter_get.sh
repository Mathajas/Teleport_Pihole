#!/bin/bash

set -e

REMOTE_HOST="host IP"
REMOTE_USER="USER"
CONTAINER_NAME="pihole"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_EXTRACT_DIR="$SCRIPT_DIR/tmp_extract"

# Docker volume paths (local)
TARGET_PIHOLE="/opt/pihole/etc-pihole"
TARGET_DNSMASQ="/opt/pihole/etc-dnsmasq.d"

echo "📡 [1] Cleaning temporary directory..."
rm -rf "$TMP_EXTRACT_DIR"
mkdir -p "$TMP_EXTRACT_DIR"

# --- Copy /etc/pihole ---
echo "📦 [1a] Attempting to fetch /etc/pihole from container..."
if ssh "$REMOTE_USER@$REMOTE_HOST" "sudo docker exec $CONTAINER_NAME test -d /etc/pihole"; then
  ssh "$REMOTE_USER@$REMOTE_HOST" "sudo docker cp $CONTAINER_NAME:/etc/pihole -" | tar -x -C "$TMP_EXTRACT_DIR"
else
  echo "❌ /etc/pihole not found in container — aborting."
  exit 1
fi

# --- Copy /etc/dnsmasq.d ---
echo "📦 [1b] Attempting to fetch /etc/dnsmasq.d from container..."
if ssh "$REMOTE_USER@$REMOTE_HOST" "sudo docker exec $CONTAINER_NAME test -d /etc/dnsmasq.d"; then
  ssh "$REMOTE_USER@$REMOTE_HOST" "sudo docker cp $CONTAINER_NAME:/etc/dnsmasq.d -" | tar -x -C "$TMP_EXTRACT_DIR"
else
  echo "⚠️ /etc/dnsmasq.d not found in container — skipping."
fi

echo "🛑 [2] Stopping local Pi-hole container..."
sudo docker stop pihole || exit 1

echo "📁 [3] Ensuring target volume directories exist..."
mkdir -p "$TARGET_PIHOLE"
mkdir -p "$TARGET_DNSMASQ"

echo "🧹 [4] Cleaning target directories..."
rm -rf "$TARGET_PIHOLE"/*
rm -rf "$TARGET_DNSMASQ"/*

echo "💾 [5] Restoring configuration..."

if [ -d "$TMP_EXTRACT_DIR/pihole" ] && [ "$(ls -A "$TMP_EXTRACT_DIR/pihole")" ]; then
  cp -r "$TMP_EXTRACT_DIR/pihole/"* "$TARGET_PIHOLE/"
else
  echo "⚠️ Skipping pihole copy — source missing or empty."
fi

if [ -d "$TMP_EXTRACT_DIR/dnsmasq.d" ] && [ "$(ls -A "$TMP_EXTRACT_DIR/dnsmasq.d")" ]; then
  cp -r "$TMP_EXTRACT_DIR/dnsmasq.d/"* "$TARGET_DNSMASQ/"
else
  echo "⚠️ Skipping dnsmasq.d copy — source missing or empty."
fi

echo "🚀 [6] Starting Pi-hole container..."
sudo docker start pihole || exit 1

echo "🔄 [7] Running gravity update..."
sudo docker exec pihole pihole -g && echo "✅ Gravity update complete." || echo "❌ Gravity update failed."

echo "🧼 [8] Cleaning temporary data..."
rm -rf "$TMP_EXTRACT_DIR"

echo "✅ Pi-hole sync completed."
