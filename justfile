# run all conversions (default)
all: _default pdf
set dotenv-load := true
set allow-duplicate-recipes := true

[private]
alias Pandoc := pandoc
[private]
alias pandoc-xml := pandoc
[private]
alias pandoc-pdf := pandoc-pdf-html
[private]
alias XML := xml
[private]
alias HTML := html
[private]
alias PDF := pdf
[private]
alias Pagedjs := pagedjs
[private]
alias WeasyPrint := weasyprint
[private]
alias Weasyprint := weasyprint
[private]
alias weasy := weasyprint

# command line parameters
theme := 'default'
#docx-file := '$(find $WORK_PATH -maxdepth 1 -type f -name "*.docx" | head -n 1 | xargs basename)'
docx-file := '$(ls $WORK_PATH/*.docx | head -n 1 | xargs basename)'
xml-file := 'buffer.xml'
xml-mode := 'jats'
metadata-filter := 'custom'
buffer-xml-file := 'buffer.xml'
html-file := 'buffer.html'
buffer-html-file := 'buffer.html'
xsl-file := 'pandoc_post_process_jats.xsl'
debug := 'false'
validate := 'false'
develop := 'false'
pandoc_from := 'xml'
pagedjs-polyfill := 'false'

# path variables
develop_html_fragment := '$(echo "/<head/ r "$XSL_PATH/html_fragment_develop.html"")'

# find jar files in $LIB_PATH/Saxon${SAXON_VERSION}J/ and add to classpath
javaClassPath := '$(find $LIB_PATH/Saxon${SAXON_VERSION}J/ -name "*.jar" | tr "\n" ":")'

# color defnitions
hcs := '\033[0;32m' # heading color start
nc := '\033[0m'    # no color
wcs := '\033[0;31m' # warning color start

import 'justfiles/default-justfile'
import 'justfiles/help-justfile'
import 'justfiles/pandoc-justfile'
import 'justfiles/xml-justfile'
import 'justfiles/html-justfile'
import 'justfiles/pagedjs-justfile'
import 'justfiles/mathjax-justfile'
import 'justfiles/weasyprint-justfile'
import 'justfiles/docxtojats-justfile'
import 'justfiles/xmllint-justfile'

# Generate PDF using Pandoc, Pagedjs and Weasyprint
[private]
pdf-: _default (pandoc-pdf- pandoc_from) pagedjs- weasyprint-

# Generate PDF using Pandoc, Pagedjs and Weasyprint
pdf: _default html (pandoc-pdf- pandoc_from) pagedjs- mathjax weasyprint-

[no-cd]
@_cleanup-tmp:
  -rm $WORK_PATH/{{buffer-xml-file}} $WORK_PATH/{{buffer-html-file}} 2> /dev/null

# Clean up the working directory removing all files in work and in work/media
[no-cd]
@cleanup-work:
  -rm $WORK_PATH/* 2> /dev/null
  -rm $WORK_PATH/media/* 2> /dev/null
  -rm $WORK_PATH/metadata/* 2> /dev/null

# Clean up the working directory and reset Jats XML example file 
[no-cd]
reset-jats-example: (reset-example "jats")

# Clean up the working directory and reset Jats XML example file with YAML metadata header
[no-cd]
reset-jats-example-yaml: (reset-example "jats" "yaml")

# Clean up the working directory and reset Jats XML example file with table metadata header
[no-cd]
reset-jats-example-table: (reset-example "jats" "table")

# Clean up the working directory and reset Bits XML example file 
[no-cd]
reset-bits-example: (reset-example "bits")

# Clean up the working directory and reset Bits XML example file with YAML metadata header
[no-cd]
reset-bits-example-yaml: (reset-example "bits" "yaml")

# Clean up the working directory and reset Bits XML example file with table metadata header
[no-cd]
reset-bits-example-table: (reset-example "bits" "table")

[no-cd, private]
reset-example xml-mode=xml-mode metadata-filter=metadata-filter: cleanup-work && _default 
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  bitscustom='Dummy_Book_Template.docx'
  bitsyaml='Dummy_Book_Template_Yaml_Header.docx'
  bitstable='Dummy_Book_Template_Table_Header.docx'
  jatscustom='Dummy_Article_Template.docx'
  jatsyaml='Dummy_Article_Template_Yaml_Header.docx'
  jatstable='Dummy_Article_Template_Table_Header.docx'
  echo -e $UTILS_PATH/${{xml-mode}}{{metadata-filter}}
  cp $UTILS_PATH/${{xml-mode}}{{metadata-filter}} $WORK_PATH/${{xml-mode}}{{metadata-filter}}
  cp $THEME_PATH/default/templates/metadata.yaml $METADATA_PATH/metadata.yaml

#Run different test scripts
@runtests:
  $UTILS_PATH/run_tests.sh

# Copies the full content of the work folder into a new folder inside the configured COPY_PATH folder
[no-cd]
@copy-work destination:
  mkdir $COPY_PATH/{{destination}}
  cp -r $WORK_PATH/* $COPY_PATH/{{destination}}

# Show versions of all used tools
[no-cd]
@versions:
  echo "{{hcs}}Pandoc version: {{nc}}"$(pandoc --version | head -n 1)
  echo -n "{{hcs}}Saxon version: {{nc}}"
  echo -n $(java -cp {{javaClassPath}} net.sf.saxon.Version)
  # echo "{{hcs}}Pagedjs version: {{nc}}"$(pagedjs --version)
  echo "{{hcs}}WeasyPrint version: {{nc}}"$(weasyprint --version | head -n 1)
  echo "{{hcs}}MathJax version: {{nc}}"$(npm list mathjax 2>/dev/null | grep 'mathjax' | sed 's/.*@//')
  echo "{{hcs}}LuaRocks version: {{nc}}"$(luarocks --version | head -n 1 )
  echo "{{hcs}}just version: {{nc}}"$(just --version)

# Overwrite pagedjs- to disable it
[no-cd, private]
pagedjs-:
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  echo -e "{{wcs}}Pagedjs currently disabled due to lack of maintenance{{nc}}"