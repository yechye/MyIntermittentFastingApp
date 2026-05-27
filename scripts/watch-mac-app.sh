#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="FastingApp"
POLL_SECONDS="${POLL_SECONDS:-1}"

cd "$ROOT_DIR"

snapshot() {
  {
    find FastingApp FastingAppTests -type f \( -name '*.swift' -o -name '*.xcassets' -o -name '*.json' \) -print0
    printf '%s\0' Package.swift
  } | xargs -0 stat -f '%m %N' 2>/dev/null | sort
}

relaunch() {
  osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  ./scripts/run-mac-app.sh
}

echo "Watching Swift sources for changes. Press Ctrl-C to stop."
last_snapshot="$(snapshot)"
relaunch

while true; do
  sleep "$POLL_SECONDS"
  next_snapshot="$(snapshot)"
  if [[ "$next_snapshot" != "$last_snapshot" ]]; then
    echo
    echo "Change detected. Rebuilding and relaunching..."
    last_snapshot="$next_snapshot"
    if relaunch; then
      echo "Relaunched $APP_NAME."
    else
      echo "Build failed. Fix the error and save again."
    fi
  fi
done
