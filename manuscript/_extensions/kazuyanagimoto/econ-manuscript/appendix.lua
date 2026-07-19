-- {{< appendix >}} shortcode.
-- Prints an "Appendix" divider title, then switches to appendix numbering: top-
-- level sections become A, B, ...; figures, tables and equations become A.1,
-- A.2, ... (reset per appendix section). Works for both Typst and LaTeX/PDF.
--
-- The title text defaults to "Appendix" and can be overridden with the
-- `appendix-title` shortcode argument, e.g. {{< appendix appendix-title="付録" >}},
-- or the document-level `appendix-title` metadata field.

local function typst_block(title)
  return table.concat({
    '#pagebreak(weak: true)',
    '#state("ecn-appendix", false).update(true)',
    '#counter(heading).update(0)',
    '#set heading(numbering: "A.1")',
    '#set figure(numbering: num => numbering("A.1", counter(heading).get().first(), num))',
    '#let equation-numbering = num => numbering("(A.1)", counter(heading).get().first(), num)',
    '#show heading.where(level: 1): it => {',
    '  counter(figure.where(kind: "quarto-float-fig")).update(0)',
    '  counter(figure.where(kind: "quarto-float-tbl")).update(0)',
    '  counter(math.equation).update(0)',
    '  it',
    '}',
    '#v(1.2em)',
    '#align(center, text(size: 1.6em, weight: "bold")[' .. title .. '])',
    '#v(0.8em)',
  }, "\n")
end

local function latex_block(title)
  return table.concat({
    '\\clearpage',
    '\\appendix',
    '\\numberwithin{figure}{section}',
    '\\numberwithin{table}{section}',
    '\\numberwithin{equation}{section}',
    '\\makeatletter',
    '\\@ifundefined{c@theorem}{}{\\numberwithin{theorem}{section}}',
    '\\makeatother',
    '\\bigskip',
    '{\\centering\\LARGE\\bfseries ' .. title .. '\\par}',
    '\\nopagebreak\\medskip',
    '\\FloatBarrier',
  }, "\n")
end

return {
  ['appendix'] = function(args, kwargs, meta)
    local title = "Appendix"
    if kwargs["appendix-title"] ~= nil and #pandoc.utils.stringify(kwargs["appendix-title"]) > 0 then
      title = pandoc.utils.stringify(kwargs["appendix-title"])
    elseif meta and meta["appendix-title"] ~= nil then
      title = pandoc.utils.stringify(meta["appendix-title"])
    end

    if quarto.doc.is_format("typst") then
      return pandoc.RawBlock("typst", typst_block(title))
    elseif quarto.doc.is_format("pdf") then
      return pandoc.RawBlock("latex", latex_block(title))
    end
    return pandoc.Null()
  end
}
