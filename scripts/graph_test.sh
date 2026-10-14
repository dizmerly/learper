#!/bin/zsh
set -euo pipefail
project_root="${0:A:h:h}"
output_dir="$project_root/.build/tests"
mkdir -p "$output_dir"
xcrun --sdk macosx swiftc \
  -target "$(uname -m)-apple-macos13.0" \
  -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  "$project_root/scripts/graph_test.swift" \
  -o "$output_dir/learper-graph-tests"
"$output_dir/learper-graph-tests" "$project_root"
