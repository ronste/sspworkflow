# Documentation BerlinUP Books Theme

This theme takes different docx files as input and creates a BITS XML output file.

## How it works

Each part of the book, i.e. chapters and other sections of the book body have to be provided as separate docx files with a table header containing the metadata.

The theme currently supports the following recipes:

- **assembleBook**
  Creates a BITS XML file for the complete book from XML files located in the `templates` folder. Requires a contents-metadata.yaml file to be present in the `templates` folder. The contents-metadata.yaml should list the different parts of the books in correct order:
  ```yaml
  content:
  - "`EditionAVL_Band03_BeitragMix.docx`{=latex}"
  - prefacePart1
  - chapter1
  - chapter2
  - chapter3
  - prefacePart2
  - chapter4
  - chapter5
  - chapter6
  ```
  Note: Avoid underscores in the file name as pandoc escapes them. If you have to use underscorse, to avoid pandoc escaping underscores use the above shown syntax.
- **convertBookChapter**
  Creates a BITS XML <book-part> element from the selected docx file (chapter or other part) and copies it to the `templates`folder.
- **reset-work**
  Removes all XML files from the working directory (not the `templates` folder) and resets yaml files to theme defaults.

## How to run a conversion

To convert a single book part run the `convertBookChapter` recipe:

```bash
runConversionChain theme=BerlinUP_Books convertBookChapter
runConversionChain theme=BerlinUP_Books docx-file=EditionAVL_Band03_BeitragMix.docx convertBookChapter
```

If you do not provide a docx file name the first docx file will be used. Repeat this for every part of the book. (We may implement conversion of a complete folder of docx files later.)

Edit or create the file `templates/contents-metadata.yaml` as describe above.

To finally assemble the full BITS XML file run:

```bash
runConversionChain theme=BerlinUP_Books docx-file=EditionAVL_Band03_Gesamtband.docx assembleBook
```