-- Two extra callout types on top of Quarto's five:
--   ::: {.callout-success}   green, a check in a filled circle
--   ::: {.callout-fail}      red, an x in a filled circle
-- Quarto only knows note, tip, important, caution and warning, so each variant is rewritten
-- to its closest built-in type (tip, important) plus a marker class (pb-success, pb-fail).
-- The built-in type gives every format a sensible fallback (Typst, Word, PDF); the HTML theme
-- recolours it and swaps the icon through the marker class. A title is supplied when the
-- callout has neither a `title` attribute nor a leading heading.

local variants = {
  success = { base = "callout-tip",       title = "Success" },
  fail    = { base = "callout-important", title = "Failed"  },
}

function Div(el)
  for name, v in pairs(variants) do
    local cls = "callout-" .. name
    if el.classes:includes(cls) then
      -- rebuild the list: assigning into el.classes in place does not stick
      local classes = pandoc.List()
      for _, c in ipairs(el.classes) do
        if c ~= cls then classes:insert(c) end
      end
      classes:insert(v.base)
      classes:insert("pb-" .. name)
      el.classes = classes
      local first = el.content[1]
      if not el.attributes["title"] and not (first and first.t == "Header") then
        el.attributes["title"] = v.title
      end
      return el
    end
  end
end
