// Layout helpers for the CV (cv/index.qmd), measured from the Word-exported reference PDF
// (US Letter, 11 pt Times New Roman).
//
// Text lines have zero height (top and bottom edge = baseline), so a paragraph's `leading` is
// the exact baseline-to-baseline distance and a block's `above` gap is the exact distance from
// the previous baseline to this block's first baseline. Weak block spacing is dropped at the
// top of a page, so a section that starts a page sits on the top margin.

#let serif = ("Times New Roman", "Liberation Serif")
#let pitch = 12.65pt // Word's single line spacing for 11 pt Times New Roman
#let blue = rgb("#0000ff")

#let setup(body) = {
  set page(paper: "us-letter", margin: (top: 54.4pt, bottom: 43pt, x: 36pt), numbering: none)
  set text(font: serif, size: 11pt, fill: black, lang: "en", top-edge: 0pt, bottom-edge: 0pt)
  set par(leading: pitch, spacing: pitch, justify: false)
  set block(spacing: 0pt)
  body
}

// Underlined link: blue in the body, black in the header
#let ul(url, body, color: blue) = link(url, text(fill: color, underline(offset: 1.2pt, stroke: 0.5pt + color, evade: false, body)))

// An icon that takes up width but no height, so it cannot push the baseline around
#let ico(name, w: 14pt, h: 14pt, iw: auto) = box(width: w, height: 0pt, place(bottom + left, image("/assets/icons/" + name + ".svg", width: if iw == auto { w } else { iw }, height: h, fit: "contain")))

// Header: name and the contact line
#let header(name, ..items) = {
  v(3.8pt, weak: false)
  align(center, text(size: 16pt, weight: "bold")[#name])
  block(above: 17pt, width: 100%, align(center, text(size: 12pt)[#items.pos().join[ | ]]))
}

// Contact item: icon, a space, then the text
#let contact(icon, w, ht, body) = [#ico(icon, w: w, h: ht) #h(2.6pt) #body]

// Section heading: icon, upper-case bold title and a heavy rule. `before` is the gap from the
// previous baseline, `after` the gap to the first baseline of the content.
#let section(icon, title, before: 26pt, after: 16pt, w: 15pt, h: 15pt, iw: auto, gap: 2.8pt) = {
  block(above: before, width: 100%, below: 0pt)[
    #text(weight: "bold")[#ico(icon, w: w + gap, iw: if iw == auto { w } else { iw }, h: h)#upper(title)]
    #v(3.1pt)
    #move(dx: -1.4pt, line(length: 100% + 2.9pt, stroke: 1.4pt))
  ]
  v(after - 3.1pt, weak: true)
}

// Entry heading: bold organisation and place on the first line, italic role and dates on the
// second. `before` is the gap from the previous baseline.
#let entry(org, where, role, dates, before: 21.6pt) = block(above: before, width: 100%, below: 0pt)[
  #text(weight: "bold")[#org] #h(1fr) #where \
  #emph[#role] #h(1fr) #emph[#dates]
]

// A line with a bold lead and a right-aligned date (volunteering)
#let item(lead, role, dates, before: 15.7pt) = block(above: before, width: 100%, below: 0pt)[
  #text(weight: "bold")[#lead] | #emph[#role] #h(1fr) #dates
]

// Bullet with a hanging indent. `x` is where the bullet sits; the text starts 18 pt later.
#let bullet(body, before: 13.5pt, pitch: pitch, x: 54pt, glyph: "•") = block(above: before, below: 0pt, width: 100%, pad(left: x + 18pt - 36pt, {
  set par(leading: pitch)
  place(dx: -18pt, glyph)
  body
}))

// The same, for a block of bullets that share a pitch and gap
#let bullets(pitch: pitch, before: 13.5pt, first: 13.5pt, x: 54pt, ..items) = for (i, it) in items.pos().enumerate() {
  bullet(it, before: if i == 0 { first } else { before }, pitch: pitch, x: x)
}

#let sub(body, before: pitch) = bullet(body, before: before, x: 81pt, glyph: "–")
