// Branded Typst template for the PDF versions of the site's pages.
//
// This is Quarto's own typst-template.typ (same `article` function, same parameters, same
// TOC / list-of-figures handling) with the site's look added on top, so the PDFs stay
// recognisably Quarto documents and keep working across Quarto updates as long as the
// partial contract (`article`, `callout`) is unchanged. Look-and-feel only: if Quarto's
// template changes upstream, diff against
//   <quarto>/share/formats/typst/pandoc/quarto/typst-template.typ
//
// Added here:
//   - brand colours (below) and a navy title banner echoing the website's title banner
//   - running header (from page 2) and a footer with page numbers and the site address
//   - heading, code, table, quote, caption and outline styling
//   - callouts redrawn like the website's: tinted body, tinted title strip, bar on the left,
//     per-type colours from the site palette (Quarto's fixed colours are remapped)
// The page margins live in YAML (`margin:`) and must match page-mx / page-my below.

// ------------------------------------------------------------------ Brand tokens
#let ink = rgb("#0E171E")          // navy: text and banner
#let cream = rgb("#FFFBF2")
#let accent = rgb("#D96E34")       // orange
#let accent-text = rgb("#B8531F")  // orange that holds small text on white (5.0:1)
#let accent-soft = rgb("#F2A27A")  // orange for text on navy
#let rule-c = rgb("#E8E5DC")       // hairlines
#let surface = rgb("#F8F6ED")      // code blocks
#let muted = rgb("#5F6B76")        // secondary text (5.4:1 on white)
#let on-navy = rgb("#A3B8C6")      // secondary text on the banner
#let page-mx = 0.9in
#let page-my = 0.85in
#let heading-fonts = ("Poppins", "Libertinus Serif")

// Site palette for callouts, keyed by the colour Quarto emits for each type
#let callout-palette = (
  (match: rgb("#0758E5"), color: rgb("#007EA7")),  // note
  (match: rgb("#00A047"), color: rgb("#2E8B62")),  // tip
  (match: rgb("#CC1914"), color: rgb("#C0392B")),  // important
  (match: rgb("#EB9113"), color: rgb("#C28A00")),  // warning
  (match: rgb("#FC5300"), color: rgb("#8A3F6B")),  // caution
)

#let article(
  title: none,
  subtitle: none,
  description: none,
  categories: (),
  authors: none,
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: none,
  fontsize: 9.5pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: none,
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  lof: false,
  lof-title: none,
  lot: false,
  lot-title: none,
  doc,
) = {
  // Set document metadata for PDF accessibility
  set document(title: title, keywords: keywords)
  set document(
    author: authors.map(author => content-to-string(author.name)).join(", ", last: " & "),
  ) if authors != none and authors != ()
  set par(
    justify: false,
    leading: linestretch * 0.72em,
    spacing: 1em,
  )
  set text(lang: lang,
           region: region,
           size: fontsize,
           fill: ink)
  set text(font: font) if font != none
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: codefont) if codefont != none

  set heading(numbering: sectionnumbering)

  show link: set text(fill: rgb(content-to-string(linkcolor))) if linkcolor != none
  show ref: set text(fill: rgb(content-to-string(citecolor))) if citecolor != none
  show link: this => {
    if filecolor != none and type(this.dest) == label {
      text(this, fill: rgb(content-to-string(filecolor)))
    } else {
      text(this)
    }
   }

  let has-title-block = title != none or (authors != none and authors != ()) or date != none or abstract != none
  if has-title-block {
    place(
      top,
      float: true,
      scope: "parent",
      clearance: 7mm,
      {
        // Navy banner, bled to the page edges, like the website's title banner
        block(
          width: 100%,
          fill: ink,
          outset: (x: page-mx, top: page-my),
          inset: (x: 0pt, top: 4pt, bottom: 16pt),
          below: 0pt,
        )[
          #set par(leading: 0.5em, spacing: 0.8em, justify: false)
          #set text(fill: cream)

          #if categories != none and categories != () {
            block(below: 11pt)[
              #for c in categories {
                box(
                  stroke: 0.5pt + accent-soft.transparentize(45%),
                  radius: 2pt,
                  inset: (x: 5pt, y: 2.5pt),
                  outset: (y: 0pt),
                  text(size: 7pt, fill: cream.transparentize(12%))[#c],
                )
                h(3pt)
              }
            ]
          }

          #if title != none {
            block(below: 8pt)[
              #set text(font: heading-fonts, weight: 600)
              #text(size: 22pt)[#title #if thanks != none {
                footnote(thanks, numbering: "*")
                counter(footnote).update(n => n - 1)
              }]
            ]
            if subtitle != none {
              block(below: 8pt, text(font: heading-fonts, size: 11.5pt, fill: cream.transparentize(14%))[#subtitle])
            }
          }

          #if description != none {
            block(below: 12pt, width: 88%, text(size: 8.5pt, fill: accent-soft)[#description])
          }

          #if (authors != none and authors != ()) or date != none {
            set text(size: 8.5pt, fill: on-navy)
            let who = if authors != none and authors != () {
              authors.map(a => {
                strong(text(fill: cream)[#a.name])
                if not empty(a.affiliation) [ #h(2pt) #a.affiliation]
              }).join(h(14pt))
            }
            who
            if who != none and date != none [ #h(14pt) ]
            if date != none [#date]
          }
        ]
        // the accent rule that closes the banner
        move(dx: -page-mx, rect(width: 100% + 2 * page-mx, height: 3pt, fill: accent, stroke: none))

        if abstract != none {
          block(inset: (top: 1.4em, bottom: 0.4em))[
            #text(weight: 600)[#abstract-title] #h(1em) #abstract
          ]
        }
      }
    )
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if lof {
    block(above: 0em, below: 2em)[
    #outline(title: lof-title, target: figure.where(kind: "quarto-float-fig"));
    ]
  }

  if lot {
    block(above: 0em, below: 2em)[
    #outline(title: lot-title, target: figure.where(kind: "quarto-float-tbl"));
    ]
  }

  doc
}

// ------------------------------------------------------------------ Page furniture
// The first page carries the banner, so the running header starts on page 2.
#set page(
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 7.5pt, fill: muted, font: heading-fonts)
      grid(
        columns: (auto, 1fr),
        align: (left, right),
        strong[Pukar Bhandari],
        context document.title,
      )
      v(-4pt)
      line(length: 100%, stroke: 0.5pt + rule-c)
    }
  },
  header-ascent: 38%,
  footer: context {
    set text(size: 7.5pt, fill: muted, font: heading-fonts)
    line(length: 100%, stroke: 0.5pt + rule-c)
    v(-2pt)
    grid(
      columns: (1fr, auto),
      align: (left, right),
      [#link("https://ar-puuk.github.io")[ar-puuk.github.io] #h(8pt) Made with Quarto],
      counter(page).display("1 / 1", both: true),
    )
  },
  footer-descent: 30%,
)

