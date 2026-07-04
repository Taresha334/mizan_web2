#!/bin/bash
git config --global --add safe.directory '*'

# 1. Download and extract if missing
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter..."
  curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz | tar xJ
fi

# 2. Run commands using the direct path
echo "Running pub get..."
./flutter/bin/flutter pub get

echo "Building web..."
./flutter/bin/flutter build web --release --no-tree-shake-icons