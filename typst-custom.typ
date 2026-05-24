// ════════════════════════════════════════════════════════════════
// ESD113 — Thème Typst personnalisé  (v3)
// Auditeur CNAM : Alban VIDELOUP
// ════════════════════════════════════════════════════════════════

// ┌──────────────────────────────────────────────────────────────┐
// │  PALETTE DE COULEURS                                         │
// └──────────────────────────────────────────────────────────────┘
#let ca    = rgb("#a12b4e")   // bordeaux accent principal
#let ca2   = rgb("#7a1f39")   // bordeaux foncé
#let ca3   = rgb("#fde8ef")   // rose pâle (fonds callout)
#let cs    = rgb("#1a2e44")   // bleu marine (titres numérotés)
#let cm    = rgb("#5a6a7e")   // gris bleuté (sous-titres, pied)
#let cbg   = rgb("#f6f8fa")   // fond blocs de code
#let cbd   = rgb("#dce1e7")   // bordure blocs de code
#let cr    = rgb("#e2e6ea")   // filets légers

// ┌──────────────────────────────────────────────────────────────┐
// │  PIED DE PAGE                                                │
// └──────────────────────────────────────────────────────────────┘
#set page(
  footer: context {
    set text(size: 7.8pt, fill: cm,
             font: ("Latin Modern Roman", "DejaVu Serif"))
    v(0.4em)
    line(length: 100%, stroke: 0.35pt + cr)
    v(0.25em)
    grid(
      columns: (1fr, auto, 1fr),
      gutter: 0pt,
      align(left)[
        #text(fill: ca, weight: "bold")[ESD113]
        #text(fill: cm)[ — Probabilités et statistique avec R]
      ],
      align(center)[
        #text(fill: cr)[◆]
      ],
      align(right)[
        #text(fill: cm)[page ]
        #text(fill: ca, weight: "bold")[#counter(page).display("1")]
      ]
    )
  }
)

// ┌──────────────────────────────────────────────────────────────┐
// │  TYPOGRAPHIE PRINCIPALE                                      │
// └──────────────────────────────────────────────────────────────┘
#set text(
  font: ("Latin Modern Roman", "DejaVu Serif"),
  size: 11pt,
  fill: rgb("#1a1a1a"),
  hyphenate: true,
)
#set par(
  justify: true,
  leading: 0.84em,
  first-line-indent: 0em,
)

// ┌──────────────────────────────────────────────────────────────┐
// │  TITRES NIVEAU 1                                             │
// └──────────────────────────────────────────────────────────────┘
#show heading.where(level: 1): it => {
  v(2em, weak: true)
  if it.numbering == none {
    // ── Sections non numérotées (Parties, Remerciements, etc.) ──
    block(
      width: 100%,
      fill: ca,
      radius: 5pt,
      inset: (x: 1.8em, y: 1.25em),
    )[
      #set align(center)
      #set par(justify: false)
      #set text(fill: white, size: 17pt, weight: "bold",
                font: ("Latin Modern Roman"))
      #it.body
    ]
  } else {
    // ── Sections numérotées normales ────────────────────────────
    block(
      width: 100%,
      stroke: (left: 5pt + ca),
      inset: (left: 0.9em, top: 0.2em, bottom: 0.2em, right: 0pt),
    )[
      #set text(fill: cs, size: 14pt, weight: "bold",
                font: ("Latin Modern Roman"))
      #it
    ]
    v(0.15em, weak: true)
    line(length: 100%, stroke: 0.5pt + cr)
  }
  v(0.75em, weak: true)
}

// ┌──────────────────────────────────────────────────────────────┐
// │  TITRES NIVEAU 2                                             │
// └──────────────────────────────────────────────────────────────┘
#show heading.where(level: 2): it => {
  v(1.4em, weak: true)
  if it.numbering == none {
    // Sous-sections non numérotées (dans Rapport, etc.)
    set text(fill: ca2, size: 12pt, weight: "bold")
    it
    v(0.1em, weak: true)
    line(length: 100%, stroke: 0.4pt + cr)
  } else {
    set text(fill: ca2, size: 12.5pt, weight: "bold",
             font: ("Latin Modern Roman"))
    it
    v(0.2em, weak: true)
    line(length: 38%, stroke: 1.2pt + ca)
  }
  v(0.5em, weak: true)
}

// ┌──────────────────────────────────────────────────────────────┐
// │  TITRES NIVEAU 3                                             │
// └──────────────────────────────────────────────────────────────┘
#show heading.where(level: 3): it => {
  v(1em, weak: true)
  {
    set text(fill: cm, size: 11.5pt, weight: "bold", style: "italic")
    it
  }
  v(0.3em, weak: true)
}

// ┌──────────────────────────────────────────────────────────────┐
// │  LÉGENDES DES FIGURES                                        │
// └──────────────────────────────────────────────────────────────┘
#show figure.caption: it => {
  set text(size: 9pt, style: "italic", fill: cm)
  set par(justify: false)
  v(0.4em)
  align(center)[#it]
}

// ┌──────────────────────────────────────────────────────────────┐
// │  LIENS HYPERTEXTE                                            │
// └──────────────────────────────────────────────────────────────┘
#show link: it => {
  set text(fill: ca)
  underline(offset: 2pt, stroke: 0.4pt + ca)[#it]
}

// ┌──────────────────────────────────────────────────────────────┐
// │  CITATIONS (blockquote >)                                    │
// └──────────────────────────────────────────────────────────────┘
#show quote.where(block: true): it => {
  block(
    width: 100%,
    fill: ca3,
    radius: (left: 0pt, right: 4pt),
    inset: (left: 1.4em, right: 1.2em, y: 0.75em),
    stroke: (left: 4pt + ca, rest: 0.5pt + rgb("#f0c4d0")),
  )[
    #set text(style: "italic", fill: ca2, size: 10.5pt)
    #set par(justify: false)
    #it.body
  ]
}
