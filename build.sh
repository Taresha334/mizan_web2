#!/bin/bash
git config --global --add safe.directory '*'

# Only download if flutter folder doesn't exist
if [ ! -d "flutter" ]; then
  curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz | tar xJ
fi

# Add the local flutter bin to the PATH for this session
export PATH="$PATH:`pwd`/flutter/bin"

# Run the commands
flutter pub get
flutter build web --release --no-tree-shake-icons