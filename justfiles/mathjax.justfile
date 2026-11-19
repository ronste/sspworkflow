_mathjax-help:
  #!/bin/bash
  cat << EOF
  This conversion step uses Mathjax on a HTML file to convert MathML formulas into CHTML.

  Relevant links:
  https://www.mathjax.org/
  https://github.com/mathjax/MathJax-demos-node

  Known issues:
  - MathJax conversion script runs with the workspace node_modules on Node.js 20+
  EOF

# Convert Mathl to CHTML using mathjax
[private]
mathjax-: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  echo -e "{{hcs}}Processing MathML with Mathjax ... {{nc}}"
  docx_file="{{docx-file}}" && cd "$UTILS_PATH" && node "mml2chtml-page" "$WORK_PATH/{{html-file}}" > "$WORK_PATH/${docx_file}_mathjax.html" && cd "$WORK_PATH"
  cp "$WORK_PATH/{{docx-file}}_mathjax.html" "$WORK_PATH/{{buffer-html-file}}"
  echo "Elapsed Time: $SECONDS seconds"

# Convert MathML to CHTML using mathjax
mathjax: _default html mathjax-