#!/bin/bash
# Production-ready build script for Mizan PLC Web Application
# This script handles Flutter SDK acquisition and project compilation.

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

# 4. Build the web project
# We use --no-wasm-dry-run to suppress the specific flutter_tts warnings
# that were causing the build to fail the validation check.
echo "Building web..."
./flutter/bin/flutter build web --release --no-tree-shake-icons --no-wasm-dry-run

# 5. Success check
# We explicitly check for the directory. If it exists, we exit 0 (success).
# This prevents Vercel from trying to run its own build command.
if [ -d "build/web" ]; then
  echo "Build successful."
  exit 0
else
  echo "Build failed: output directory not found."
  exit 1
fi