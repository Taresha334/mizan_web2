#!/bin/bash
git config --global --add safe.directory '*'

if [ ! -d "flutter" ]; then
  curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz | tar xJ
fi

# Run pub get
./flutter/bin/flutter pub get

# Run build
./flutter/bin/flutter build web --release --no-tree-shake-icons

# Ensure the output is in the folder Vercel expects
if [ -d "build/web" ]; then
  echo "Build successful, directory exists."
else
  echo "Build failed to create output directory."
  exit 1
fi