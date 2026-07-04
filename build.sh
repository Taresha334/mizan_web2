#!/bin/bash
# Production-ready build script for Mizan PLC Web Application
# This script handles Flutter SDK acquisition and project compilation.

git config --global --add safe.directory '*'

# 1. Download and extract Flutter if it is not already present
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz | tar xJ
fi

# 2. Run pub get to resolve all dependencies
echo "Running pub get..."
./flutter/bin/flutter pub get

# 3. Build the web project
# --no-tree-shake-icons: Ensures all icons are available for the UI
# --no-wasm: Disables WebAssembly compilation to ensure compatibility with older plugins
echo "Building web application..."
./flutter/bin/flutter build web --release --no-tree-shake-icons --no-wasm

# 4. Final verification
if [ -d "build/web" ]; then
  echo "Build completed successfully. Output located in build/web."
else
  echo "Build failed to generate the required build/web directory."
  exit 1
fi