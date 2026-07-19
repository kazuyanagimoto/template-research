// econ-manuscript: classic economics working-paper look for Typst.
// `content-to-string` is provided by Quarto's definitions.typ (included before this).

// ORCID iD icon (inline SVG), shown as a link next to author names.
#let orcid-svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 256 256'><path fill='#A6CE39' d='M256 128c0 70.7-57.3 128-128 128S0 198.7 0 128 57.3 0 128 0s128 57.3 128 128z'/><path fill='#FFF' d='M86.3 186.2H70.9V79.1h15.4v107.1zm22.6-107.1h41.6c39.6 0 57 28.3 57 53.6 0 27.5-21.5 53.6-56.8 53.6h-41.8V79.1zm15.4 93.3h24.5c34.9 0 42.9-26.5 42.9-39.7 0-21.5-13.7-39.7-43.7-39.7h-23.7v79.4zM88.7 56.8c0 5.5-4.5 10.1-10.1 10.1s-10.1-4.6-10.1-10.1c0-5.6 4.5-10.1 10.1-10.1s10.1 4.6 10.1 10.1z'/></svg>"
#let orcid-mark(id) = link(
  "https://orcid.org/" + id,
  box(baseline: 0.13em, height: 0.85em, image(bytes(orcid-svg), format: "svg")),
)

