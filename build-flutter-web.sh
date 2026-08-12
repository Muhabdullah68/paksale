#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/flutter"
export PATH="${INSTALL_DIR}/bin:${INSTALL_DIR}/bin/cache/dart-sdk/bin:${PATH}"

echo "=== Build step: flutter pub get ==="
flutter pub get

echo "=== Build step: flutter build web ==="
flutter build web \
  --release \
  --base-href=/ \
  --web-renderer=canvaskit

echo "=== Build complete: build/web ==="
ls -la build/web | head -n 20
