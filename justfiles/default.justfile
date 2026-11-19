# run for all recipies
_default: _initialize _print-user-info

_initialize:
  #!/usr/bin/env bash
  set -euo pipefail
  # set all dynamic environment variables (others will be set via .env file)
  sed -i '/^export TEMPLATE_PATH=/d' ~/.bashrc
  sed -i '/^export XSL_PATH=/d' ~/.bashrc
  sed -i '/^export CSS_PATH=/d' ~/.bashrc
  sed -i '/^export RES_PATH=/d' ~/.bashrc
  echo 'export TEMPLATE_PATH="$THEME_PATH/{{theme}}/templates"' >> ~/.bashrc
  echo 'export XSL_PATH="$THEME_PATH/{{theme}}/xsl"'  >> ~/.bashrc
  echo 'export CSS_PATH="$THEME_PATH/{{theme}}/css"'  >> ~/.bashrc
  echo 'export RES_PATH="$THEME_PATH/{{theme}}/res"'  >> ~/.bashrc
  # Apply the changes
  source ~/.bashrc
  # Load theme
  if [ {{ if theme  == "default" {"true"} else {"false"} }} ]; then
    if [ ! -f "$METADATA_PATH/metadata.yaml" ]; then
      cp $TEMPLATE_PATH/metadata.yaml $METADATA_PATH/metadata.yaml
    fi
  else
    echo "Loading theme {{theme}} from $THEME_PATH/{{theme}}"
    cp $THEME_PATH/{{theme}}/templates/metadata.yaml $METADATA_PATH/metadata.yaml
    just --justfile $THEME_PATH/{{theme}}/justfile
  fi

# print user info
_print-user-info:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "Working directory is: $WORK_PATH"
  echo "Theme path is:        $THEME_PATH/{{theme}}"
  echo "Utils path is:        $UTILS_PATH"
  echo "Input file is:        {{docx-file}}"
  if [ ! -d "$METADATA_PATH" ]; then
    mkdir -p $METADATA_PATH
  fi

