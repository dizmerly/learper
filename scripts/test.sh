#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
output_dir="$project_root/.build/tests"
mkdir -p "$output_dir"

swiftc \
  -target "$(uname -m)-apple-macos13.0" \
  -sdk "$sdk_path" \
  -emit-library -emit-module -enable-testing \
  -profile-generate -profile-coverage-mapping \
  -module-name Learper \
  "$project_root/Sources/Learper/QuizModels.swift" \
  "$project_root/Sources/Learper/QuizResources.swift" \
  "$project_root/Sources/Learper/QuizLibrary.swift" \
  "$project_root/Sources/Learper/QuizSession.swift" \
  -o "$output_dir/libLearper.dylib"

swiftc \
  -target "$(uname -m)-apple-macos13.0" \
  -sdk "$sdk_path" \
  -emit-library -emit-module \
  -module-name LearperTestSupport \
  "$project_root/Tests/LearperTestSupport/TestSupport.swift" \
  -o "$output_dir/libLearperTestSupport.dylib"

swiftc \
  -target "$(uname -m)-apple-macos13.0" \
  -sdk "$sdk_path" \
  -D LEARPER_MANUAL_TEST_RUNNER \
  -I "$output_dir" -L "$output_dir" -lLearper -lLearperTestSupport \
  -Xlinker -rpath -Xlinker "$output_dir" \
  "$project_root"/Tests/LearperTests/*.swift \
  -o "$output_dir/learper-tests"

LEARPER_SAMPLE_PATH="$project_root/Sources/Learper/Resources/sample-quiz.json" \
LLVM_PROFILE_FILE="$output_dir/learper.profraw" \
  "$output_dir/learper-tests"

xcrun llvm-profdata merge -sparse "$output_dir/learper.profraw" \
  -o "$output_dir/learper.profdata"
xcrun llvm-cov report "$output_dir/libLearper.dylib" \
  -instr-profile="$output_dir/learper.profdata"
