Mermaid 10.9.5 is bundled here for offline WebKit rendering on macOS 13 and later.
`mermaid.min.js` includes its npm dependencies. `LICENSE` is Mermaid's MIT license;
`mermaid.min.js.LEGAL.txt` contains notices retained from bundled dependencies.

To rebuild intentionally, run `./scripts/update_mermaid.sh` from the project root.
The source configuration is in `scripts/mermaid-entry.js`. npm is needed only to
regenerate this checked-in bundle, not to build or run Learper.
