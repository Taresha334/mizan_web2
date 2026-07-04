#!/bin/bash
git config --global --add safe.directory '*'

# 1. Download and extract Flutter if it is not already present
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz | tar xJ
fi

# 2. Prepare environment
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Clean and build
echo "Cleaning up..."
./flutter/bin/flutter clean
echo "Running pub get..."
./flutter/bin/flutter pub get
echo "Building web..."
./flutter/bin/flutter build web --release --no-tree-shake-icons

# 4. Success check
if [ -d "build/web" ]; then
  echo "Build successful."
  exit 0
else
  echo "Build failed."
  exit 1
fi