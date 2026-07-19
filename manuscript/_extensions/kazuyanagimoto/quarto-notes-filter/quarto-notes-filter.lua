
--[[
quarto-notes-filter
-------------------
Adds AER-style "Notes:" text below a figure caption or a table.

Usage
-----
Figure:
  ![Caption](img.png){#fig-x fig-notes="Source: ..." fig-notes-title="Notes:"}

Executable cell producing a figure:
  #| fig-cap: "My caption"
  #| fig-notes: "Source: ..."

Markdown table:
  | a | b |
  |---|---|
  | 1 | 2 |

  : Caption {#tbl-x tbl-notes="Source: ..." tbl-notes-title="Notes:"}

Document-level defaults (YAML front matter):
  fig-notes-title: "Notes:"   # default "Notes:"
  fig-notes-scale: 0.9        # default 0.9 (fraction of body fontsize)
  tbl-notes-title: "Notes:"   # default "Notes:"
  tbl-notes-scale: 0.9        # default 0.9
]]

local default_fig_title = "Notes:"
local default_fig_scale = 0.9
local default_tbl_title = "Notes:"
local default_tbl_scale = 0.9

-- Document-level defaults.
function Meta(meta)
  if meta["fig-notes-title"] ~= nil then
    default_fig_title = pandoc.utils.stringify(meta["fig-notes-title"])
  end
  if meta["fig-notes-scale"] ~= nil then
    local s = tonumber(pandoc.utils.stringify(meta["fig-notes-scale"]))
    if s ~= nil then default_fig_scale = s end
  end
  if meta["tbl-notes-title"] ~= nil then
    default_tbl_title = pandoc.utils.stringify(meta["tbl-notes-title"])
  end
  if meta["tbl-notes-scale"] ~= nil then
    local s = tonumber(pandoc.utils.stringify(meta["tbl-notes-scale"]))
    if s ~= nil then default_tbl_scale = s end
  end
end

-- Parse a string of inline markdown into a Pandoc Inlines list.
local function parse_inlines(s)
  if s == nil or s == "" then return pandoc.Inlines({}) end
  local doc = pandoc.read(s, "markdown")
  return pandoc.utils.blocks_to_inlines(doc.blocks)
end

-- Escape text so it can sit inside a Typst content block `[ ... ]`.
local function typst_escape(s)
  return (s:gsub("\\", "\\\\")
           :gsub("%[", "\\[")
           :gsub("%]", "\\]"))
end

-- Build a list of Inlines that renders the notes line in Typst. The
-- notes content is passed through as real Pandoc Inlines (rather than
-- being pre-serialized via `pandoc.write`) so that any `Cite` or
-- cross-reference inlines survive intact and are later resolved by
-- Quarto's citeproc / crossref filters. `above_em` controls the gap
-- above the notes block.
local function build_typst_notes(title, notes_inlines, scale, above_em)
  local title_typ = typst_escape(title)
  local open = pandoc.RawInline("typst", string.format(
    "\n#block(width: 100%%, above: %sem, below: 0.5em)[#align(left)[#set text(size: %sem); #set par(justify: false, leading: 0.42em, spacing: 0em, first-line-indent: 0pt); #emph[%s] ",
    tostring(above_em), tostring(scale), title_typ
  ))
  local close = pandoc.RawInline("typst", "]]")
  local result = pandoc.Inlines({ open })
  for _, inl in ipairs(notes_inlines) do result:insert(inl) end
  result:insert(close)
  return result
end

-- LaTeX font-size command for a given scale relative to the body fontsize.
-- Approximate mapping at 10pt body:
--   \scriptsize    ~ 7pt    (0.7em)
--   \footnotesize  ~ 8pt    (0.8em)
--   \small         ~ 9pt    (0.9em, AER-style default)
--   \normalsize    ~ 10pt   (1.0em)
local function latex_size_cmd(scale)
  if scale <= 0.75 then return "\\scriptsize"
  elseif scale <= 0.85 then return "\\footnotesize"
  elseif scale <= 0.95 then return "\\small"
  elseif scale <= 1.05 then return "\\normalsize"
  else return "\\large"
  end
end

-- Escape a plain string for LaTeX.
local function latex_escape(s)
  return (s:gsub("\\", "\\textbackslash{}")
           :gsub("([&%%$#_{}])", "\\%1")
           :gsub("~", "\\textasciitilde{}")
           :gsub("%^", "\\textasciicircum{}"))
end

-- Build LaTeX notes Inlines intended to be injected at the end of a
-- figure caption.
local function build_latex_fig_notes(title, notes_inlines, scale)
  local title_tex = latex_escape(title)
  local size_cmd = latex_size_cmd(scale)
  local open = pandoc.RawInline("latex", string.format(
    "\\newline\\rule{0pt}{1.6ex}\\newline\\protect\\parbox[t]{\\linewidth}{\\raggedright %s\\emph{%s} ",
    size_cmd, title_tex
  ))
  local close = pandoc.RawInline("latex", "}")
  local result = pandoc.Inlines({ open })
  for _, inl in ipairs(notes_inlines) do result:insert(inl) end
  result:insert(close)
  return result
end

-- Track whether the global LaTeX captionsetup has been injected
-- (we only need it once per document).
local latex_captionsetup_injected = false

-- Inject (once) a global LaTeX `\captionsetup{...}` so that the figure
-- caption is rendered ragged-right with no hanging indent. This is
-- needed because our injected notes paragraph turns the caption into
-- multi-line content, and the `caption` package's default multi-line
-- behavior is to hang-indent under the label ("Figure N:"), which
-- would push the notes paragraph in from the figure's left edge.
local function inject_latex_captionsetup()
  if latex_captionsetup_injected then return end
  latex_captionsetup_injected = true
  quarto.doc.include_text(
    "in-header",
    "\\captionsetup{format=plain,justification=centering,singlelinecheck=off,indention=0pt}\n"
  )
end


-- Escape a plain string for HTML attribute / text contexts.
local function html_escape(s)
  return (s:gsub("&", "&amp;")
           :gsub("<", "&lt;")
           :gsub(">", "&gt;"))
end

-- Build HTML notes Inlines. `class_name` lets callers distinguish
-- figure-notes vs table-notes for CSS purposes; `above_em` controls
-- the top margin.
local function build_html_notes(title, notes_inlines, scale, class_name, above_em)
  local title_html = html_escape(title)
  local style = string.format(
    "margin-top:%sem;text-align:left;font-size:%sem;",
    tostring(above_em), tostring(scale)
  )
  local open = pandoc.RawInline("html", string.format(
    '<div class="%s" style="%s"><em>%s</em> ',
    class_name, style, title_html
  ))
  local close = pandoc.RawInline("html", "</div>")
  local result = pandoc.Inlines({ open })
  for _, inl in ipairs(notes_inlines) do result:insert(inl) end
  result:insert(close)
  return result
end

-- Build Inlines that go *inside* a table foot cell (i.e. a cell
-- spanning all columns), to be appended at the very bottom of the
-- table -- in the spirit of `tinytable`'s `notes` option: the note
-- sits directly beneath the table's bottom rule with no gap, rather
-- than floating below the entire `table` environment.
local function build_tbl_foot_inlines(title, notes_inlines, scale, format)
  local result = pandoc.Inlines({})
  if format == "latex" then
    local size_cmd = latex_size_cmd(scale)
    result:insert(pandoc.RawInline("latex", string.format(
      "%s\\emph{%s} ", size_cmd, latex_escape(title))))
    for _, inl in ipairs(notes_inlines) do result:insert(inl) end
  elseif format == "typst" then
    result:insert(pandoc.RawInline("typst", string.format(
      "#set par(justify: false, leading: 0.56em, spacing: 0em, first-line-indent: 0pt); #text(size: %sem)[#emph[%s] ",
      tostring(scale), typst_escape(title))))
    for _, inl in ipairs(notes_inlines) do result:insert(inl) end
    result:insert(pandoc.RawInline("typst", "]"))
  elseif format == "html" then
    result:insert(pandoc.RawInline("html",
      string.format("<em>%s</em> ", html_escape(title))))
    for _, inl in ipairs(notes_inlines) do result:insert(inl) end
  end
  return result
end

local function find_image(blocks)
  if blocks == nil then return nil end
  for _, b in ipairs(blocks) do
    if b.t == "Plain" or b.t == "Para" then
      for _, inl in ipairs(b.content) do
        if inl.t == "Image" then return inl end
      end
    elseif b.t == "Div" then
      local r = find_image(b.content)
      if r then return r end
    end
  end
  return nil
end

-- Side table populated by the `Div` pass for executable code cells,
-- keyed by the figure identifier (e.g. "fig-scatter"). Quarto silently
-- strips unrecognised attributes such as `fig-notes` from the image
-- element while constructing the float, so we have to stash the
-- attribute values out-of-band and look them up again in
-- `FloatRefTarget` by the float's identifier.
local pending_fig_notes = {}

-- Append a list of Inlines to the float's caption (figure case).
local function append_to_caption(float, inlines)
  if float.caption_long == nil then
    float.caption_long = pandoc.Plain(inlines)
    return
  end
  if float.caption_long.t == "Plain" or float.caption_long.t == "Para" then
    for _, inl in ipairs(inlines) do
      float.caption_long.content:insert(inl)
    end
    return
  end
  float.caption_long.content:insert(pandoc.Plain(inlines))
end

-- Handle a figure float with fig-notes set on its image (markdown image
-- syntax), on the float itself, or stashed by the `Div` pass for
-- executable code cells.
local function handle_figure(float)
  local content_blocks = quarto.utils.as_blocks(float.content)
  local img = find_image(content_blocks)

  -- Resolve the source of the notes attributes, in priority order:
  --   1. the image's own attributes (markdown `![](...){fig-notes=...}`)
  --   2. the float's attributes
  --   3. attributes captured by the `Div` pass from a wrapping `.cell`
  --      Div produced by an executable code cell, looked up by the
  --      inner image's `src` (since Quarto strips the image identifier
  --      and discards unknown image attributes during float
  --      construction, but the image src is preserved).
  local attr_holder = nil
  local pending = nil
  if img ~= nil and img.attributes["fig-notes"] ~= nil
      and img.attributes["fig-notes"] ~= "" then
    attr_holder = img.attributes
  elseif float.attributes ~= nil
      and float.attributes["fig-notes"] ~= nil
      and float.attributes["fig-notes"] ~= "" then
    attr_holder = float.attributes
  elseif img ~= nil and img.src ~= nil
      and pending_fig_notes[img.src] ~= nil then
    pending = pending_fig_notes[img.src]
    pending_fig_notes[img.src] = nil
  else
    return nil
  end

  local notes_raw, title, scale
  if pending ~= nil then
    notes_raw = pending.notes
    title = pending.title or default_fig_title
    scale = tonumber(pending.scale or "") or default_fig_scale
  else
    notes_raw = attr_holder["fig-notes"]
    title = attr_holder["fig-notes-title"] or default_fig_title
    scale = tonumber(attr_holder["fig-notes-scale"] or "") or default_fig_scale
    attr_holder["fig-notes"] = nil
    attr_holder["fig-notes-title"] = nil
    attr_holder["fig-notes-scale"] = nil
  end

  local notes_inlines = parse_inlines(notes_raw)

  if quarto.doc.is_format("typst") then
    append_to_caption(float, build_typst_notes(title, notes_inlines, scale, 0.8))
    return float
  end

  if quarto.doc.is_format("latex") or quarto.doc.is_format("pdf") then
    inject_latex_captionsetup()
    append_to_caption(float, build_latex_fig_notes(title, notes_inlines, scale))
    return float
  end

  if quarto.doc.is_format("html") then
    append_to_caption(float,
      build_html_notes(title, notes_inlines, scale, "quarto-figure-notes", 1.5))
    return float
  end

  return nil
end

-- Recursively find the first Table block inside a list of blocks.
local function find_table(blocks)
  if blocks == nil then return nil end
  for _, b in ipairs(blocks) do
    if b.t == "Table" then return b end
    if b.content then
      local r = find_table(b.content)
      if r then return r end
    end
  end
  return nil
end

-- Handle a table float with tbl-notes set on its attributes. Unlike
-- figures, the notes are appended as a final row inside the table's
-- foot (TableFoot), so they sit flush against the bottom rule -- in
-- the spirit of `tinytable`'s `notes` option (LaTeX `\multicolumn`
-- inside the tabular, HTML `<tfoot>`, Typst grid footer).
local function handle_table(float)
  local notes_raw = float.attributes["tbl-notes"]
  if notes_raw == nil or notes_raw == "" then return nil end

  local title = float.attributes["tbl-notes-title"] or default_tbl_title
  local scale = tonumber(float.attributes["tbl-notes-scale"] or "") or default_tbl_scale

  float.attributes["tbl-notes"] = nil
  float.attributes["tbl-notes-title"] = nil
  float.attributes["tbl-notes-scale"] = nil

  local content_blocks = quarto.utils.as_blocks(float.content)
  local tbl = find_table(content_blocks)
  if tbl == nil then return nil end

  local notes_inlines = parse_inlines(notes_raw)
  local ncols = #tbl.colspecs
  if ncols < 1 then ncols = 1 end

  local format
  if quarto.doc.is_format("latex") or quarto.doc.is_format("pdf") then
    format = "latex"
  elseif quarto.doc.is_format("typst") then
    format = "typst"
  elseif quarto.doc.is_format("html") then
    format = "html"
  else
    return nil
  end

  local cell_inlines = build_tbl_foot_inlines(title, notes_inlines, scale, format)

  -- HTML: style the cell directly so the note row is left-aligned,
  -- smaller, and has no top border (sits flush against the bottom of
  -- the body rows).
  local cell_attr = pandoc.Attr()
  if format == "html" then
    cell_attr = pandoc.Attr("", { "quarto-table-notes" }, {
      { "style", string.format(
        "text-align:left;font-size:%sem;border-top:none;",
        tostring(scale)) },
    })
  end

  local cell = pandoc.Cell(
    { pandoc.Plain(cell_inlines) },
    pandoc.AlignLeft, 1, ncols, cell_attr)
  local row = pandoc.Row({ cell })
  tbl.foot.rows:insert(row)

  -- Without explicit column widths, a long single-line note in the
  -- footer cell can stretch only the bottom rule (LaTeX) or push the
  -- whole table wider while leaving data columns natural-width (Typst),
  -- producing a layout where the data block and the notes row visibly
  -- disagree, and where LaTeX and Typst outputs diverge depending on
  -- the note length. Normalising `colspecs` to equal fractions makes
  -- every writer (LaTeX `p{}` columns, Typst `columns: (1fr, 1fr, ...)`,
  -- HTML percentage widths) lay out the table at the full available
  -- text width, so data columns stretch, the note wraps within that
  -- width, and the three formats look the same regardless of the
  -- length of the note.
  local new_colspecs = {}
  for i = 1, ncols do
    local existing = tbl.colspecs[i]
    local align = (existing and existing[1]) or pandoc.AlignDefault
    new_colspecs[i] = { align, 1.0 / ncols }
  end
  tbl.colspecs = new_colspecs

  float.content = content_blocks
  return float