#let article(
  title: none,
  subtitle: none,
  authors: none,
  keywords: (),
  custom-keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: ("New Computer Modern",),
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.1em,
  heading-family: none,
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  mathfont: none,
  codefont: none,
  linestretch: 1.5,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  // --- Document metadata (PDF accessibility) ---
  set document(title: title, keywords: keywords)
  set document(
    author: authors.map(author => content-to-string(author.name)).join(", ", last: " & "),
  ) if authors != none and authors != ()

  // --- Body text ---
  set text(lang: lang, region: region, size: fontsize)
  set text(font: font) if font != none
  // Match LaTeX baseline spacing: in LaTeX a line is `linestretch * 1.2 * size`
  // apart (article 11pt uses ~1.236). Typst's leading is the *gap* between
  // lines, so we subtract the font's ascender+descender (~0.68em for New
  // Computer Modern) to land on the same baseline-to-baseline distance.
  let line-gap = (1.236 * linestretch - 0.68) * 1em
  set par(
    justify: true,
    leading: line-gap,
    spacing: line-gap,
    first-line-indent: (amount: 1.5em, all: false),
  )
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: codefont) if codefont != none

  // Footnote separator: match LaTeX's \footnoterule (0.4 of the text width,
  // 0.4pt thick) instead of Typst's default short 30% rule.
  set footnote.entry(separator: line(length: 40%, stroke: 0.4pt))

  // Theorem-like environments (rendered as theorion figures) should start flush
  // left, like LaTeX's amsthm, rather than inheriting the body's paragraph indent.
  show figure.where(kind: "theorem"): set par(first-line-indent: 0pt)
  show figure.where(kind: "lemma"): set par(first-line-indent: 0pt)
  show figure.where(kind: "corollary"): set par(first-line-indent: 0pt)
  show figure.where(kind: "proposition"): set par(first-line-indent: 0pt)
  show figure.where(kind: "conjecture"): set par(first-line-indent: 0pt)
  show figure.where(kind: "definition"): set par(first-line-indent: 0pt)
  show figure.where(kind: "example"): set par(first-line-indent: 0pt)
  show figure.where(kind: "remark"): set par(first-line-indent: 0pt)

  // --- Headings: numbered, bold serif, generous space above ---
  set heading(numbering: sectionnumbering)
  show heading: set text(font: heading-family) if heading-family != none
  // Size relative to the *body* font (absolute), not `em`: Typst's default
  // heading sizing would otherwise compound and make headings far too large.
  // 1.09 * 11pt = 12pt, matching LaTeX's \large section headings.
  show heading.where(level: 1): set text(size: 1.09 * fontsize)
  show heading.where(level: 2): set text(size: 1.0 * fontsize)
  show heading.where(level: 3): set text(size: 1.0 * fontsize, style: "italic")
  show heading: it => {
    set text(weight: heading-weight)
    set text(style: heading-style) if heading-style != "normal"
    set text(fill: heading-color) if heading-color != black
    // Reconstruct the heading so we can put a little more space between the
    // section number and the title than Typst's default word space.
    let header = if it.numbering != none {
      numbering(it.numbering, ..counter(heading).at(it.location()))
      h(0.5em)
      it.body
    } else {
      it.body
    }
    block(above: 1.9em, below: 1.35em, header)
  }

  // --- Links / cross-references colouring (match LaTeX: blue links) ---
  let link-color = if citecolor != none {
    rgb(content-to-string(citecolor))
  } else if linkcolor != none {
    rgb(content-to-string(linkcolor))
  } else {
    rgb(0, 0, 255)
  }

  // Citations (link-citations wraps them in #link to a <ref-...> label) and
  // URLs: colour the whole link, like LaTeX's citecolor/urlcolor.
  show link: it => {
    set text(fill: link-color)
    it
  }

  // Cross-references: colour only the number, not the "Section"/"Table"/... word,
  // matching LaTeX where \ref is the coloured link but the prefix word is plain.
  show ref: it => {
    let el = it.element
    if el == none { return it }
    let loc = el.location()
    // After {{< appendix >}} the appendix state is true; floats and equations are
    // then numbered <section-letter>.<n> (computed at the element's location).
    let in-appendix = state("ecn-appendix", false).at(loc)
    let num = if el.func() == heading {
      numbering(el.numbering, ..counter(heading).at(loc))
    } else if el.func() == math.equation {
      let n = counter(math.equation).at(loc).first()
      if in-appendix { numbering("A.1", counter(heading).at(loc).first(), n) } else { numbering("1", n) }
    } else if el.func() == figure {
      let n = counter(figure.where(kind: el.kind)).at(loc).first()
      if in-appendix and el.kind in ("quarto-float-fig", "quarto-float-tbl") {
        numbering("A.1", counter(heading).at(loc).first(), n)
      } else {
        numbering("1", n)
      }
    } else {
      return it
    }
    [#it.supplement~#link(loc, text(fill: link-color, num))]
  }

  // --- Reference list: body line spacing within each entry, a hanging indent,
  //     and a blank-line gap between entries (matching LaTeX). ---
  show selector(<refs>): it => {
    set par(leading: line-gap, spacing: line-gap, first-line-indent: 0pt, hanging-indent: 1.5em)
    set block(spacing: 1.2em)
    it
  }

  // --- Title block (top of page 1, normal flow) ---
  let has-title-block = title != none or (authors != none and authors != ()) or abstract != none
  if has-title-block {
    // Title block is single-spaced (like LaTeX's title/author lines), independent
    // of the body's linestretch.
    set par(first-line-indent: 0pt, justify: false, leading: 0.5em, spacing: 0.5em)
    block(width: 100%, above: 0pt, below: 2em)[
      #if title != none {
        align(center)[
          #text(size: title-size, weight: "bold")[#title#if thanks != none {
            footnote(thanks, numbering: "*")
            counter(footnote).update(n => n - 1)
          }]
          #if subtitle != none {
            linebreak()
            v(0.45em)
            text(size: subtitle-size)[#subtitle]
          }
        ]
        v(0.8em)
      }

      #if authors != none and authors != () {
        let ncols = calc.min(authors.len(), 3)
        // Auto-width columns, centred as a group (like LaTeX's centred authors)
        // rather than spread to the page margins.
        align(center, grid(
          columns: (auto,) * ncols,
          column-gutter: 3em,
          row-gutter: 1em,
          ..authors.map(author => align(center)[
            #author.name#if author.at("orcid", default: "") not in (none, "") [#h(0.35em)#orcid-mark(author.orcid)] \
            #if author.affiliation not in (none, []) [ #emph(author.affiliation) \ ]
            #if author.email not in (none, []) [ #text(size: 0.9em, raw(content-to-string(author.email))) ]
          ])
        ))
        v(0.6em)
      }

      #if date != none {
        align(center, text(size: 0.95em, date))
        v(1em)
      }

      // --- Abstract: narrower, smaller, justified ---
      #if abstract != none {
        block(width: 100%, inset: (x: 2.5em))[
          // Abstract is single-spaced (matches LaTeX's \small abstract),
          // regardless of the body's linestretch.
          #set par(justify: true, first-line-indent: 0pt, leading: 0.56em, spacing: 0.56em)
          #align(center, text(weight: "bold", abstract-title))
          #v(0.4em)
          #text(size: 0.91em, abstract)
          #if keywords != () or custom-keywords != () {
            v(0.6em)
            set text(size: 0.9em)
            set par(leading: 0.5em, first-line-indent: 0pt)
            // Keywords first, then any custom keyword groups (JEL codes, etc.),
            // each on its own line with a bold label.
            let groups = ()
            if keywords != () { groups.push((name: [Keywords], values: keywords)) }
            groups += custom-keywords
            for (i, g) in groups.enumerate() {
              if i > 0 { linebreak() }
              [*#g.name:* #g.values.join(", ")]
            }
          }
        ]
      }
    ]
  }

  // --- Table of contents ---
  if toc {
    block(above: 0em, below: 2em)[
      #outline(title: toc_title, depth: toc_depth, indent: toc_indent)
    ]
  }

  doc
}

// tinytable manages its own borders; keep a clean default elsewhere.
#set table(inset: 6pt, stroke: none)
