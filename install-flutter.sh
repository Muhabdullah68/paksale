#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.29.0"
ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${ARCHIVE}"
INSTALL_DIR="$HOME/flutter"

echo "=== Flutter Installer (for Vercel) ==="
echo "Flutter version : ${FLUTTER_VERSION}"
echo "Target dir      : ${INSTALL_DIR}"

if [ -x "${INSTALL_DIR}/bin/flutter" ]; then
  echo "Flutter already installed. Skipping download."
else
  echo "Downloading Flutter from Google Storage..."
  cd /tmp
  curl -fL --retry 3 -o "${ARCHIVE}" "${URL}"
  echo "Extracting..."
  mkdir -p "$HOME"
  tar -xf "${ARCHIVE}" -C "$HOME"
  ls -la "${INSTALL_DIR}/bin/flutter"
fi

export PATH="${INSTALL_DIR}/bin:${INSTALL_DIR}/bin/cache/dart-sdk/bin:${PATH}"
flutter --version
dart --version
flutter config --no-analytics --no-cli-animations
echo "=== Flutter install OK ==="
