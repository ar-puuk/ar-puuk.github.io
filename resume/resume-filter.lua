-- Maps the plain-Markdown resume onto the helpers in resume-style.typ.
--
--   ::: {.main} ... :::  and  ::: {.side} ... :::   the two panels (use both, main first)
--   ## Title {.role org=.. place=.. dates=..}        -> #role(...)
--   ## Name {.degree before=..}                      -> #degree(...)  (bold education line)
--   # Title {before=..}                              -> gap above, in pt, when it is not the usual one
--   [text]{.ul}                                      -> #ul[text]  (underlined label)
--   resume-name / resume-title / resume-contact      -> #resume-header(...) at the top
-- Everything else (#, ##, ###, lists, paragraphs) is styled by the show rules in resume-style.typ.

local stringify = pandoc.utils.stringify

local function esc(s)
  s = s:gsub('\\', '\\\\')
  s = s:gsub('"', '\\"')
  return s
end

local function trim(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end

local function blocks_to_typst(blocks)
  return trim(pandoc.write(pandoc.Pandoc(blocks), 'typst'))
end

local ul_pass = {
  Span = function(s)
    if s.classes:includes('ul') then
      local out = { pandoc.RawInline('typst', '#ul[') }
      for _, i in ipairs(s.content) do out[#out + 1] = i end
      out[#out + 1] = pandoc.RawInline('typst', ']')
      return out
    end
  end,
}

local function md_inline(s)
  return blocks_to_typst(pandoc.read(s, 'markdown-smart'):walk(ul_pass).blocks)
end

local function header_block(meta)
  if not meta['resume-name'] then return nil end
  local items = {}
  for _, c in ipairs(meta['resume-contact']) do
    local url = c.url and ('"' .. esc(stringify(c.url)) .. '"') or 'none'
    items[#items + 1] = '("' .. stringify(c.icon) .. '", "' .. esc(stringify(c.text)) .. '", ' .. url .. ')'
  end
  return pandoc.RawBlock('typst',
    '#resume-header("' .. esc(stringify(meta['resume-name'])) .. '", "' .. esc(stringify(meta['resume-title'])) ..
    '", (' .. table.concat(items, ', ') .. ',))')
end

local function head(b) return blocks_to_typst({ pandoc.Plain(b.content) }) end

-- Rewrites headings inside a list of blocks into calls to the Typst helpers
local function convert(blocks)
  local out = {}
  for _, b in ipairs(blocks) do
    if b.t == 'Header' and b.classes:includes('role') then
      local a = b.attributes
      out[#out + 1] = pandoc.RawBlock('typst', '#role([' .. head(b) .. '], [' ..
        md_inline(a.org) .. '], [' .. md_inline(a.place) .. '], [' .. md_inline(a.dates) .. '])')
    elseif b.t == 'Header' and b.classes:includes('degree') then
      out[#out + 1] = pandoc.RawBlock('typst', '#degree(before: ' .. (b.attributes.before or '0') ..
        ', [' .. head(b) .. '])')
    elseif b.t == 'Header' then
      local fn = ({ 'section', 'group', 'sub' })[math.min(b.level, 3)]
      local before = b.attributes.before and ('before: ' .. b.attributes.before .. ', ') or ''
      out[#out + 1] = pandoc.RawBlock('typst', '#' .. fn .. '(' .. before .. '[' .. head(b) .. '])')
    else
      out[#out + 1] = b
    end
  end
  return out
end

function Pandoc(doc)
  doc = doc:walk(ul_pass)
  local out = {}
  local hb = header_block(doc.meta)
  if hb then out[#out + 1] = hb end

  for _, b in ipairs(doc.blocks) do
    if b.t == 'Div' and b.classes:includes('main') then
      out[#out + 1] = pandoc.RawBlock('typst', '#panels([')
      for _, c in ipairs(convert(b.content)) do out[#out + 1] = c end
      out[#out + 1] = pandoc.RawBlock('typst', '],')
    elseif b.t == 'Div' and b.classes:includes('side') then
      out[#out + 1] = pandoc.RawBlock('typst', '[')
      for _, c in ipairs(convert(b.content)) do out[#out + 1] = c end
      out[#out + 1] = pandoc.RawBlock('typst', '])')
    else
      out[#out + 1] = b
    end
  end
  return pandoc.Pandoc(out, doc.meta)
end
