// Resume layout: a header, then a main panel and a side panel separated by a rule.
// Loaded by include-before-body in index.qmd; resume-filter.lua calls resume-header and panels.
//
// Measured from the Word-exported reference (US Letter, 612 x 792 pt, 9.96 pt Source Sans 3).
// Text lines have zero height (top/bottom edge = baseline), so `leading` is the exact
// baseline-to-baseline distance and a block's `above`/`below` is the exact distance between
// baselines. Every size is in em, so the whole page scales together when it has to shrink.
//
// Single page: `panels` tries font sizes from `max-size` downwards and keeps the largest one at
// which both panels fit. If even `min-size` does not fit, the build stops with a message.

#let ink = rgb("#3a3a3a")
#let gray-name = rgb("#595959")
#let gray-bar = rgb("#aeaeae")
#let gray-rule = rgb("#747474")

#let max-size = 9.96pt
#let min-size = 8.4pt
#let pitch = 13.833

// A length measured at the nominal size, as em so it scales with the text
#let u(x) = x / 9.96 * 1em

#let ul(body) = underline(offset: 0.96pt, stroke: 0.48pt + ink, evade: false, body)

#let setup(body) = {
  set page(paper: "us-letter", margin: (top: 36pt, bottom: 32.3pt, left: 29.04pt, right: 24.85pt), numbering: none)
  set text(font: "Source Sans 3", size: max-size, fill: ink, lang: "en", top-edge: 0pt, bottom-edge: 0pt)
  set par(leading: u(pitch), spacing: u(pitch), justify: false)
  set block(spacing: 0pt)
  set list(
    marker: box(width: 18pt)[#text(size: 1.3em, baseline: -0.15em)[•]#h(1fr)],
    indent: 18pt, body-indent: 0pt, spacing: u(14.04), tight: false,
  )

  body
}

// Section heading, group heading (skills) and sub heading inside a job
#let section(body, before: 27.84) = block(above: u(before), below: u(14.4), sticky: true,
  text(size: u(12), weight: "bold", fill: black, tracking: 0.085em, upper(body)))
#let group(body, before: 17.6) = block(above: u(before), below: u(16.32), sticky: true,
  text(size: u(10.56), weight: "bold", body))
#let sub(body, before: 13.9) = block(above: u(before), below: u(14.06), sticky: true, pad(left: 18pt, strong(body)))

// Job title line and the place / dates line under it
#let role(title, org, place, dates) = {
  block(above: u(17.6), below: u(16.35), sticky: true, text(size: u(10.56))[*#title |* #org])
  block(below: u(18.5), sticky: true, text(fill: gray-name)[#place | #emph(dates)])
}

// Bold line that starts an education entry; `before` is the gap from the previous baseline
#let degree(body, before: 0) = block(above: u(before), below: u(13.8), sticky: true, strong(body))

// Header: bar, name, title, and the contact grid
#let icon(name) = box(width: 13pt, height: 11pt, image("/assets/icons/" + name + ".svg", height: 11pt, fit: "contain"))

#let resume-header(name, title, contacts) = {
  let parts = name.split(" ")
  let cell(c) = {
    let t = if c.at(2) == none { c.at(1) } else { ul(link(c.at(2), c.at(1))) }
    (place(top + left, dy: -9.2pt, icon(c.at(0))), t)
  }
  let cells = contacts.map(cell).flatten()
  block(width: 100%, height: 64.5pt, {
    place(top + left, dx: 7pt, rect(width: 7.2pt, height: 46pt, fill: gray-bar, stroke: none))
    place(top + left, dx: 25pt, dy: 19.7pt,
      text(size: 20.04pt, weight: "bold", tracking: 1.14pt)[#text(fill: black)[#parts.first()] #text(fill: gray-name)[#parts.slice(1).join(" ")]])
    place(top + left, dx: 25pt, dy: 38.9pt, text(size: 14.04pt, tracking: 0.1pt)[#title])
    place(top + left, dx: 280pt, dy: 9.5pt,
      grid(columns: (19.9pt, 96.3pt, 22.7pt, auto), rows: 15.84pt, ..cells))
  })
}

// Main panel and side panel, with the rule between them, shrunk (if needed) to fit the page
#let panels(main, side) = block(width: 100%, height: 1fr, layout(size => {
  let w1 = 361.4pt
  let w2 = size.width - w1 - 14.5pt - 10.25pt
  let height(c, w, s) = measure(text(size: s, block(width: w, pad(top: 11pt, c)))).height
  let sizes = range(0, 40).map(i => max-size - i * 0.1pt).filter(s => s >= min-size)
  let s = sizes.find(s => calc.max(height(main, w1, s), height(side, w2, s)) <= size.height)
  if s == none {
    panic("The resume does not fit on one page even at " + repr(min-size) + ". Shorten the content.")
  }
  set text(size: s)
  grid(
    columns: (w1, 14.5pt, 10.25pt, 1fr), rows: (size.height,),
    grid.vline(x: 2, stroke: 0.75pt + gray-rule),
    pad(top: 11pt, main), [], [], pad(top: 11pt, side),
  )
}))

// Applied to the whole document (loaded by include-before-body in index.qmd)
#show: setup
