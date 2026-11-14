-- Link row at the top of a research article page, built from the same `pub-info.links`
-- front matter the Research listing uses, so each article keeps one list of links.
-- A link marked `listing-only: true` (e.g. Add to Zotero) is left off the article page.
-- Local files (`local: true`) are relative to the article folder, which is also where the
-- rendered page lives, so their url works as written.

local function str(v) return v and pandoc.utils.stringify(v) or "" end

local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

function Pandoc(doc)
  if not FORMAT:match("html") then return nil end
  local info = doc.meta["pub-info"]
  local links = info and info.links
  if not links then return nil end

  local items = {}
  for _, link in ipairs(links) do
    if str(link["listing-only"]) ~= "true" then
      table.insert(items, string.format(
        '<li><a href="%s"><i class="%s"></i> %s</a></li>',
        esc(str(link.url)), esc(str(link.icon)), esc(str(link.name))))
    end
  end
  if #items == 0 then return nil end

  local html = '<ul class="pub-links">' .. table.concat(items) .. '</ul>'
  table.insert(doc.blocks, 1, pandoc.RawBlock("html", html))
  return doc
end
