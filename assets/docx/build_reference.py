"""Build assets/docx/reference.docx, the branded Word reference document.

Run:  uv run --with python-docx python assets/docx/build_reference.py

Starts from Pandoc's default reference.docx (via Quarto's bundled pandoc) and
restyles it with the site's brand tokens. Fonts are kept to ones present on
every Word install (Calibri body, Segoe UI headings, Consolas code) because
fonts cannot be embedded through Pandoc.
"""
import copy
import subprocess
import tempfile
from pathlib import Path

from docx import Document
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn
from docx.shared import Inches, Pt

OUT = Path(__file__).with_name("reference.docx")

NAVY = "0E171E"
CREAM_DARK = "F8F6ED"
ORANGE = "D96E34"
LINK = "B8531F"
BORDER = "E8E5DC"
MUTED = "6C757D"
BODY_FONT = "Calibri"
HEAD_FONT = "Segoe UI"
CODE_FONT = "Consolas"


def base_docx(path):
    data = subprocess.run(
        ["quarto", "pandoc", "--print-default-data-file", "reference.docx"],
        check=True, capture_output=True, shell=True,
    ).stdout
    Path(path).write_bytes(data)


def get_style(doc, name, style_type=1):
    for s in doc.styles:
        if s.name == name:
            return s
    s = doc.styles.add_style(name, style_type)
    return s


def clear(style, *tags):
    """Remove given child elements from a style's pPr/rPr."""
    for parent_tag in ("w:pPr", "w:rPr"):
        parent = style.element.find(qn(parent_tag))
        if parent is None:
            continue
        for t in tags:
            for el in parent.findall(qn(t)):
                parent.remove(el)


def font(style, name=None, size=None, color=None, bold=None, italic=None):
    f = style.font
    if name:
        f.name = name
        rpr = style.element.get_or_add_rPr()
        rf = rpr.find(qn("w:rFonts"))
        for a in ("w:asciiTheme", "w:hAnsiTheme", "w:eastAsiaTheme", "w:cstheme"):
            if rf.get(qn(a)) is not None:
                del rf.attrib[qn(a)]
        rf.set(qn("w:ascii"), name)
        rf.set(qn("w:hAnsi"), name)
        rf.set(qn("w:cs"), name)
    if size:
        f.size = Pt(size)
    if color:
        from docx.shared import RGBColor
        f.color.rgb = RGBColor.from_string(color)
    if bold is not None:
        f.bold = bold
    if italic is not None:
        f.italic = italic


def para(style, before=None, after=None, line=None, left=None, right=None,
         keep_next=None, align=None, first=None):
    pf = style.paragraph_format
    if before is not None:
        pf.space_before = Pt(before)
    if after is not None:
        pf.space_after = Pt(after)
    if line is not None:
        pf.line_spacing = line
    if left is not None:
        pf.left_indent = Pt(left)
    if right is not None:
        pf.right_indent = Pt(right)
    if first is not None:
        pf.first_line_indent = Pt(first)
    if keep_next is not None:
        pf.keep_with_next = keep_next
    if align is not None:
        pf.alignment = align


def ppr_xml(style, xml):
    """Append raw pPr children (borders, shading) respecting schema order."""
    ppr = style.element.get_or_add_pPr()
    for el in parse_xml(f"<w:pPr {nsdecls('w')}>{xml}</w:pPr>"):
        for old in ppr.findall(el.tag):
            ppr.remove(old)
        ppr.append(el)
    order = ["pStyle", "keepNext", "keepLines", "pageBreakBefore", "framePr",
             "widowControl", "numPr", "suppressLineNumbers", "pBdr", "shd",
             "tabs", "suppressAutoHyphens", "kinsoku", "wordWrap",
             "overflowPunct", "topLinePunct", "autoSpaceDE", "autoSpaceDN",
             "bidi", "adjustRightInd", "snapToGrid", "spacing", "ind",
             "contextualSpacing", "mirrorIndents", "suppressOverlap", "jc",
             "textDirection", "textAlignment", "textboxTightWrap",
             "outlineLvl", "divId", "cnfStyle", "rPr", "sectPr", "pPrChange"]
    kids = list(ppr)
    kids.sort(key=lambda e: order.index(e.tag.split("}")[1])
              if e.tag.split("}")[1] in order else 99)
    for k in kids:
        ppr.remove(k)
    for k in kids:
        ppr.append(k)


