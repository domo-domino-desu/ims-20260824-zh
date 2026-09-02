-- PDF-specific cleanup for structures produced by the knitr/Quarto pipeline.

local function trim_citation_spacing(citation)
  while #citation.prefix > 0 and citation.prefix[#citation.prefix].tag == "Space" do
    citation.prefix:remove(#citation.prefix)
  end
  while #citation.suffix > 0 and citation.suffix[1].tag == "Space" do
    citation.suffix:remove(1)
  end
end

local function is_crossref_id(id)
  return id:match("^sec%-") or id:match("^fig%-") or
         id:match("^tbl%-") or id:match("^eq%-")
end

local function render_crossref(cite)
  for _, citation in ipairs(cite.citations) do
    trim_citation_spacing(citation)
  end
  -- Quarto's cross-reference renderer inserts nonbreaking spaces between its
  -- Chinese label and the number.  Emit only the numbered reference here;
  -- source text supplies “第…章/节”“图…” and “表…” without word spaces.
  if FORMAT:match("latex") and #cite.citations == 1 then
    local citation = cite.citations[1]
    local id = citation.id
    if is_crossref_id(id) then
      local prefix = pandoc.utils.stringify(citation.prefix):gsub("%s+", "")
      local suffix = pandoc.utils.stringify(citation.suffix):gsub("%s+", "")
      if id:match("^fig%-") then
        prefix, suffix = "图", ""
      elseif id:match("^tbl%-") then
        prefix, suffix = "表", ""
      elseif id:match("^eq%-") then
        prefix, suffix = "式", ""
      elseif prefix:match("附录") then
        prefix, suffix = "附录", ""
      else
        prefix = "第"
        suffix = suffix:match("章") and "章" or "节"
      end
      return pandoc.RawInline(
        "latex",
        prefix .. "\\ref{" .. id .. "}" .. suffix
      )
    end
  end
end

function Cite(cite)
  local rendered = render_crossref(cite)
  if rendered then
    return rendered
  end
  return cite
end

local function is_crossref(inline)
  if inline.tag == "RawInline" and inline.format == "latex" then
    for _, kind in ipairs({"sec", "fig", "tbl", "eq"}) do
      if inline.text:match("\\ref{" .. kind .. "%-") then
        return true
      end
    end
  end
  if inline.tag ~= "Cite" then
    return false
  end
  for _, citation in ipairs(inline.citations) do
    if is_crossref_id(citation.id) then
      return true
    end
  end
  return false
end

function Inlines(inlines)
  -- Chinese prose does not use word spaces around cross-references.  Remove
  -- only spaces adjacent to Quarto cross-references; author-year citations
  -- retain their normal spacing.
  local rendered = pandoc.List()
  for _, inline in ipairs(inlines) do
    if inline.tag == "Cite" then
      rendered:insert(render_crossref(inline) or inline)
    else
      rendered:insert(inline)
    end
  end

  local cleaned = pandoc.List()
  for i, inline in ipairs(rendered) do
    local previous_is_crossref = i > 1 and is_crossref(rendered[i - 1])
    local next_is_crossref = i < #rendered and is_crossref(rendered[i + 1])
    local stray_cell_marker = inline.tag == "Str" and (
      inline.text:match("^:::+$") or
      inline.text:match("^%{%.cell.-%}$")
    )
    if not stray_cell_marker and
       (inline.tag ~= "Space" or (not previous_is_crossref and not next_is_crossref)) then
      cleaned:insert(inline)
    end
  end
  return cleaned
end

function Header(header)
  -- Quarto 1.4 injects an unnumbered “Appendices” division after loading the
  -- project language metadata.  Localize that generated division directly;
  -- setting `lang: zh` would unnecessarily activate Babel for LuaLaTeX.
  if pandoc.utils.stringify(header.content) == "Appendices" then
    header.content = pandoc.Inlines({pandoc.Str("附录")})
    return header
  end
end

function CodeBlock(block)
  -- knitr indents cell wrappers inside long exercise lists.  Pandoc can then
  -- mistake the generated fenced div for literal code and print the `:::`
  -- markers.  Parse only those known generated cells back into Markdown.
  if FORMAT:match("latex") and block.text:match("^:::+%s+{%.cell[%s}]") then
    local output = pandoc.List()
    for line in (block.text .. "\n"):gmatch("(.-)\n") do
      if not line:match("^:::+") then
        local path, width = line:match("^!%[%]%((.-)%)%{width=([%d.]+)%%%}%s*$")
        if path then
          output:insert(string.format(
            "\\begin{center}\\includegraphics[width=%.2f\\linewidth]{%s}\\end{center}",
            tonumber(width) / 100,
            path
          ))
        else
          line = line:gsub(
            "%[([^%]]+)%]%((https?://[^%)]+)%)",
            "\\href{%2}{%1}"
          )
          output:insert(line)
        end
      end
    end
    return pandoc.RawBlock("latex", table.concat(output, "\n"))
  end
end