// ------------------------------------------------------------------ Headings
#show heading: it => {
  let sizes = (15pt, 12.5pt, 10.5pt, 9.5pt)
  block(
    above: if it.level == 1 { 2em } else { 1.6em },
    below: if it.level == 1 { 0.9em } else { 0.7em },
    sticky: true,
  )[
    #set text(font: heading-fonts, weight: 600, fill: ink, size: sizes.at(it.level - 1, default: 9.5pt))
    #if it.numbering != none {
      text(fill: accent-text)[#counter(heading).display(it.numbering)]
      h(0.55em)
    }
    #it.body
    #if it.level == 1 {
      v(-0.35em)
      line(length: 100%, stroke: 0.6pt + rule-c)
    }
  ]
}

// ------------------------------------------------------------------ Code
// Pandoc draws highlighted code (blocks AND inline code) from per-token calls that each wrap a
// `raw`, so no `raw` selector can tell a block from inline code; styling a raw rule would box
// every token. Instead, plain (unhighlighted) blocks get the block rule below, and highlighted
// blocks are drawn by redefining Quarto's `Skylighting` function with the site's surface.
#show raw: set text(size: 0.9em)
#show raw.where(block: true): set block(
  fill: surface,
  stroke: 0.5pt + rule-c,
  radius: 3pt,
  width: 100%,
  inset: (x: 9pt, y: 8pt),
)

#let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
  let blocks = []
  let lnum = start - 1
  for ln in sourcelines {
    if number {
      lnum = lnum + 1
      blocks = blocks + box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ]))
    }
    blocks = blocks + ln + EndLine()
  }
  block(
    fill: surface,
    stroke: 0.5pt + rule-c,
    width: 100%,
    inset: (x: 9pt, y: 8pt),
    radius: 3pt,
    breakable: true,
    blocks,
  )
}

// ------------------------------------------------------------------ Quotes, tables, captions
#show quote.where(block: true): it => block(
  inset: (left: 11pt, y: 3pt),
  stroke: (left: 2.5pt + accent),
  below: 1em,
)[
  #set text(fill: muted)
  #it.body
]

#set table(
  inset: (x: 7pt, y: 6pt),
  stroke: (x, y) => (bottom: if y == 0 { 0.9pt + ink } else { 0.4pt + rule-c }),
)
#show table.cell.where(y: 0): set text(weight: 600)

#show figure.caption: set text(size: 8pt, fill: muted)

#show outline.entry.where(level: 1): it => {
  v(0.5em, weak: true)
  strong(it)
}

// ------------------------------------------------------------------ Callouts
// Same signature and block nesting as Quarto's own `callout` (its crossref machinery takes the
// block apart by position), restyled: a bar on the left, a tinted title strip over a lighter
// tinted body, in the site's colours.
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  let tone = callout-palette.find(p => p.match == icon_color)
  let c = if tone != none { tone.color } else { icon_color }
  let strip = color.mix((c, 16%), (white, 84%))
  let wash = color.mix((c, 7%), (white, 93%))
  block(
    breakable: false,
    fill: wash,
    stroke: (left: (paint: c, thickness: 3pt)),
    width: 100%,
    radius: (right: 4pt),
    clip: true,
    block(
      inset: 1pt,
      width: 100%,
      below: 0pt,
      block(
        fill: strip,
        width: 100%,
        inset: (x: 9pt, y: 6.5pt))[#if icon != none [#box(fill: c, radius: 50%, inset: (x: 3.2pt, y: 3pt), baseline: 25%, text(white, size: 6pt, weight: 900)[#icon]) #h(2pt) ]#text(font: heading-fonts, weight: 600)[#title]]) +
      if(body != []){
        block(
          inset: 1pt,
          width: 100%,
          block(fill: wash, width: 100%, inset: (x: 9pt, y: 8pt), body))
      }
    )
}
