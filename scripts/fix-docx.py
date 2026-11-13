"""Post-render step: left-align code in the Word (docx) versions of the posts.

Quarto writes `<w:jc w:val="center"/>` directly onto every code paragraph of a captioned listing
(a chunk with `lst-cap`), so the code comes out centred line by line in Word. Direct formatting
outranks styles, so the reference document cannot fix it; this removes that one attribute from
paragraphs that use the SourceCode style. Nothing else in the file is touched.

Quarto runs this after a full render (see `post-render` in _quarto.yml). It never fails the
render: any problem is reported and skipped.
"""
import os
import re
import shutil
import sys
import tempfile
import zipfile

OUTPUT_DIR = os.environ.get("QUARTO_PROJECT_OUTPUT_DIR", "docs")
CENTERED_CODE = re.compile(r'(<w:pStyle w:val="SourceCode"\s*/>)\s*<w:jc w:val="center"\s*/>')


def fix(path):
    with zipfile.ZipFile(path) as zin:
        xml = zin.read("word/document.xml").decode("utf-8")
        fixed, n = CENTERED_CODE.subn(r"\1", xml)
        if n == 0:
            return 0
        fd, tmp = tempfile.mkstemp(suffix=".docx", dir=os.path.dirname(path))
        os.close(fd)
        with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
            for item in zin.infolist():
                data = fixed.encode("utf-8") if item.filename == "word/document.xml" else zin.read(item.filename)
                zout.writestr(item, data)
    shutil.move(tmp, path)
    return n


def main():
    total = files = 0
    for root, _, names in os.walk(OUTPUT_DIR):
        for name in names:
            if not name.endswith(".docx"):
                continue
            path = os.path.join(root, name)
            try:
                n = fix(path)
            except Exception as err:  # keep the render going
                print(f"fix-docx: skipped {path}: {err}", file=sys.stderr)
                continue
            if n:
                files += 1
                total += n
    print(f"fix-docx: left-aligned {total} code paragraph(s) in {files} Word file(s)")


if __name__ == "__main__":
    main()
