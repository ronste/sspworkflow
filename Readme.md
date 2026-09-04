# Single Source Publishing Workflow Image

- Version: 1.6 (04.03.2026)
- Developed by: Ronald Steffen

---

This repo contains a container image assembling different open source tools and a range of open source template files into a flexible framework for single source Jats/Bits XML publishing. The framework allows to define custom conversion toolchains that combine different conversion tools into an automized conversion workflow. Currently it provides a `docx -> (Jats) XML -> html -> pdf` toolchain by default.

***NOTE: This repo is under development.***
This repo is intended as a proof-of-concept tool. In particular the templates require significant revision and improvement. I don't play around with Latex. So don't count on any developments of the pandoc-pdf Latex template. Documantation is incomplete.

The tools included are [updated 04.03.2026]:

- [Pandoc](https://pandoc.org/) 3.11
- [luarocks](https://luarocks.org/) 3.13.0
- [Saxon HE 12.10J](https://www.saxonica.com/documentation12/documentation.xml)
- [mathjax-full](https://www.mathjax.org/) 4.0.0
- [Pagedjs](https://pagedjs.org/) and [pagedjs-cli](https://github.com/pubpub/pagedjs-cli) 0.4.3 (with puppeteer 22.4.1)
- [WeasyPrint](https://weasyprint.org/) version 69.0
- [docxToJats](https://github.com/Vitaliy-1/docxToJats)
- [just](https://github.com/casey/just) 1.58.0 (for task execution)

Template files and other sources (e.g. css) are dereived from:

- Pandoc default templates
- Preview of [NISO JATS Publishing 1.0](https://jats.nlm.nih.gov/publishing/tag-library/1.0/) XML
- [NLM/NCBI  Journal Publishing 3.0](https://dtd.nlm.nih.gov/publishing/3.0/) Preview HTML
- Journal Publishing 3.0 APA-like Citation
- [NCBI Book Tag Set Version 2.2](https://jats.nlm.nih.gov/extensions/bits/2.2/dtd.html)

## Installation & Usage

### Installation

1. Download all files required to build and run the image/container (To use this repo in "production mode" you don't need to clone it to your host machine. This might only be necessary in case you want to develop new templates.):

    Linux/macOS (bash):
    ```bash
    wget https://raw.githubusercontent.com/ronste/sspworkflow/main/download.sh
    source download.sh
    ```

    Windows (PowerShell):
    ```powershell
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ronste/sspworkflow/main/download.ps1" -OutFile "download.ps1" ; .\download.ps1
    ```
2. Build the conainter image from inside the download directory according to your platform (e.g. Docker, Podman, ...) with the image name `sspworkflow:latest`, eg:
    - `docker build -t sspworkflow:latest .`
    - `podman build -t sspworkflow:latest .`

  Further examples will be for `podman` but should also work with `docker`

### Prepare working environment

1) Create a directory to hold all your working directories and files
2) Start the sspworkflow conatiner with:

    Linux/macOS (bash):
    ```bash
   . sspworkflow-run-prod.sh <your-container-name>` to start a container
    ```
    
    Windows (PowerShell):
    ```powershell
   & "sspworkflow-run-prod.ps1" -ContainerImage "sspworkflow:latest"`
   ```
     
    Note: If no container name is provided `sspworkflow` will be used.

3) Optional (PowerShell): enable tab completion for `runConversionChain`, `runConversionChain.ps1`, and `rcc`:

    ```powershell
    & "setup-completion.ps1" -ContainerName "sspworkflow"
    ```

    This creates a user completion file and updates your PowerShell profile to load it automatically.
4) Prepare your working directory by either copying a docx file into the folder `work` or, alternatively, run

    Linux/macOS (bash):
    ```bash
       runConversionChain.sh reset-jats-example
    ```
    
    Windows (PowerShell):
    ```powershell
       runConversionChain.ps1 reset-jats-example
    ```
to use the demo docx file.

The runConversionChain scripts (the alias `rcc` could also be used) are just a shortcut for the generalized command for accessing conatiner functions:
```bash
    podman exec <your container name> /bin/bash -c "cd /root/sspworkflow/work && runConversionChain <command>"
```

### Perfrom a docx converion

To run a full docx to pdf conversion a specifically prepared MS Word docx document needs to be placed inside the working directory. The docx document is requiered to use specific formating templates as explained in the [documentation](Documentation.md).
Please note that the default conversion chain (which handles metadata from the docx document) is optimized for docx -> Jats XML conversion via Pandoc (for customized conversion chains see [below](#how-to-run-a-custom-conversion-chain)).

Start the docx conversion with the following command: `runConversionChain`

This will create a range of intermediate and final files in the working directory which will be named according to the conversion step (tool) they are corresponding to. E.g. `<docx-filename>_SaxonHE.html` or `<docx-filename>_weasyprint.pdf`.

To get an overview of all options run:

`podman exec <your-container-name> /bin/bash -c "cd /root/sspworkflow/work && runConversionChain help"`

Windows PowerShell example (default container name):

`podman exec sspworkflow /bin/bash -c "cd /root/sspworkflow/work && runConversionChain help"`

or, with the helper scripts and alias (Linux and Windows Powershell):

`rcc help`

which will output something like:

```text
Usage: [ runConversionChain | just ] [ theme=<theme> | debug=true | validate=true | develop=true  | pagedjs-polyfill=true ] [ docx-file | xml-file | html-file =<filename> ] [ <recipe> ]

To run a recipe without its dependencies add a "-" to the recipes name, e.g. "weasyprint-"
If no docx file is provided the first docx file in the working dirctory will be taken.
If no recipe is provided the full conversion chain is run and all available versions of PDFs will be created.

Options:
    theme = <theme>: Selects a set of templates (i.e. a sub folder of the themes folder) to be used for conversion.
    debug = true: Enables the debug options of the different tools.
    validate = true: Runs an XML validation with xmllint.
    develop = true: Adds specific css rules to the conversion of HTML and PDF files to provide features for debugging and development of Print CSS conversion steps.
    docx-file | xml-file | html-file = <filename>: Specifies the path and name of the docx, xml or html source file to be converted.
    pagedjs-polyfill = true: Adds the Pagedjs polyfill to the final HTML output for debugging purpose.

Available recipes:
    all                   # run all conversions (default)
    bitsxml               # Convert docx to Bits XML (experimental, metadata not yet supported).
    cleanup-work          # Clean up the working directory removing all files in work and in work/media
    copy-work destination # Copies the full content of the work folder into a new folder inside the configured COPY_PATH folder
    docxtojats            # Generate Jats XML using the docxtojats converter
    html                  # Convert XML to HTML using Saxon HE 12
    mathjax               # Convert Mathl to CHTML using mathjax
    pagedjs               # Generate PDF using Pagedjs
    pandoc                # Convert docx to Jats XML using Pandoc.
    pandoc-bits           # Convert docx to Bits XML using Pandoc (experimental, metadata not yet supported).
    pandoc-pdf-html       # Generate PDF from HTML using Pandoc
    pandoc-pdf-xml        # Generate PDF from XML using Pandoc
    pdf                   # Generate PDF using Pandoc, Pagedjs and Weasyprint
    reset-bits-example    # Clean up the working directory and reset Bits XML example file
    reset-jats-example    # Clean up the working directory and reset Jats XML example file
    runtests              # Run different test scripts
    weasyprint            # Generate PDF using Weasyprint
    xml                   # Convert docx to XML using Pandoc + Saxon HE 12.
    xml-validate          # Validate XML file against DTD provided by DOCTYPE tag. Usage: "runConversionChain xml-validate <filename>"
```

More information on individual conversion steps may be available by running:

`docker exec <your-container-name> /bin/bash -c "cd /root/sspworkflow/work && runConversionChain help <recipe-name>`

### The default (docx-based) conversion chain

Running the runConversionChain command without any parameters will start the full chain of conversion from docx -> xml -> html -> pdf, including all versions of PDFs (created with Pandoc, PagedJs and Weasyprint).

However, each of these conversion steps can be selected individually. To only run a conversion from docx to HTML use:

`podman exec <your-container-name> /bin/bash -c "cd /root/sspworkflow/work && runConversionChain html"`

If, due to a previous run, the Jats XML buffer file requried to create the HTML output is already present in the working directory you can run the HTML conversion without its prior conversion steps by using:

`podman exec <your-container-name> /bin/bash -c "cd /root/sspworkflow/work && runConversionChain html-"`

Note that it is also possible to specify specific conversion chains directly by passing multiple recipe names to the`runConversionChain` command:

`podman exec <your-container-name> /bin/bash -c "cd /root/sspworkflow/work && runConversionChain pagedjs weasyprint"`

### Using custom themes

The sspworkflow container supports the definition of custom themes, i.e. different sets of templates, css and media files.
To create a custom theme create a copy of the folder `themes/default` within the themes folder.
You can then use the theme by providing the option `theme=<folder name>` and customize the templates inside this folder.

A theme may also contain its own justfile to define custom conversion steps. Not surprisingly, it should (but is not required to) import the main justfile. To run a conversion from this theme-specific justfile you directly specifiy the path to your custom justfile, e.g.:

`podman exec <your-container-name> /bin/bash -c "cd /root/sspworkflow/work && runConversionChain -f /root/sspworkflow/themes/default/justfile help"`

If you run the above command you find the additional recipes `custom-help` and `custom-example` were added.

You could e.g. define a step doing a Markdown to XML conversion with Pandoc to build your own Markdown -> Jats XML -> ... conversion chain for one particular theme.

### How to run a custom conversion chain

To run a custom conversion chain, e.g. not using the default Pandoc docx to Jats XML conversion, you can specifiy your conversion steps directly on the command line. In the following example docx to Jats XML conversion is facilitated by the [docxToJats converter](https://github.com/Vitaliy-1/docxToJats) and the resulting Jats XML file is subsequently passed through the default Jats XML -> HTML -> Weasyprint conversion steps.
The minus sign at the end of the subsequent recipe names is important in this use case, since it indicates that only the recipe without its default dependecies (which would be Pandoc) should be run.

`podman exec <your-container-name> /bin/bash -c "cd /root/sspworkflow/work && runConversionChain docxtojats html- weasyprint-"`

### How to run conversion chains not based on docx documents

By specifying a XML or HTML input file on the command line you can inject your own source file into a custom conversion chain. The following command e.g. performs an `xml -> html -> pdf` conversion without requiring a docx file:

`podman exec <your-container-name> /bin/bash -c "cd /root/sspworkflow/work && runConversionChain xml-file='Dummy_Article_Template.docx_SaxonHE.xml' html- weasyprint-"`

Please don't forget to put all dependent files into the media folder.

## How to develop, debug and test Print CSS stylesheets

To help with developing and debugging Print CSS stylesheets the develop=true option is available. This will add special css to the conversion process that may help you to identify possible issues.

The applied CSS, e.g., will color backgrounds for the html and body tags and add borders to the Print CSS page margin boxes. You can see these in the Pdf files and with the Pagedjs polyfill option.

You can also view the HTML file in print mode in Firefox. To do so open the developer tools and go to the Inspector tab. In the upper right corner of the styles section enable the icon "Toggle print media simulation for the page".
This will show the HTML file with all @media print styles enabled (but without pagination) and you can inspect any issues interactively.

For specifically debugging Pagedjs issues you can add the Pagedjs polyfill to you HTML file by using the option `pagedjs-polyfill=true`.
However, please not that the Pagedjs polyfill and pagedjs-cli (as currently used for the conversion) might behave differently under some circumstances (see below).

An empty HTML template that loads the development CSS and the Pagedjs polyfill is provided with the file `themes\default\templates\html_template_printcss.html`. You can inspect this file with your browser to learn about the basic Print CSS page layout. Note however, that Pagedjs and Weasyprint handle these layout elements differently!

To run a set of different tests use:

`podman exec \<your-container-name> /bin/bash -c "cd /root/sspworkflow/work && runConversionChain runtests"

## How to handle Mathjax fonts

For handling Mathjax fonts see [here](https://docs.mathjax.org/en/v4.0/output/fonts.html).

## Next steps

- Continuous imporovements of template files
- Implementation of a web app to provide a REST-API to handle [Dar packages](https://github.com/substance/dar)
- considering pagedjs polyfill vs pagedjs-cli
- revise handling of resource files between themes
- pull lua filters from https://codeberg.org/pandoc/metadata-table/src/branch/main/metadata-table.lua

## Known issues

- As of Pandoc version 3.1.12.2 the Pandoc HTML reader complains about unclosed HTML tags (used to work with Pandoc 3.1.11). Therefore the HTML -> PDF conversion with Pandoc is currently broken.
- Pajedjs dependencies are deprecated. Pajedjs has been disabled.

## Version history

1.1 New recipes added
1.2 Added feature to define theme-specific custom conversion steps
1.3 Added docxtojats converter, added mathjay, runtests and xml-validate recipes
1.6 Major version updates

## Disclaimer

This repo is developed in the context of the services offered by Berlin Universities Publishing Journals (operated by the University Library FU Berlin) and licensed under GNU GENERAL PUBLIC LICENSE Version 3.
