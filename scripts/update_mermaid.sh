#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
tools_dir="$project_root/.build/mermaid-tools"
vendor_dir="$project_root/Sources/Learper/Resources/Web/vendor/mermaid"

npm install --prefix "$tools_dir" --no-audit --no-fund mermaid@10.9.5 esbuild@0.25.12
cp "$project_root/scripts/mermaid-entry.js" "$tools_dir/entry.js"
mkdir -p "$vendor_dir"
"$tools_dir/node_modules/.bin/esbuild" "$tools_dir/entry.js" \
  --bundle --minify --format=iife --target=safari16 --legal-comments=external \
  --outfile="$vendor_dir/mermaid.min.js"
cp "$tools_dir/node_modules/mermaid/LICENSE" "$vendor_dir/LICENSE"
