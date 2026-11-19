#Generate Jats XML using the docxtojats converter
docxtojats: _default
  #!/usr/bin/env bash
  set -euo pipefail
  source ~/.bashrc
  php $LIB_PATH/docxToJats/docxtojats.php $WORK_PATH/{{docx-file}} $WORK_PATH/{{docx-file}}_docxtojats.xml
  cp $WORK_PATH/{{docx-file}}_docxtojats.xml $WORK_PATH/{{buffer-xml-file}}
  echo "Elapsed Time: $SECONDS seconds"