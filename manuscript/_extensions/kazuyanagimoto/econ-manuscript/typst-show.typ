#show: doc => article(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    ( name: [$it.name.literal$],
      affiliation: [$for(it.affiliations)$$it.name$$sep$, $endfor$],
      email: [$it.email$],
      orcid: "$it.orcid$" ),
$endif$
$endfor$
    ),
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
$if(abstract)$
  abstract: [$abstract$],
  abstract-title: "$labels.abstract$",
$endif$
$if(keywords)$
  keywords: ($for(keywords)$"$keywords$",$endfor$),
$endif$
$if(custom-keywords)$
  custom-keywords: (
$for(custom-keywords)$
    ( name: [$it.name$], values: ($for(it.values)$[$it$],$endfor$) ),
$endfor$
  ),
$endif$
$if(mainfont)$
  font: ("$mainfont$",),
$elseif(brand.typography.base.family)$
  font: $brand.typography.base.family$,
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$elseif(brand.typography.base.size)$
  fontsize: $brand.typography.base.size$,
$endif$
$if(brand.typography.headings.family)$
  heading-family: $brand.typography.headings.family$,
$endif$
$if(brand.typography.headings.weight)$
  heading-weight: $brand.typography.headings.weight$,
$endif$
$if(brand.typography.headings.style)$
  heading-style: "$brand.typography.headings.style$",
$endif$
$if(brand.typography.headings.color)$
  heading-color: $brand.typography.headings.color$,
$endif$
$if(section-numbering)$
  sectionnumbering: "$section-numbering$",
$endif$
$if(mathfont)$
  mathfont: ($for(mathfont)$"$mathfont$",$endfor$),
$endif$
$if(codefont)$
  codefont: ($for(codefont)$"$codefont$",$endfor$),
$elseif(brand.typography.monospace.family)$
  codefont: $brand.typography.monospace.family$,
$endif$
$if(linestretch)$
  linestretch: $linestretch$,
$endif$
$if(thanks)$
  thanks: [$thanks$],
$endif$
$if(linkcolor)$
  linkcolor: [$linkcolor$],
$elseif(brand.color.link)$
  linkcolor: [$brand.color.link$],
$endif$
$if(citecolor)$
  citecolor: [$citecolor$],
$elseif(brand.color.link)$
  citecolor: [$brand.color.link$],
$endif$
$if(filecolor)$
  filecolor: [$filecolor$],
$endif$
$if(toc)$
  toc: $toc$,
$endif$
$if(toc-title)$
  toc_title: [$toc-title$],
$endif$
$if(toc-indent)$
  toc_indent: $toc-indent$,
$endif$
  toc_depth: $toc-depth$,
  doc,
)
