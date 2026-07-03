#!/bin/bash
git config --global --add safe.directory '*'
if [ ! -d "flutter" ]; then
  curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz | tar xJ
fi
./flutter/bin/flutter pub get
./flutter/bin/flutter build web --release --no-tree-shake-icons