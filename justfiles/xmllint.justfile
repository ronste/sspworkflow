#Validate XML file against DTD provided by DOCTYPE tag. Usage: "runConversionChain xml-file=<filename> xml-validate"
[no-cd]
xml-validate:
  #!/usr/bin/env bash
  set -euo pipefail
  if [ "{{ xml-file }}" != "buffer.xml" ]; then \
    echo -e "{{hcs}}Validating XML with xmllint ...{{nc}}"; \
    xmllint {{xml-file}} --noout --dtdvalid; \
      if [ $? -eq 0 ]; then \
        echo -e "{{hcs}}Validation successfull{{nc}}"; \
      else \
        echo -e "{{wcs}}XML-document is not valid!{{nc}}"; \
      fi \
  else \
    echo -e "{{wcs}}Please provide a filename to validate!{{nc}}"; \
  fi
  echo "Elapsed Time: $SECONDS seconds"
