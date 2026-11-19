[private]
help topic="help": _initialize
  #!/usr/bin/env bash
  set -euo pipefail
  case {{topic}} in
    'help')
        # if [ {{ if theme == "default" {"true"} else {"false"} }} ]; then
        #   just theme={{theme}} default-help
        # else
        #   just theme={{theme}} default-help --justfile "$THEME_PATH/{{ theme }}/justfile"
        # fi
        just theme={{theme}} default-help
      ;;

    'pandoc')
      just _pandoc-help
      ;;

    'xml')
      just _xml-help
      ;;

    'html')
      just _html-help
      ;;

    'pagedjs')
      just _pagedjs-help
      ;;

    'weasyprint')
      just _weasyprint-help
      ;;

    'mathjax')
      just _mathjax-help
      ;;

    *)
      echo 'No help for this recipe available.'
      ;;
  esac


[private]
default-help:
  #!/usr/bin/env bash
  echo "Usage: [ runConversionChain | just ] [ theme=<theme> | debug=true | validate=true | develop=true  | pagedjs-polyfill=true ] [ docx-file | xml-file | html-file =<filename> ] [ <recipe> ]"
  echo ""
  echo 'To run a recipe without its dependencies add a "-" to the recipes name, e.g. "weasyprint-"'
  echo "If no docx file is provided the first docx file in the working dirctory will be taken."
  echo "If no recipe is provided the full conversion chain is run and all available versions of PDFs will be created." 
  echo ""
  echo "Options:"
  echo "    theme = <theme>: Selects a set of templates (i.e. a sub folder of the themes folder) to be used for conversion."
  echo "    debug = true: Enables the debug options of the different tools."
  echo "    validate = true: Runs an XML validation with xmllint."
  echo "    develop = true: Adds specific css rules to the conversion of HTML and PDF files to provide features for debugging and development of Print CSS conversion steps."
  echo "    docx-file | xml-file | html-file = <filename>: Specifies the path and name of the docx, xml or html source file to be converted."
  echo "    pagedjs-polyfill = true: Adds the Pagedjs polyfill to the final HTML output for debugging purpose."
  echo ""
  # if {{ if theme == "default" {"true"} else {"false"} }}; then
  #   just --list
  # else
  #   just --list --justfile "$THEME_PATH/{{ theme }}/justfile"
  # fi
  just --list