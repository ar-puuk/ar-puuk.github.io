-- Pilot: maps a plain-Markdown CV onto the helpers in cv-style.typ.
--
--   # Title {icon=... before=.. after=.. w=.. h=.. iw=..}   -> #section(...)
--   ## Org {.entry place=.. role=.. dates=.. before=..}     -> #entry(...)
--   ## Lead {.item role=.. dates=.. before=..}              -> #item(...)
--   ### Role {.subentry dates=.. before=..}                 -> the italic role/dates line
--   a bullet list right after one of those headings          -> #bullet(...) calls, tuned by
--     the heading's first / gap / pitch / x / subfirst attributes
--   [text]{.nobreak}                                         -> #box[text]
--   links                                                    -> #ul("url")[text]  (blue underline)
-- Numeric attributes are points. role / place / dates are parsed as Markdown.
-- The name and contact line come from the cv-name / cv-contact YAML keys.

local stringify = pandoc.utils.stringify

local function esc(s)
  s = s:gsub('\\', '\\\\')
  s = s:gsub('"', '\\"')
  return s
end

local function trim(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end

local function pt(v) return v .. 'pt' end

local function blocks_to_typst(blocks)
  return trim(pandoc.write(pandoc.Pandoc(blocks), 'typst'))
end

-- Inline rewrites: links and spans become calls to the Typst helpers
local link_pass = {
  Link = function(l)
    local out = { pandoc.RawInline('typst', '#ul("' .. esc(l.target) .. '")[') }
    for _, i in ipairs(l.content) do out[#out + 1] = i end
    out[#out + 1] = pandoc.RawInline('typst', ']')
    return out
  end,
}
local span_pass = {
  Span = function(s)
    if s.classes:includes('nobreak') then
      local out = { pandoc.RawInline('typst', '#box[') }
      for _, i in ipairs(s.content) do out[#out + 1] = i end
      out[#out + 1] = pandoc.RawInline('typst', ']')
      return out
    end
  end,
}

local function rewrite(doc)
  return doc:walk(link_pass):walk(span_pass)
end

-- An attribute value (Markdown) as Typst content
local function md_attr(s)
  local d = rewrite(pandoc.read(s, 'markdown-smart'))
  return blocks_to_typst(d.blocks)
end

local function inlines_to_typst(inlines)
  return blocks_to_typst({ pandoc.Plain(inlines) })
end

local function named(a, keys)
  local parts = {}
  for _, k in ipairs(keys) do
    if a[k] then parts[#parts + 1] = k .. ': ' .. pt(a[k]) end
  end
  return table.concat(parts, ', ')
end

local function bullets(list, a)
  local out = {}
  for idx, item in ipairs(list.content) do
    local head, nested = {}, nil
    for _, blk in ipairs(item) do
      if blk.t == 'BulletList' then nested = blk else head[#head + 1] = blk end
    end
    local before = (idx == 1) and (a.first or '13.5') or (a.gap or '13.5')
    local p = { 'before: ' .. pt(before) }
    if a.pitch then p[#p + 1] = 'pitch: ' .. pt(a.pitch) end
    if a.x then p[#p + 1] = 'x: ' .. pt(a.x) end
    out[#out + 1] = '#bullet(' .. table.concat(p, ', ') .. ')[' .. blocks_to_typst(head) .. ']'
    if nested then
      for j, s in ipairs(nested.content) do
        local sp = (j == 1 and a.subfirst) and ('before: ' .. pt(a.subfirst)) or ''
        out[#out + 1] = '#sub(' .. sp .. ')[' .. blocks_to_typst(s) .. ']'
      end
    end
  end
  return table.concat(out, '\n')
end

local function header_block(meta)
  if not meta['cv-name'] then return nil end
  local items = {}
  for _, c in ipairs(meta['cv-contact']) do
    local text = '#"' .. esc(stringify(c.text)) .. '"'
    if c.url then text = '#ul("' .. esc(stringify(c.url)) .. '", color: black)[' .. text .. ']' end
    items[#items + 1] = 'contact("' .. stringify(c.icon) .. '", 10.5pt, 10.5pt)[' .. text .. ']'
  end
  return pandoc.RawBlock('typst',
    '#header("' .. esc(stringify(meta['cv-name'])) .. '",\n  ' .. table.concat(items, ',\n  ') .. ')')
end

function Pandoc(doc)
  doc = rewrite(doc)
  local out = {}
  local hb = header_block(doc.meta)
  if hb then out[#out + 1] = hb end

  local blocks = doc.blocks
  local i = 1
  while i <= #blocks do
    local b = blocks[i]
    local call = nil
    if b.t == 'Header' then
      local a = b.attributes
      local cls = b.classes
      if b.level == 1 then
        local extra = named(a, { 'before', 'after', 'w', 'h', 'iw' })
        call = '#section("' .. (a.icon or '') .. '", "' .. esc(stringify(b.content)) .. '"' ..
          (extra ~= '' and (', ' .. extra) or '') .. ')'
      elseif cls:includes('entry') then
        local extra = named(a, { 'before' })
        call = '#entry([' .. inlines_to_typst(b.content) .. '], [' .. md_attr(a.place) .. '], [' ..
          md_attr(a.role) .. '], [' .. md_attr(a.dates) .. ']' .. (extra ~= '' and (', ' .. extra) or '') .. ')'
      elseif cls:includes('item') then
        local extra = named(a, { 'before' })
        call = '#item([' .. inlines_to_typst(b.content) .. '], [' .. md_attr(a.role) .. '], [' ..
          md_attr(a.dates) .. ']' .. (extra ~= '' and (', ' .. extra) or '') .. ')'
      elseif cls:includes('subentry') then
        call = '#block(above: ' .. pt(a.before or '21.6') .. ', width: 100%)[#emph[' ..
          inlines_to_typst(b.content) .. '] #h(1fr) #emph[' .. md_attr(a.dates) .. ']]'
      end
      if call then
        out[#out + 1] = pandoc.RawBlock('typst', call)
        local nxt = blocks[i + 1]
        if nxt and nxt.t == 'BulletList' then
          out[#out + 1] = pandoc.RawBlock('typst', bullets(nxt, a))
          i = i + 1
        end
      end
    end
    if not call then out[#out + 1] = b end
    i = i + 1
  end
  return pandoc.Pandoc(out, doc.meta)
end
