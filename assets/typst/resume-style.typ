// Measured from the Word-exported reference PDF (US Letter, 612 x 792 pt).
// Lines have zero height (top/bottom edge = baseline), so `pitch` is the exact
// baseline-to-baseline distance and `v(g)` after a paragraph is the exact gap
// from its last baseline to the next block's first baseline.
#let ink = rgb("#3a3a3a")
#let gray-name = rgb("#595959")
#let gray-bar = rgb("#aeaeae")
#let gray-rule = rgb("#747474")
#let pitch = 13.833pt

#let ul(body) = underline(offset: 0.96pt, stroke: 0.48pt + ink, evade: false, body)

// Absolute placement of a block whose first baseline sits at page y = `y`
#let at(x, y, w: auto, body) = place(top + left, dx: x, dy: y, box(width: w, {
  set text(fill: ink, top-edge: 0pt, bottom-edge: 0pt)
  set par(leading: pitch, spacing: 0pt, justify: false)
  body
}))

#let heading(body) = text(size: 12pt, weight: "bold", fill: black, tracking: 1.02pt, upper(body))
#let role(title, org) = {
  text(size: 10.56pt)[*#title |* #org]
}
#let bullet(body) = pad(left: 36.02pt, {
  h(-18.02pt)
  box(width: 18.02pt)[#text(size: 1.3em, baseline: -0.15em)[•]]
  body
})
#let sub(body) = pad(left: 18pt, strong(body))
#let group(body) = text(size: 10.56pt, weight: "bold")[#body]
#let sk(label, value) = [#ul(label) #emph(value)]
#let loc(place, dates) = text(fill: gray-name)[#place | #emph(dates)]

#let icon(name, x, y, w, h) = place(top + left, dx: x, dy: y, image("/assets/icons/" + name + ".svg", width: w, height: h))