def bdr(side, color, sz=4, space=1):
    return f'<w:{side} w:val="single" w:sz="{sz}" w:space="{space}" w:color="{color}"/>'


def set_tbl_style(style, xml):
    tblpr = style.element.find(qn("w:tblPr"))
    if tblpr is not None:
        style.element.remove(tblpr)
    for el in style.element.findall(qn("w:tblStylePr")):
        style.element.remove(el)
    style.element.append(parse_xml(xml))


def main():
    tmp = Path(tempfile.mkdtemp()) / "base.docx"
    base_docx(tmp)
    doc = Document(str(tmp))
    st = doc.styles

    # docDefaults: body font
    rpr_def = st.element.find(qn("w:docDefaults")).find(qn("w:rPrDefault")).find(qn("w:rPr"))
    rf = rpr_def.find(qn("w:rFonts"))
    for a in list(rf.attrib):
        del rf.attrib[a]
    for a in ("ascii", "hAnsi", "cs", "eastAsia"):
        rf.set(qn("w:" + a), BODY_FONT)

    # ---- Body ----
    normal = st["Normal"]
    font(normal, BODY_FONT, 11, NAVY)
    para(normal, before=0, after=0, line=1.25)
    for n, b, a in (("Body Text", 6, 8), ("First Paragraph", 0, 8), ("Compact", 1, 1)):
        s = st[n]
        font(s, BODY_FONT, 11, NAVY)
        para(s, before=b, after=a, line=1.25)

    # ---- Title block: navy banner ----
    t = st["Title"]
    font(t, HEAD_FONT, 26, "FFFBF2", bold=True)
    para(t, before=0, after=0, line=1.1, left=0, align=0, keep_next=True)
    ppr_xml(t, f'<w:pBdr>{bdr("top", NAVY, 4, 12)}{bdr("left", NAVY, 4, 8)}'
               f'{bdr("bottom", ORANGE, 24, 10)}{bdr("right", NAVY, 4, 8)}</w:pBdr>'
               f'<w:shd w:val="clear" w:color="auto" w:fill="{NAVY}"/>'
               f'<w:spacing w:before="0" w:after="160" w:line="264" w:lineRule="auto"/>'
               f'<w:ind w:left="170" w:right="170"/>')
    for n in ("Subtitle", "Author", "Date", "Abstract Title", "Abstract"):
        try:
            st[n].base_style = st["Normal"]
        except KeyError:
            pass
    sub = st["Subtitle"]
    font(sub, HEAD_FONT, 14, MUTED, bold=False, italic=False)
    para(sub, before=0, after=6, line=1.2, keep_next=True, align=0)
    for n in ("Author", "Date"):
        s = st[n]
        font(s, BODY_FONT, 11, NAVY, bold=(n == "Author"), italic=False)
        para(s, before=0, after=2, align=0, keep_next=True)
    st["Date"].font.color.rgb = __import__("docx").shared.RGBColor.from_string(MUTED)
    ab = st["Abstract Title"] if "Abstract Title" in [s.name for s in st] else get_style(doc, "Abstract Title")
    font(ab, HEAD_FONT, 11, ORANGE, bold=True)
    ab.font.all_caps = True
    para(ab, before=14, after=2, keep_next=True, align=0)
    a = get_style(doc, "Abstract")
    a.base_style = st["Normal"]
    font(a, BODY_FONT, 11, NAVY, italic=False)
    para(a, before=0, after=10, line=1.25, left=14, right=14)
    ppr_xml(a, f'<w:pBdr>{bdr("left", ORANGE, 18, 10)}</w:pBdr>'
               f'<w:shd w:val="clear" w:color="auto" w:fill="{CREAM_DARK}"/>')

    # ---- Headings ----
    sizes = {1: (20, 20, 6), 2: (16, 16, 4), 3: (13.5, 12, 3),
             4: (12, 10, 2), 5: (11, 8, 2), 6: (11, 8, 2)}
    for i, (sz, bef, aft) in sizes.items():
        h = st[f"Heading {i}"]
        font(h, HEAD_FONT, sz, NAVY, bold=True, italic=False)
        para(h, before=bef, after=aft, line=1.15, keep_next=True, left=0, first=0)
        clear(h, "w:ind") if False else None
        if i == 5:
            font(h, color=MUTED)
        if i == 6:
            font(h, color=MUTED, italic=True)
        if i in (1, 2):
            ppr_xml(h, f'<w:pBdr>{bdr("bottom", BORDER, 8 if i == 1 else 6, 4)}</w:pBdr>')

    # ---- Block quote ----
    bq = st["Block Text"]
    font(bq, BODY_FONT, 11, MUTED, italic=True)
    para(bq, before=6, after=8, line=1.25, left=14, right=14)
    ppr_xml(bq, f'<w:pBdr>{bdr("left", ORANGE, 24, 10)}</w:pBdr>')

    # ---- Code ----
    vc = st["Verbatim Char"]
    font(vc, CODE_FONT, 9.5, NAVY)
    vc.element.get_or_add_rPr().append(parse_xml(
        f'<w:shd {nsdecls("w")} w:val="clear" w:color="auto" w:fill="{CREAM_DARK}"/>'))
    sc = get_style(doc, "Source Code"); sc.base_style = st["Normal"]
    font(sc, CODE_FONT, 9, NAVY)
    para(sc, before=6, after=10, line=1.15, left=6, right=6)
    ppr_xml(sc, f'<w:pBdr>{bdr("top", BORDER, 4, 6)}{bdr("left", BORDER, 4, 6)}'
                f'{bdr("bottom", BORDER, 4, 6)}{bdr("right", BORDER, 4, 6)}</w:pBdr>'
                f'<w:shd w:val="clear" w:color="auto" w:fill="{CREAM_DARK}"/>'
                f'<w:wordWrap w:val="1"/>')
    # Verbatim shading inside code blocks is redundant; tokens inherit it, fine.

    # ---- Table ----
    set_tbl_style(st["Table"], f'''<w:tblPr {nsdecls("w")}>
      <w:tblInd w:w="0" w:type="dxa"/>
      <w:tblBorders>
        <w:top w:val="single" w:sz="8" w:space="0" w:color="{NAVY}"/>
        <w:bottom w:val="single" w:sz="8" w:space="0" w:color="{NAVY}"/>
        <w:insideH w:val="single" w:sz="4" w:space="0" w:color="{BORDER}"/>
      </w:tblBorders>
      <w:tblCellMar><w:top w:w="60" w:type="dxa"/><w:left w:w="100" w:type="dxa"/>
        <w:bottom w:w="60" w:type="dxa"/><w:right w:w="100" w:type="dxa"/></w:tblCellMar>
    </w:tblPr>''')
    st["Table"].element.append(parse_xml(f'''<w:tblStylePr {nsdecls("w")} w:type="firstRow">
      <w:rPr><w:b/><w:color w:val="{NAVY}"/></w:rPr>
      <w:tcPr><w:tcBorders><w:bottom w:val="single" w:sz="12" w:space="0" w:color="{NAVY}"/>
      </w:tcBorders></w:tcPr></w:tblStylePr>'''))

    # ---- Captions ----
    for n in ("Table Caption", "Image Caption", "Caption"):
        c = st[n]
        font(c, BODY_FONT, 9.5, MUTED, italic=True, bold=False)
        para(c, before=4, after=10, line=1.15)
    st["Table Caption"].paragraph_format.keep_with_next = True
    st["Table Caption"].paragraph_format.space_before = Pt(10)
    st["Table Caption"].paragraph_format.space_after = Pt(4)
    cf = st["Captioned Figure"]
    para(cf, before=8, after=0, keep_next=True, align=1)
    fg = st["Figure"]
    para(fg, before=8, after=0, keep_next=True, align=1)

    # ---- Links, footnotes ----
    hl = st["Hyperlink"]
    font(hl, color=LINK)
    hl.font.underline = False
    ft = st["Footnote Text"]
    font(ft, BODY_FONT, 9, MUTED)
    para(ft, before=0, after=2, line=1.1)
    fr = st["Footnote Reference"]
    font(fr, color=LINK)
    for n in ("Definition Term",):
        font(st[n], bold=True)

    # ---- TOC ----
    th = st["TOC Heading"]
    font(th, HEAD_FONT, 14, NAVY, bold=True)
    para(th, before=18, after=6, keep_next=True)
    ppr_xml(th, f'<w:pBdr>{bdr("bottom", BORDER, 6, 4)}</w:pBdr>')
    for lvl, ind in ((1, 0), (2, 14), (3, 28)):
        s = get_style(doc, f"TOC {lvl}")
        s.base_style = st["Normal"]
        s.next_paragraph_style = st["Normal"]
        font(s, BODY_FONT, 11 if lvl == 1 else 10.5, NAVY if lvl == 1 else MUTED,
             bold=(lvl == 1))
        para(s, before=4 if lvl == 1 else 0, after=2, line=1.15, left=ind)
        s.element.set(qn("w:customStyle"), "0")
        s.hidden = False
        ppr_xml(s, '<w:tabs><w:tab w:val="right" w:leader="dot" w:pos="9350"/></w:tabs>')

    # ---- Header / footer / page ----
    sec = doc.sections[0]
    sec.page_width, sec.page_height = Inches(8.5), Inches(11)
    sec.left_margin = sec.right_margin = Inches(1)
    sec.top_margin = sec.bottom_margin = Inches(1)
    sec.header_distance = sec.footer_distance = Inches(0.5)

    hdr_style = get_style(doc, "Header")
    ftr_style = get_style(doc, "Footer")
    for s in (hdr_style, ftr_style):
        s.base_style = st["Normal"]
        font(s, BODY_FONT, 9, MUTED)
        para(s, before=0, after=0, line=1.0)
    tabs = '<w:tabs><w:tab w:val="clear" w:pos="4680"/><w:tab w:val="clear" w:pos="9360"/><w:tab w:val="right" w:pos="9360"/></w:tabs>'
    ppr_xml(hdr_style, tabs + f'<w:pBdr>{bdr("bottom", BORDER, 4, 4)}</w:pBdr>')
    ppr_xml(ftr_style, tabs + f'<w:pBdr>{bdr("top", BORDER, 4, 4)}</w:pBdr>')

    sec.header.is_linked_to_previous = False
    hp = sec.header.paragraphs[0]
    hp.style = hdr_style
    for r in list(hp.runs):
        r._r.getparent().remove(r._r)
    hp.add_run("Pukar Bhandari").bold = True
    hp.add_run("\tar-puuk.github.io")

    sec.footer.is_linked_to_previous = False
    fp = sec.footer.paragraphs[0]
    fp.style = ftr_style
    fp.add_run("ar-puuk.github.io\tPage ")
    run = fp.add_run()
    for kind, text in (("begin", None), (None, " PAGE "), ("end", None)):
        if kind:
            el = OxmlElement("w:fldChar")
            el.set(qn("w:fldCharType"), kind)
        else:
            el = OxmlElement("w:instrText")
            el.set(qn("xml:space"), "preserve")
            el.text = text
        run._r.append(el)

    doc.save(str(OUT))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