end

-- For executable code cells (e.g. R/Python chunks producing a figure),
-- Quarto wraps the generated image in a `.cell` Div and attaches the
-- chunk options to that Div. Capture any `fig-notes*` attributes here
-- (before Quarto's crossref pass moves the identifier off the image
-- and discards unknown image attributes), keyed by the inner image's
-- `src` so `FloatRefTarget` can recover them.
local function stash_cell_div_notes(div)
  local notes = div.attributes["fig-notes"]
  if notes == nil or notes == "" then return nil end

  local img = find_image(div.content)
  if img == nil or img.src == nil or img.src == "" then
    return nil
  end

  pending_fig_notes[img.src] = {
    notes = notes,
    title = div.attributes["fig-notes-title"],
    scale = div.attributes["fig-notes-scale"],
  }

  div.attributes["fig-notes"] = nil
  div.attributes["fig-notes-title"] = nil
  div.attributes["fig-notes-scale"] = nil
  return div
end

-- Run the cell-Div stashing pass first, then the float-handling pass,
-- so that `pending_fig_notes` is populated before `FloatRefTarget` is
-- invoked for the corresponding figure.
return {
  { Div = stash_cell_div_notes },
  {
    FloatRefTarget = function(float)
      if float.type == "Table" then
        return handle_table(float)
      end
      return handle_figure(float)
    end,
    Meta = Meta,
  },
}
