_weasyprint-help:
  #!/bin/bash
  cat << EOF
  This conversion step uses Weasyprint to perform a HTML -> PDF conversion. It uses the "weasyprint.css" file of the currently selected theme on top of the css included in the HTML file.

  Relevant links:
  https://doc.courtbouillon.org/weasyprint/stable/first_steps.html
  https://weasyprint.org/
  http://test.weasyprint.org/suite-css-page-3/chapter4/section1/
  EOF

# Generate PDF using Weasyprint
[private]
weasyprint-: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  echo -e "{{hcs}}Converting to PDF with WeasyPrint ...{{nc}}"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/weasyprint.css $WORK_PATH/media/weasyprint.css
  weasyprint {{ if debug == "true" { "-d" } else { "" } }} \
    -m print -p \
    -s "$WORK_PATH/media/weasyprint.css" \
    {{ if develop == "true" { "-s $CSS_PATH/develop.css" } else { "" } }} \
    -p "$WORK_PATH/{{html-file}}" "$WORK_PATH/{{docx-file}}_weasyprint.pdf"
  echo "Elapsed Time: $SECONDS seconds"

# Generate PDF using Weasyprint
weasyprint: _default html mathjax weasyprint-