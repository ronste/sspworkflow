_xml-help:
  #!/bin/bash
  cat << EOF
  This conversion step uses SaxonHE to perform a XSL transformation on a XML file. By default it uses the file "pandoc_post_process_jats.xsl" to perform a post precessing step on a prior Pandoc docx -> Jats XML conversion. However, you can provide a path to an XML file and a path to an XSL file in the form 

  runConversionChain xml- <path-to-xml> <path-to-xsl>

  to perform custom XSL transformations.

  Debug hints:
  # java classpath separator is ":" on Linux and ";" on Windows !!!
  # java -p lib/SaxonHE12-4J/saxon-he-12.4.jar --list-modules
  # java -verbose:class net.sf.saxon.Transform
  EOF

# Convert docx to XML using Pandoc + Saxon HE 12.
[private]
xml- xml-mode=xml-mode: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  echo -e "{{hcs}}XSLT processing with Saxon HE 12 ...{{nc}}"
  echo -e 'Using XSLT {{ if xml-mode == "bits" { "pandoc_post_process_bits.xsl" } else { xsl-file } }}'
  java -cp "{{javaClassPath}}" \
    net.sf.saxon.Transform -s:"$WORK_PATH/{{xml-file}}" \
    -xsl:$UTILS_PATH/{{ if xml-mode == "bits" { "pandoc_post_process_bits.xsl" } else { xsl-file } }} \
    -o:"$WORK_PATH/{{docx-file}}_SaxonHE_{{xml-mode}}.xml"
  cp {{ if debug == "true" { "--verbose" } else { "" } }} "$WORK_PATH/{{docx-file}}_SaxonHE_{{xml-mode}}.xml" "$WORK_PATH/{{buffer-xml-file}}"
  if [ "{{ validate }}" = "true" ]; then \
    just xml-file="$WORK_PATH/{{docx-file}}_SaxonHE_{{xml-mode}}.xml" xml-validate; \
  fi
  echo "Elapsed Time: $SECONDS seconds"

# Convert docx to XML using Pandoc + Saxon HE 12.
xml: (pandoc- xml-mode metadata-filter) (xml- xml-mode)

# Convert docx to Bits XML (experimental, metadata not yet supported).
bitsxml: (pandoc- "bits" metadata-filter) (xml- "jats") (xml- "bits")

[private]
bitsxml-: (xml- "bits")

