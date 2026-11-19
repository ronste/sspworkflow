_html-help:
  #!/bin/bash
  cat << EOF
  This conversion step uses Saxon HE 12 to perform a Jats XML -> HTML conversion. It uses the "jats_html.css" file of the currently selected theme.

  Conversion in performed in to steps:
  1) Citation conversion using "jats-APAcit.xsl" from the currently selected theme.
  2) Document conversion using "jats-html.xsl" from the currently selected theme.
  EOF

# Convert XML to HTML using Saxon HE 12
[no-cd, private]
html-: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/jats_html.css $WORK_PATH/media/jats_html.css
  cp {{ if debug == "true" { "--verbose" } else { "" } }} $RES_PATH/logo/* $WORK_PATH/media
  echo -e "{{hcs}}Converting XML to HTML with Saxon HE 12 ...{{nc}}"
  # run citation conversion
  java -cp "{{javaClassPath}}" \
    net.sf.saxon.Transform -s:"$WORK_PATH/{{xml-file}}" \
    -xsl:"$XSL_PATH/jats-APAcit.xsl" \
    -o:"$WORK_PATH/{{docx-file}}_SaxonHE_cit.xml"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} "$WORK_PATH/{{docx-file}}_SaxonHE_cit.xml" "$WORK_PATH/{{buffer-xml-file}}"
  # run html conversion
  java -cp "{{javaClassPath}}" \
    net.sf.saxon.Transform -s:"$WORK_PATH/{{buffer-xml-file}}" \
    -xsl:"$XSL_PATH/jats-html.xsl" \
    -o:"$WORK_PATH/{{docx-file}}_SaxonHE.html"
  # add development styles
  if [ "{{ develop }}" = "true" ]; then \
    echo -e "{{wcs}}Adding development styles ...{{nc}}"; \
    sed "{{develop_html_fragment}}" -i "$WORK_PATH/{{docx-file}}_SaxonHE.html"; \
    cp {{ if debug == "true" { "--verbose" } else { "" } }} $CSS_PATH/develop.css $WORK_PATH/media/develop.css; \
    echo -e "TODO: start development server"; \
  fi
  # copy to buffer
  cp "$WORK_PATH/{{docx-file}}_SaxonHE.html" "$WORK_PATH/{{buffer-html-file}}"
  # add pagedjs polyfill to output file only
  if [ "{{ pagedjs-polyfill }}" = "true" ]; then \
    echo -e "{{wcs}}Adding pagedjs polyfill ...{{nc}}"; \
    sed -i '/<head>/a <script src="https://unpkg.com/pagedjs/dist/paged.polyfill.js"></script>' "$WORK_PATH/{{docx-file}}_SaxonHE.html"; \
    sed -i '/<head>/a <link rel="stylesheet" type="text/css" href="media/pagedjs.css">' "$WORK_PATH/{{docx-file}}_SaxonHE.html"; \
  fi
  # validate html
  set +e
  if [ "{{ validate }}" = "true" ]; then \
    echo -e "{{hcs}}Validating HTML with html-validate ...{{nc}}"; \
    # xmllint "$WORK_PATH/{{docx-file}}_SaxonHE.html" --noout --valid --html; \
    # https://html-validate.org/usage/cli.html
    html-validate "$WORK_PATH/{{docx-file}}_SaxonHE.html"
    if [ $? -eq 0 ]; then \
      echo -e "{{hcs}}Validation successfull{{nc}}"; \
    else \
      echo -e "{{wcs}}HTML-document is not valid!{{nc}}"; \
    fi \
  fi
  set -e
  echo "Elapsed Time: $SECONDS seconds"

# Convert XML to HTML using Saxon HE 12
html: _default xml html-