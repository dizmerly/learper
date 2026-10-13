#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
test_binary="$project_root/.build/learper-smoke"
mkdir -p "$project_root/.build"

swiftc \
  -target "$(uname -m)-apple-macos13.0" \
  -sdk "$sdk_path" \
  -parse-as-library \
  "$project_root/Sources/Learper/QuizModels.swift" \
  "$project_root/Sources/Learper/QuizResources.swift" \
  "$project_root/Sources/Learper/QuizLibrary.swift" \
  "$project_root/Sources/Learper/QuizSession.swift" \
  "$project_root/scripts/smoke_test.swift" \
  -o "$test_binary"

"$test_binary" "$project_root/Sources/Learper/Resources/sample-quiz.json"
