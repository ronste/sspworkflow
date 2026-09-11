# Documentation BerlinUP Books Theme

This theme takes different docx files as input and creates a BITS XML output file.

## How it works

Each part of the book, i.e. chapters and other sections of the book body have to be provided as separate docx files with a table header containing the metadata. Each metadata table has to contain a "type" entry specifying the the value to be used for BITS book-part-type attribute. This is required to assemble the book parts in the correct structure. 

The theme currently supports the following recipes:

- **assembleBook**
  Creates a BITS XML file for the complete book from XML files located in the `templates` folder. Requires a contents-metadata.yaml file to be present in the `templates` folder. The contents-metadata.yaml should list the different parts of the books in correct order:
  ```yaml
  content:
  - "Beitrag1.docx"
  - "prefacePart1.docx"
  - "Beitrag2.docx"
  - "Beitrag3.docx"
  - "Beitrag4.docx"
  - "prefacePart2.docx"
  - "Beitrag5.docx"
  - "Beitrag6.docx"
  - "Beitrag7.docx"
  ```

- **convertBookChapter**
  Creates a BITS XML <book-part> element from the selected docx file (chapter or other part) and copies it to the `templates`folder.
- **convertAllChapters"
  Runs **convertChapter** for each docx file listed in `templates/contents-metadata.yaml`
- **reset-work**
  Removes all XML files from the working directory (not the `templates` folder) and resets yaml files to theme defaults.

## How to run a conversion

To convert a single book part run the `convertBookChapter` recipe:

```bash
runConversionChain theme=BerlinUP_Books convertBookChapter
runConversionChain theme=BerlinUP_Books docx-file=EditionAVL_Band03_BeitragMix.docx convertBookChapter
```

If you do not provide a docx file name the first docx file will be used. 

Edit or create the file `templates/contents-metadata.yaml` as describe above.

To finally assemble the full BITS XML file run:

```bash
runConversionChain theme=BerlinUP_Books docx-file=EditionAVL_Band03_Gesamtband.docx assembleBook
```

To run the full conversion chain at once use:

```bash
runConversionChain theme=BerlinUP_Books docx-file=EditionAVL_Band03_Gesamtband.docx convertAllChapters assembleBook
```