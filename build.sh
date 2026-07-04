#!/bin/bash
git config --global --add safe.directory '*'

# 1. Download Flutter
if [ ! -d "flutter" ]; then
  curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz | tar xJ
fi

# 2. Build
./flutter/bin/flutter pub get
./flutter/bin/flutter build web --release --no-tree-shake-icons --no-wasm-dry-run

# 3. CRITICAL: Vercel expects a specific file structure.
# If build/web exists, we exit with 0.
if [ -d "build/web" ]; then
  echo "Build finished successfully."
  # We do NOT exit here, we let the script finish normally.
else
  exit 1
fi