#! /bin/bash
set -euo pipefail
cd /root/sspworkflow/work
runConversionChain reset-example
runConversionChain
runConversionChain validate=true html-
runConversionChain debug=true validate=true develop=true weasyprint-
runConversionChain pandoc-pdf-xml-
runConversionChain theme=berlinup validate=true reset-example html
runConversionChain -f /root/sspworkflow/themes/berlinup/justfile debug=true custom-example
runConversionChain docxtojats
runConversionChain xml-file='/root/sspworkflow/work/buffer.xml' xml-validate
runConversionChain reset-example
runConversionChain
runConversionChain xml-file=buffer.xml html-
runConversionChain reset-bits-example
runConversionChain bitsxml html-
runConversionChain copy-work test
runConversionChain reset-bits-example-yaml
runConversionChain metadata-filter="yaml" xml-mode="bits" xml