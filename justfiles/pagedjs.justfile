_pagedjs-help:
  #!/bin/bash
  cat << EOF
  This conversion step uses pagedjs-cli to perform a HTML -> PDF conversion. It uses the "pagedjs.css" file of the currently selected theme on top of the css included in the HTML file.

  Relevant links:
  https://www.npmjs.com/package/pagedjs-cli
  https://pagedjs.org/documentation/ 
  https://gitlab.coko.foundation/pagedjs/pagedjs-cli

  Known issues:
  - pagedjs-cli fails with --debug option !!! a browser is required
  - pagedjs-cli produces different results as compared to pagedjs polyfill !!!
  EOF

# Generate PDF using Pagedjs
[no-cd, private]
pagedjs-:
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  echo -e "{{hcs}}Converting to PDF with pagedjs-cli ...{{nc}}"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/pagedjs.css $WORK_PATH/media/pagedjs.css
  pagedjs-cli {{ if debug == "true" { "--warn" } else { "" } }} \
    --style "$WORK_PATH/media/pagedjs.css" \
    {{ if develop == "true" { "--style $DEFAULT_CSS_PATH/develop.css" } else { "" } }} \
    --browserArgs '--no-sandbox' \
    -i "$WORK_PATH/{{html-file}}" \
    -o "$WORK_PATH/{{docx-file}}_pagedjs.pdf"
  echo "Elapsed Time: $SECONDS seconds"

# Generate PDF using Pagedjs
pagedjs: _default html pagedjs-