# Fonts for the PDF (Typst) output

Typst reads TrueType files, while the website serves Poppins and Fira Code as web fonts, so the
PDF renders get their own copies here. `posts/_metadata.yml` points Quarto at this folder
(`font-paths`).

- Poppins (400, 500, 600, with italics) and Fira Code (400, 500) are licensed under the SIL Open
  Font License 1.1, which allows redistribution with the project: https://openfontlicense.org
- Poppins 700 is not included; headings use SemiBold (600).
- The TTFs were copied from the WFRCAnalytics/wfrc-brand Quarto extension.
