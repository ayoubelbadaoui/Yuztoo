#!/usr/bin/env bash
# Fix gRPC basic_seq.h in both pods for Xcode 15/16 Clang.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for rel in \
  "Pods/gRPC-Core/src/core/lib/promise/detail/basic_seq.h" \
  "Pods/gRPC-C++/src/core/lib/promise/detail/basic_seq.h"; do
  F="$ROOT/$rel"
  if [[ -f "$F" ]]; then
    perl -i -pe 's/Traits::template CallSeqFactory/Traits::CallSeqFactory/g' "$F"
    echo "Patched: $F"
  fi
done
