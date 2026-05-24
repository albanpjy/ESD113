// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
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
             font: ("Linux Libertine", "Georgia", "serif"))
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
  font: ("Linux Libertine", "Libertinus Serif", "Georgia", "serif"),
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
                font: ("Linux Libertine", "serif"))
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
                font: ("Linux Libertine", "serif"))
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
             font: ("Linux Libertine", "serif"))
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
#import "@preview/fontawesome:0.5.0": *

#set page(
  paper: "a4",
  margin: (x: 2.5cm,y: 2.8cm,),
  numbering: "1",
)

#show: doc => article(
  title: [ESD113 --- Probabilités et statistique avec R],
  subtitle: [De l'introduction à R au clustering : Keno, Tidyverse et méthodes non supervisées],
  authors: (
    ( name: [Auditeur CNAM : Alban VIDELOUP],
      affiliation: [],
      email: [] ),
    ),
  date: [3 mai 2026],
  lang: "fr",
  fontsize: 11pt,
  sectionnumbering: "1.1.1",
  toc: true,
  toc_title: [Table des matières],
  toc_depth: 3,
  cols: 1,
  doc,
)

#horizontalrule

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
[
Remerciements
]
)
]
#block[
#callout(
body: 
[
]
, 
title: 
[
❤️ À celles et ceux sans qui rien de tout cela n'aurait été possible
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
À #strong[Rhizlane];, mon épouse.

Les soirées passées sur ces pages, les week-ends confisqués par les algorithmes et les compilations récalcitrantes --- tu les as vécus avec une patience et une générosité qui forcent l'admiration. Tu as tenu la maison, organisé les journées, rassuré les enfants qui demandaient où était papa, et tu l'as fait avec cette force tranquille qui te caractérise. Ce travail t'appartient autant qu'à moi. Merci d'avoir cru, sans jamais fléchir, que ces efforts en valaient la peine.

À #strong[mes deux enfants];,

Vous avez souvent dû vous passer de moi à des moments où un père devrait être présent --- les jeux du soir, les histoires du coucher, les repas en famille que l'écran a parfois remplacés. Vous avez accepté ces absences avec une maturité touchante, et chacun de vos sourires, chacune de vos questions sur "ce que fait papa sur l'ordinateur", m'a redonné l'énergie de continuer. Je vous dois du temps, de la présence, et je m'y engage. Ce document, c'est aussi votre victoire.

À #strong[Monsieur Karim KILANI];, responsable de l'unité d'enseignement ESD113,

Rares sont les enseignants qui parviennent à rendre la statistique non seulement accessible, mais véritablement désirable. Votre pédagogie rigoureuse, votre disponibilité et votre souci constant de contextualiser les méthodes ont transformé ce cours en une exploration intellectuelle passionnante. Merci de consacrer votre expertise à des auditeurs comme nous, qui jonglent entre vie professionnelle et ambition académique.

Au #strong[CNAM];,

Permettre à un auditeur qui approche la cinquantaine, au cœur d'une vie active intense, de se former aux méthodes quantitatives avancées, à la data science, à R et à Quarto --- c'est un acte de foi dans l'idée que l'éducation n'a pas d'âge et que l'apprentissage tout au long de la vie n'est pas un slogan mais une réalité concrète. Le CNAM incarne cette conviction avec une constance exemplaire depuis plus de deux siècles. Il est difficile d'exprimer combien ce dispositif représente, pour des professionnels comme moi, une chance inestimable de rester dans la course d'un monde qui accélère. Merci d'exister, merci de persévérer, merci d'accueillir ceux que les circuits classiques ne peuvent plus atteindre.

#block[
#set text(style: "italic"); #emph[Alban VIDELOUP] \
#emph[Paris, 03 May 2026]

]
#pagebreak()

#horizontalrule

= Introduction générale
<sec-intro-generale>
Ce document a été réalisé dans le cadre de l'unité d'enseignement #strong[ESD113 --- Probabilités et statistiques avec R];, dispensée au Conservatoire National des Arts et Métiers (CNAM) par Monsieur Karim KILANI.

Un recours significatif aux outils d'intelligence artificielle a permis de résoudre les problématiques complexes de mise en page et de structuration du contenu.

Ce document fusionne trois volets complémentaires du cours :

+ #strong[Volet 1 --- Introduction à R, Quarto et Tidyverse :] prise en main de l'environnement de travail, manipulation de données, visualisation.
+ #strong[Volet 2 --- Projet Keno :] application à un cas concret avec les données de tirage du Keno (FDJ), incluant modélisation probabiliste et simulation de Monte-Carlo.
+ #strong[Volet 3 --- Méthodes de clustering :] reproduction et adaptation du code R de l'article de référence #emph["A Survey of Popular R Packages for Cluster Analysis"] (Flynt & Dean, 2016), couvrant K-means, classification hiérarchique ascendante et modèles de mélanges gaussiens (Mclust).

Le fil conducteur est la #strong[rigueur reproductible] : chaque résultat est produit directement par le code R présenté, dans un document Quarto compilable.

#block[
#callout(
body: 
[
Ce document est la version #strong[Typst] du rapport. Typst offre une composition typographique de haute qualité, comparable à LaTeX, tout en assurant des temps de compilation nettement plus rapides. Les formules mathématiques sont rendues nativement par le moteur Typst ; les callouts Quarto, les tableaux et les graphiques R sont pleinement pris en charge. Pour chaque formule, le bloc grisé affiche le #strong[code LaTeX source] à titre pédagogique, et le rendu apparaît immédiatement en dessous.

]
, 
title: 
[
Note sur le format Typst
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
Toutes les analyses sont réalisées avec R @r2024 et Quarto @quarto2024.

#horizontalrule

#pagebreak()
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
[
Partie I --- Introduction à R, Quarto et Tidyverse
]
)
]

#horizontalrule

= Initiation à R, Quarto et Markdown
<sec-intro>
== Présentation générale
<présentation-générale>
Ce premier volet est une introduction pratique au langage #strong[R] et à l'environnement de publication #strong[Quarto];. L'objectif est triple :

+ #strong[Découvrir Quarto] : un système de publication scientifique qui mêle texte, code et résultats dans un seul document.
+ #strong[Maîtriser les bases de R et du Tidyverse] : manipulation de données, statistiques descriptives, visualisation.
+ #strong[Appliquer ces outils à un cas réel] : les données de tirage du #strong[Keno FDJ];, avec modélisation probabiliste et simulation de Monte-Carlo.

#block[
#callout(
body: 
[
Quarto, c'est comme un cahier de laboratoire numérique : on y écrit ses observations (le texte), on y insère ses protocoles (le code R), et les résultats apparaissent automatiquement à la compilation. Plus besoin de copier-coller les sorties manuellement.

]
, 
title: 
[
Analogie pédagogique
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]

#horizontalrule

== Mise en forme du texte en Markdown
<mise-en-forme-du-texte-en-markdown>
Quarto repose sur la syntaxe #strong[Markdown] pour la mise en forme du texte. On peut écrire du texte en #strong[gras] et en #emph[italique];, insérer des listes, des tableaux, et bien sûr des formules mathématiques grâce à LaTeX.

=== Formules mathématiques
<formules-mathématiques>
Pour chaque formule, le bloc grisé montre le #strong[code LaTeX source] tel qu'il apparaît dans le document `.qmd`, et le rendu est affiché juste en dessous. Cette double présentation est précieuse pour l'apprentissage : on voit à la fois ce qu'on écrit et ce que Typst produit.

#strong[L'intégrale de Gauss] --- résultat fondamental en probabilité et théorie des fonctions, qui établit que l'aire sous la courbe en cloche $e^(- x^2)$ vaut exactement $sqrt(pi)$ :

```latex
$$\int_{-\infty}^{+\infty} e^{-x^2}\, dx = \sqrt{\pi}$$
```

$ integral_(- oo)^(+ oo) e^(- x^2) thin d x = sqrt(pi) $

où $x in bb(R)$ est la variable d'intégration et $e^(- x^2)$ est la fonction gaussienne non normalisée. C'est cette identité qui fonde, après normalisation par $sqrt(2 pi) sigma$, la densité de la loi normale.

#strong[La Transformée de Fourier (décomposition)] --- extrait les fréquences d'un signal temporel pour révéler son contenu spectral :

```latex
$$\hat{f}(\xi) = \int_{-\infty}^{+\infty} f(t)\, e^{-i 2\pi \xi t}\, dt$$
```

$ hat(f) (xi) = integral_(- oo)^(+ oo) f (t) thin e^(- i 2 pi xi t) thin d t $

où $f (t)$ est le signal d'origine, $hat(f) (xi)$ sa transformée, et $e^(- i 2 pi xi t)$ le noyau exponentiel complexe qui projette le signal sur chaque fréquence. La constante $i$ désigne l'unité imaginaire ($i^2 = - 1$).

#strong[La Transformée de Fourier inverse (reconstruction)] --- opération réciproque qui reconstruit le signal temporel à partir de son spectre :

```latex
$$f(t) = \int_{-\infty}^{+\infty} \hat{f}(\xi)\, e^{i 2\pi \xi t}\, d\xi$$
```

$ f (t) = integral_(- oo)^(+ oo) hat(f) (xi) thin e^(i 2 pi xi t) thin d xi $

où les rôles de $t$ et $xi$ sont inversés par rapport à la transformée directe : on intègre sur la variable de fréquence $xi$, et le signe du noyau exponentiel passe de $- i$ à $+ i$ (ce qui assure la réversibilité de l'opération).

#horizontalrule

== Les chunks de code R
<les-chunks-de-code-r>
Un #strong[chunk] est un bloc de code exécutable intégré au document. Le chunk ci-dessous génère la séquence des entiers de 1 à 20 :

#block[
```r
seq(1, 20)   # Fonction générique : séquence de 1 à 20 par pas de 1
```

#block[
```
#>  [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
```

]
```r
1:20         # Opérateur : notation compacte équivalente
```

#block[
```
#>  [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
```

]
]
Les années de Coupe du Monde de football entre 1970 et 2026 :

#block[
```r
seq(1970, 2026, by = 4)
```

#block[
```
#>  [1] 1970 1974 1978 1982 1986 1990 1994 1998 2002 2006 2010 2014 2018 2022 2026
```

]
]
#block[
#callout(
body: 
[
La fonction `seq(de, à, by = pas)` est l'une des plus utiles de R. On peut aussi écrire `1:20` pour une séquence d'entiers consécutifs --- c'est la notation compacte équivalente à `seq(1, 20, by = 1)`.

]
, 
title: 
[
À retenir
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]

#horizontalrule

== Références bibliographiques dans Quarto
<références-bibliographiques-dans-quarto>
Quarto gère nativement les bibliographies grâce à #strong[BibTeX];. Il suffit d'indiquer le fichier `.bib` dans l'en-tête YAML et de citer les références avec la syntaxe `@cle_bib`.

Par exemple, on peut citer l'article fondateur du Tidyverse : #cite(<wickham2019>, form: "prose");.

#horizontalrule

= Le Tidyverse
<sec-tidyverse>
== Présentation
<présentation>
Le #strong[Tidyverse] est un écosystème de packages R conçu pour la #emph[data science];. Tous ces packages partagent une même philosophie, une même grammaire et des structures de données communes (les #emph[tibbles];).

#block[
#callout(
body: 
[
Le Tidyverse, c'est comme une boîte à outils bien organisée : chaque outil a un rôle précis, ils fonctionnent tous ensemble, et on apprend une fois la logique commune plutôt que de mémoriser des syntaxes disparates.

]
, 
title: 
[
Analogie pédagogique
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
Parmi les packages les plus utilisés :

- `dplyr` : manipulation des données (filtrer, sélectionner, grouper, résumer)
- `ggplot2` : visualisation graphique déclarative
- `tidyr` : restructuration des données (pivot, imbrication)
- `readr` : lecture de fichiers CSV et délimités
- `lubridate` : traitement des dates et heures
- `stringr` : manipulation des chaînes de caractères

== Manipulation d'un data frame en R de base
<manipulation-dun-data-frame-en-r-de-base>
#block[
```r
dfcars <- mtcars

dfcars$mpg          # Affiche les 32 valeurs de mpg (miles par gallon)
```

#block[
```
#>  [1] 21.0 21.0 22.8 21.4 18.7 18.1 14.3 24.4 22.8 19.2 17.8 16.4 17.3 15.2 10.4
#> [16] 10.4 14.7 32.4 30.4 33.9 21.5 15.5 15.2 13.3 19.2 27.3 26.0 30.4 15.8 19.7
#> [31] 15.0 21.4
```

]
```r
dfcars[, 1]         # Sélection de la 1ère colonne (toutes les lignes)
```

#block[
```
#>  [1] 21.0 21.0 22.8 21.4 18.7 18.1 14.3 24.4 22.8 19.2 17.8 16.4 17.3 15.2 10.4
#> [16] 10.4 14.7 32.4 30.4 33.9 21.5 15.5 15.2 13.3 19.2 27.3 26.0 30.4 15.8 19.7
#> [31] 15.0 21.4
```

]
```r
dfcars[1, ]         # Sélection de la 1ère ligne (toutes les colonnes)
```

#block[
```
#>           mpg cyl disp  hp drat   wt  qsec vs am gear carb
#> Mazda RX4  21   6  160 110  3.9 2.62 16.46  0  1    4    4
```

]
```r
dfcars[1, 1]        # Valeur unique : 1ère colonne, 1ère ligne
```

#block[
```
#> [1] 21
```

]
]
== Manipulations avec le Tidyverse et le pipe `|>`
<manipulations-avec-le-tidyverse-et-le-pipe>
Le #strong[pipe natif] `|>` (disponible depuis R 4.1) permet de chaîner les opérations de gauche à droite :

#block[
```r
dfcars |> dplyr::select(mpg)            # Sélection d'une colonne par son nom
```

#block[
```
#>                      mpg
#> Mazda RX4           21.0
#> Mazda RX4 Wag       21.0
#> Datsun 710          22.8
#> Hornet 4 Drive      21.4
#> Hornet Sportabout   18.7
#> Valiant             18.1
#> Duster 360          14.3
#> Merc 240D           24.4
#> Merc 230            22.8
#> Merc 280            19.2
#> Merc 280C           17.8
#> Merc 450SE          16.4
#> Merc 450SL          17.3
#> Merc 450SLC         15.2
#> Cadillac Fleetwood  10.4
#> Lincoln Continental 10.4
#> Chrysler Imperial   14.7
#> Fiat 128            32.4
#> Honda Civic         30.4
#> Toyota Corolla      33.9
#> Toyota Corona       21.5
#> Dodge Challenger    15.5
#> AMC Javelin         15.2
#> Camaro Z28          13.3
#> Pontiac Firebird    19.2
#> Fiat X1-9           27.3
#> Porsche 914-2       26.0
#> Lotus Europa        30.4
#> Ford Pantera L      15.8
#> Ferrari Dino        19.7
#> Maserati Bora       15.0
#> Volvo 142E          21.4
```

]
```r
select(dfcars, mpg)                     # Même résultat, sans le pipe
```

#block[
```
#>                      mpg
#> Mazda RX4           21.0
#> Mazda RX4 Wag       21.0
#> Datsun 710          22.8
#> Hornet 4 Drive      21.4
#> Hornet Sportabout   18.7
#> Valiant             18.1
#> Duster 360          14.3
#> Merc 240D           24.4
#> Merc 230            22.8
#> Merc 280            19.2
#> Merc 280C           17.8
#> Merc 450SE          16.4
#> Merc 450SL          17.3
#> Merc 450SLC         15.2
#> Cadillac Fleetwood  10.4
#> Lincoln Continental 10.4
#> Chrysler Imperial   14.7
#> Fiat 128            32.4
#> Honda Civic         30.4
#> Toyota Corolla      33.9
#> Toyota Corona       21.5
#> Dodge Challenger    15.5
#> AMC Javelin         15.2
#> Camaro Z28          13.3
#> Pontiac Firebird    19.2
#> Fiat X1-9           27.3
#> Porsche 914-2       26.0
#> Lotus Europa        30.4
#> Ford Pantera L      15.8
#> Ferrari Dino        19.7
#> Maserati Bora       15.0
#> Volvo 142E          21.4
```

]
```r
dfcars |> dplyr::select(7:11)           # Sélection des colonnes 7 à 11 (plage)
```

#block[
```
#>                      qsec vs am gear carb
#> Mazda RX4           16.46  0  1    4    4
#> Mazda RX4 Wag       17.02  0  1    4    4
#> Datsun 710          18.61  1  1    4    1
#> Hornet 4 Drive      19.44  1  0    3    1
#> Hornet Sportabout   17.02  0  0    3    2
#> Valiant             20.22  1  0    3    1
#> Duster 360          15.84  0  0    3    4
#> Merc 240D           20.00  1  0    4    2
#> Merc 230            22.90  1  0    4    2
#> Merc 280            18.30  1  0    4    4
#> Merc 280C           18.90  1  0    4    4
#> Merc 450SE          17.40  0  0    3    3
#> Merc 450SL          17.60  0  0    3    3
#> Merc 450SLC         18.00  0  0    3    3
#> Cadillac Fleetwood  17.98  0  0    3    4
#> Lincoln Continental 17.82  0  0    3    4
#> Chrysler Imperial   17.42  0  0    3    4
#> Fiat 128            19.47  1  1    4    1
#> Honda Civic         18.52  1  1    4    2
#> Toyota Corolla      19.90  1  1    4    1
#> Toyota Corona       20.01  1  0    3    1
#> Dodge Challenger    16.87  0  0    3    2
#> AMC Javelin         17.30  0  0    3    2
#> Camaro Z28          15.41  0  0    3    4
#> Pontiac Firebird    17.05  0  0    3    2
#> Fiat X1-9           18.90  1  1    4    1
#> Porsche 914-2       16.70  0  1    5    2
#> Lotus Europa        16.90  1  1    5    2
#> Ford Pantera L      14.50  0  1    5    4
#> Ferrari Dino        15.50  0  1    5    6
#> Maserati Bora       14.60  0  1    5    8
#> Volvo 142E          18.60  1  1    4    2
```

]
]
== Statistiques descriptives avec le Tidyverse
<statistiques-descriptives-avec-le-tidyverse>
```r
stat_des <- dfcars |>
  select(mpg) |>
  summarise(
    Moyenne      = mean(mpg),
    `Écart-type` = sd(mpg),
    Minimum      = min(mpg),
    Maximum      = max(mpg)
  )

stat_des |>
  tt(digits = 2,
     caption = "Statistiques descriptives de la variable mpg (mtcars)")
```

#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
  )

  #let style-array = ( 
    // tinytable cell style after
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 4, stroke: 0.05em + black),
 table.hline(y: 2, start: 0, end: 4, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 4, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Moyenne], [Écart-type], [Minimum], [Maximum],
    ),
    // tinytable header end

    // tinytable cell content after
[20], [6], [10], [34],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block

#horizontalrule

= Introduction à la visualisation avec R
<sec-visu>
== Histogramme de base (R natif)
<histogramme-de-base-r-natif>
```r
dfcars$mpg |> hist(main = "Histogramme de MPG pour les 32 voitures",
                   xlab = "Miles par gallon", col = "steelblue", border = "white")
```

#box(image("esd113_complet_typst_v3_files/figure-typst/hist-base-1.svg"))

On peut ensuite filtrer les voitures très économiques (30 à 35 mpg) :

#block[
```r
dfcars |> filter(mpg >= 30 & mpg <= 35)
```

#block[
```
#>                 mpg cyl disp  hp drat    wt  qsec vs am gear carb
#> Fiat 128       32.4   4 78.7  66 4.08 2.200 19.47  1  1    4    1
#> Honda Civic    30.4   4 75.7  52 4.93 1.615 18.52  1  1    4    2
#> Toyota Corolla 33.9   4 71.1  65 4.22 1.835 19.90  1  1    4    1
#> Lotus Europa   30.4   4 95.1 113 3.77 1.513 16.90  1  1    5    2
```

]
]
== Histogramme avec ggplot2
<histogramme-avec-ggplot2>
`ggplot2` offre une grammaire graphique déclarative : on décrit #emph[ce que l'on veut voir];, et non #emph[comment le dessiner];.

```r
dfcars |>
  ggplot(aes(x = mpg)) +
  geom_histogram(fill = "#a12b4e", binwidth = 5, color = "white") +
  labs(
    title    = "Distribution de la consommation des 32 véhicules",
    subtitle = "Données : jeu intégré mtcars",
    x        = "Miles par gallon (mpg)",
    y        = "Nombre de véhicules"
  )
```

#box(image("esd113_complet_typst_v3_files/figure-typst/ggplot-hist-1.svg"))

#block[
#callout(
body: 
[
Le thème ggplot2 est configuré globalement dans le chunk `setup` via `theme_set()`. Il n'est pas nécessaire d'ajouter `+ theme_minimal()` à chaque graphique --- le thème s'applique automatiquement à tous les plots du document.

]
, 
title: 
[
Point d'attention
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]

#horizontalrule

#pagebreak()
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
[
Partie II --- Projet Keno : analyse des données FDJ
]
)
]

#horizontalrule

= Projet Keno --- Analyse des données FDJ
<sec-keno>
== Présentation du Keno
<présentation-du-keno>
Le #strong[Keno] est un jeu de tirage proposé par la Française des Jeux (FDJ). Dans la version étudiée ici, #strong[16 boules] sont tirées parmi #strong[56] numérotées de 1 à 56. Le joueur coche jusqu'à 10 numéros, et ses gains dépendent du nombre de numéros cochés figurant parmi les boules tirées.

== Chargement des données
<chargement-des-données>
#block[
```r
keno_202511 <- read_delim(
  "keno_202511.csv",
  delim          = ";",
  escape_double  = FALSE,
  col_types      = cols(
    date_de_forclusion = col_skip(),
    ...23              = col_skip()
  ),
  trim_ws        = TRUE
)

keno_202511 <- keno_202511 |> select(-c(1, 19, 20, 21))

names(keno_202511)
```

#block[
```
#>  [1] "date_de_tirage" "boule1"         "boule2"         "boule3"        
#>  [5] "boule4"         "boule5"         "boule6"         "boule7"        
#>  [9] "boule8"         "boule9"         "boule10"        "boule11"       
#> [13] "boule12"        "boule13"        "boule14"        "boule15"       
#> [17] "boule16"
```

]
]
== Pivot longer : restructuration des données
<pivot-longer-restructuration-des-données>
=== Le concept de pivot
<le-concept-de-pivot>
Les données Keno arrivent au format #strong[large] (wide) : chaque tirage est une ligne, avec 16 colonnes `boule1`, `boule2`, …, `boule16`. Pour les analyses statistiques, il est plus commode d'avoir un format #strong[long] : une ligne par boule tirée.

#block[
```r
table4a <- tibble(
  country = c("A", "B", "C"),
  `1999`  = c(700,   37000,  212000),
  `2000`  = c(2000,  80000,  213000)
)
table4a
```

#block[
```
#> # A tibble: 3 × 3
#>   country `1999` `2000`
#>   <chr>    <dbl>  <dbl>
#> 1 A          700   2000
#> 2 B        37000  80000
#> 3 C       212000 213000
```

]
```r
table4a |>
  pivot_longer(
    cols      = 2:3,
    names_to  = "annee",
    values_to = "cas"
  )
```

#block[
```
#> # A tibble: 6 × 3
#>   country annee    cas
#>   <chr>   <chr>  <dbl>
#> 1 A       1999     700
#> 2 A       2000    2000
#> 3 B       1999   37000
#> 4 B       2000   80000
#> 5 C       1999  212000
#> 6 C       2000  213000
```

]
]
=== Application au Keno
<application-au-keno>
#block[
```r
keno_longer <- keno_202511 |>
  pivot_longer(
    cols            = 2:17,
    names_to        = "Boule",
    names_prefix    = "boule",
    values_to       = "Num_boule"
  ) |>
  mutate(
    Boule     = as.integer(Boule),
    Num_boule = as.integer(Num_boule)
  )

glimpse(keno_longer)
```

#block[
```
#> Rows: 1,600
#> Columns: 3
#> $ date_de_tirage <chr> "10/02/2026", "10/02/2026", "10/02/2026", "10/02/2026",…
#> $ Boule          <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, …
#> $ Num_boule      <int> 12, 13, 17, 20, 22, 23, 26, 27, 39, 42, 45, 48, 50, 52,…
```

]
]
== Tableau de fréquence des boules
<tableau-de-fréquence-des-boules>
#block[
```r
freq_boules <- keno_longer |>
  dplyr::count(Num_boule, name = "frequence")

freq_boules |> filter(frequence == min(frequence))
```

#block[
```
#> # A tibble: 1 × 2
#>   Num_boule frequence
#>       <int>     <int>
#> 1         5        17
```

]
]
== Formatage des dates
<formatage-des-dates>
#block[
```r
keno_202511 <- keno_202511 |>
  mutate(date_de_tirage = as.Date(date_de_tirage, format = "%d/%m/%Y"))

keno_202511 |>
  summarise(
    date_min = format(min(date_de_tirage), "%d/%m/%Y"),
    date_max = format(max(date_de_tirage), "%d/%m/%Y")
  )
```

#block[
```
#> # A tibble: 1 × 2
#>   date_min   date_max  
#>   <chr>      <chr>     
#> 1 03/11/2025 10/02/2026
```

]
]
== Palmarès des numéros --- style FDJ
<sec-palmares>
Ce tableau s'inspire du #strong[palmarès des numéros] du site FDJ. Pour chaque numéro de 1 à 56, on affiche le nombre de sorties, le pourcentage de présence et la date de dernière sortie. La boîte ci-dessous précise la formule de calcul utilisée et fournit la référence théorique pour interpréter correctement les valeurs affichées.

#block[
#callout(
body: 
[
#strong[Calcul du pourcentage de présence.] Pour chaque numéro $i in { 1 \, dots.h \, 56 }$, on note $S_i$ le nombre de tirages dans lesquels il est sorti. Avec $N$ tirages historiques disponibles, le pourcentage de présence du numéro $i$ est défini par :

$ upright(P c t)_i = S_i / N times 100 $

où $S_i$ est le nombre de sorties du numéro $i$ et $N$ le nombre total de tirages. Cette formule est strictement #strong[identique au calcul officiel publié par la FDJ] sur sa page de statistiques Keno.

#strong[Référence théorique.] À chaque tirage, 16 boules sont tirées parmi 56. La probabilité qu'un numéro donné figure dans un tirage est donc :

$ p_(upright("théo")) = 16 / 56 approx 0 \, 2857 = upright(bold(28 \, 57 thin %)) $

#strong[Lecture du tableau.] Un numéro affichant un pourcentage proche de #strong[28,57 %] est conforme à la loi théorique. Un écart vers le haut indique un numéro #emph[sur-représenté] sur la période, vers le bas un numéro #emph[sous-représenté];. Ces écarts relèvent de la fluctuation d'échantillonnage --- ils n'ont aucune valeur prédictive pour les tirages futurs.

]
, 
title: 
[
Rappel théorique
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
```r
df_keno <- read_delim("keno_202511.csv", delim = ";", show_col_types = FALSE)

## ── Correction robuste du décompte des tirages ──────────────────────────────
total_tirages <- df_keno |>
  mutate(date_dt = dmy(date_de_tirage)) |>
  filter(!is.na(date_dt)) |>
  distinct(date_dt) |>
  nrow()

message("Nombre de tirages distincts retenus : ", total_tirages)

freq_boules_fdj <- df_keno |>
  pivot_longer(
    cols     = matches("^boule[0-9]+$"),
    names_to = "position",
    values_to = "Num_boule"
  ) |>
  mutate(
    date_dt   = dmy(date_de_tirage),
    Num_boule = as.integer(Num_boule)
  ) |>
  filter(!is.na(date_dt), !is.na(Num_boule)) |>
  group_by(Num_boule) |>
  summarise(
    Sorties  = n(),
    Pct      = (n() / total_tirages) * 100,
    Derniere = max(date_dt, na.rm = TRUE)
  ) |>
  arrange(Num_boule)

freq_boules_fdj |>
  mutate(
    Pct      = paste0(sprintf("%.2f", Pct), " %"),
    Derniere = format(Derniere, "%d/%m/%y")
  ) |>
  select(
    `Numéros`           = Num_boule,
    `Nombre de sorties` = Sorties,
    `% de sorties`     = Pct,
    `Dernière sortie`   = Derniere
  ) |>
  tt(caption = paste0(
      "Palmarès des numéros Keno FDJ. ",
      "* Pourcentage calculé sur N = ", total_tirages,
      " tirages valides distincts. Formule : sorties / N x 100."
  )) |>
  style_tt(align = "lccc")
```

#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "0_1": 0, "1_1": 0, "2_1": 0, "3_1": 0, "4_1": 0, "5_1": 0, "6_1": 0, "7_1": 0, "8_1": 0, "9_1": 0, "10_1": 0, "11_1": 0, "12_1": 0, "13_1": 0, "14_1": 0, "15_1": 0, "16_1": 0, "17_1": 0, "18_1": 0, "19_1": 0, "20_1": 0, "21_1": 0, "22_1": 0, "23_1": 0, "24_1": 0, "25_1": 0, "26_1": 0, "27_1": 0, "28_1": 0, "29_1": 0, "30_1": 0, "31_1": 0, "32_1": 0, "33_1": 0, "34_1": 0, "35_1": 0, "36_1": 0, "37_1": 0, "38_1": 0, "39_1": 0, "40_1": 0, "41_1": 0, "42_1": 0, "43_1": 0, "44_1": 0, "45_1": 0, "46_1": 0, "47_1": 0, "48_1": 0, "49_1": 0, "50_1": 0, "51_1": 0, "52_1": 0, "53_1": 0, "54_1": 0, "55_1": 0, "56_1": 0, "0_2": 0, "1_2": 0, "2_2": 0, "3_2": 0, "4_2": 0, "5_2": 0, "6_2": 0, "7_2": 0, "8_2": 0, "9_2": 0, "10_2": 0, "11_2": 0, "12_2": 0, "13_2": 0, "14_2": 0, "15_2": 0, "16_2": 0, "17_2": 0, "18_2": 0, "19_2": 0, "20_2": 0, "21_2": 0, "22_2": 0, "23_2": 0, "24_2": 0, "25_2": 0, "26_2": 0, "27_2": 0, "28_2": 0, "29_2": 0, "30_2": 0, "31_2": 0, "32_2": 0, "33_2": 0, "34_2": 0, "35_2": 0, "36_2": 0, "37_2": 0, "38_2": 0, "39_2": 0, "40_2": 0, "41_2": 0, "42_2": 0, "43_2": 0, "44_2": 0, "45_2": 0, "46_2": 0, "47_2": 0, "48_2": 0, "49_2": 0, "50_2": 0, "51_2": 0, "52_2": 0, "53_2": 0, "54_2": 0, "55_2": 0, "56_2": 0, "0_3": 0, "1_3": 0, "2_3": 0, "3_3": 0, "4_3": 0, "5_3": 0, "6_3": 0, "7_3": 0, "8_3": 0, "9_3": 0, "10_3": 0, "11_3": 0, "12_3": 0, "13_3": 0, "14_3": 0, "15_3": 0, "16_3": 0, "17_3": 0, "18_3": 0, "19_3": 0, "20_3": 0, "21_3": 0, "22_3": 0, "23_3": 0, "24_3": 0, "25_3": 0, "26_3": 0, "27_3": 0, "28_3": 0, "29_3": 0, "30_3": 0, "31_3": 0, "32_3": 0, "33_3": 0, "34_3": 0, "35_3": 0, "36_3": 0, "37_3": 0, "38_3": 0, "39_3": 0, "40_3": 0, "41_3": 0, "42_3": 0, "43_3": 0, "44_3": 0, "45_3": 0, "46_3": 0, "47_3": 0, "48_3": 0, "49_3": 0, "50_3": 0, "51_3": 0, "52_3": 0, "53_3": 0, "54_3": 0, "55_3": 0, "56_3": 0, "0_0": 1, "1_0": 1, "2_0": 1, "3_0": 1, "4_0": 1, "5_0": 1, "6_0": 1, "7_0": 1, "8_0": 1, "9_0": 1, "10_0": 1, "11_0": 1, "12_0": 1, "13_0": 1, "14_0": 1, "15_0": 1, "16_0": 1, "17_0": 1, "18_0": 1, "19_0": 1, "20_0": 1, "21_0": 1, "22_0": 1, "23_0": 1, "24_0": 1, "25_0": 1, "26_0": 1, "27_0": 1, "28_0": 1, "29_0": 1, "30_0": 1, "31_0": 1, "32_0": 1, "33_0": 1, "34_0": 1, "35_0": 1, "36_0": 1, "37_0": 1, "38_0": 1, "39_0": 1, "40_0": 1, "41_0": 1, "42_0": 1, "43_0": 1, "44_0": 1, "45_0": 1, "46_0": 1, "47_0": 1, "48_0": 1, "49_0": 1, "50_0": 1, "51_0": 1, "52_0": 1, "53_0": 1, "54_0": 1, "55_0": 1, "56_0": 1
  )

  #let style-array = ( 
    // tinytable cell style after
    (align: center,),
    (align: left,),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 4, stroke: 0.05em + black),
 table.hline(y: 57, start: 0, end: 4, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 4, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Numéros], [Nombre de sorties], [% de sorties], [Dernière sortie],
    ),
    // tinytable header end

    // tinytable cell content after
[1], [30], [30.00 %], [09/02/26],
[2], [26], [26.00 %], [08/02/26],
[3], [28], [28.00 %], [09/02/26],
[4], [32], [32.00 %], [09/02/26],
[5], [17], [17.00 %], [02/02/26],
[6], [21], [21.00 %], [05/02/26],
[7], [37], [37.00 %], [08/02/26],
[8], [23], [23.00 %], [04/02/26],
[9], [33], [33.00 %], [09/02/26],
[10], [30], [30.00 %], [02/02/26],
[11], [28], [28.00 %], [09/02/26],
[12], [28], [28.00 %], [10/02/26],
[13], [38], [38.00 %], [10/02/26],
[14], [35], [35.00 %], [09/02/26],
[15], [21], [21.00 %], [09/02/26],
[16], [23], [23.00 %], [06/02/26],
[17], [33], [33.00 %], [10/02/26],
[18], [19], [19.00 %], [04/02/26],
[19], [38], [38.00 %], [08/02/26],
[20], [24], [24.00 %], [10/02/26],
[21], [29], [29.00 %], [08/02/26],
[22], [20], [20.00 %], [10/02/26],
[23], [29], [29.00 %], [10/02/26],
[24], [29], [29.00 %], [02/02/26],
[25], [27], [27.00 %], [09/02/26],
[26], [28], [28.00 %], [10/02/26],
[27], [36], [36.00 %], [10/02/26],
[28], [33], [33.00 %], [05/02/26],
[29], [26], [26.00 %], [08/02/26],
[30], [35], [35.00 %], [06/02/26],
[31], [29], [29.00 %], [09/02/26],
[32], [24], [24.00 %], [30/01/26],
[33], [24], [24.00 %], [28/01/26],
[34], [25], [25.00 %], [02/02/26],
[35], [29], [29.00 %], [08/02/26],
[36], [24], [24.00 %], [09/02/26],
[37], [29], [29.00 %], [03/02/26],
[38], [31], [31.00 %], [05/02/26],
[39], [27], [27.00 %], [10/02/26],
[40], [27], [27.00 %], [08/02/26],
[41], [38], [38.00 %], [06/02/26],
[42], [30], [30.00 %], [10/02/26],
[43], [25], [25.00 %], [08/02/26],
[44], [30], [30.00 %], [08/02/26],
[45], [25], [25.00 %], [10/02/26],
[46], [32], [32.00 %], [09/02/26],
[47], [31], [31.00 %], [02/02/26],
[48], [30], [30.00 %], [10/02/26],
[49], [32], [32.00 %], [07/02/26],
[50], [30], [30.00 %], [10/02/26],
[51], [30], [30.00 %], [08/02/26],
[52], [29], [29.00 %], [10/02/26],
[53], [32], [32.00 %], [09/02/26],
[54], [24], [24.00 %], [04/02/26],
[55], [33], [33.00 %], [10/02/26],
[56], [24], [24.00 %], [10/02/26],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
== Statistiques sur le format long
<statistiques-sur-le-format-long>
```r
keno_long <- keno_202511 |>
  pivot_longer(
    cols            = boule1:boule16,
    names_to        = "boule",
    names_prefix    = "boule",
    names_transform = list(boule = as.integer),
    values_to       = "numero"
  )

table_freq <- keno_long |>
  dplyr::count(numero, name = "Nombre de sorties") |>
  complete(numero = 1:56, fill = list(`Nombre de sorties` = 0)) |>
  arrange(numero)

table_freq |>
  setNames(c("Numéro", "Nombre de sorties")) |>
  tt(caption = "Fréquence d'apparition des numéros (Keno — données FDJ)")
```

#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
  )

  #let style-array = ( 
    // tinytable cell style after
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 2, stroke: 0.05em + black),
 table.hline(y: 57, start: 0, end: 2, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 2, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Numéro], [Nombre de sorties],
    ),
    // tinytable header end

    // tinytable cell content after
[1], [30],
[2], [26],
[3], [28],
[4], [32],
[5], [17],
[6], [21],
[7], [37],
[8], [23],
[9], [33],
[10], [30],
[11], [28],
[12], [28],
[13], [38],
[14], [35],
[15], [21],
[16], [23],
[17], [33],
[18], [19],
[19], [38],
[20], [24],
[21], [29],
[22], [20],
[23], [29],
[24], [29],
[25], [27],
[26], [28],
[27], [36],
[28], [33],
[29], [26],
[30], [35],
[31], [29],
[32], [24],
[33], [24],
[34], [25],
[35], [29],
[36], [24],
[37], [29],
[38], [31],
[39], [27],
[40], [27],
[41], [38],
[42], [30],
[43], [25],
[44], [30],
[45], [25],
[46], [32],
[47], [31],
[48], [30],
[49], [32],
[50], [30],
[51], [30],
[52], [29],
[53], [32],
[54], [24],
[55], [33],
[56], [24],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block

#horizontalrule

= Visualisations graphiques du Keno
<sec-graphiques>
== Histogramme des fréquences
<histogramme-des-fréquences>
```r
freq_boules_plot <- keno_long |>
  dplyr::count(numero, name = "frequence") |>
  complete(numero = 1:56, fill = list(frequence = 0)) |>
  arrange(numero)

freq_boules_plot |>
  ggplot(aes(x = numero, y = frequence, fill = frequence)) +
  geom_bar(stat = "identity", color = "white", width = 0.8) +
  scale_fill_gradient(low = "green", high = "blue") +
  labs(
    title    = "Fréquence d'apparition de chaque numéro du Keno",
    subtitle = "Données FDJ — tirages du midi et du soir",
    x        = "Numéro de boule (1 à 56)",
    y        = "Nombre de sorties",
    fill     = "Fréquence"
  ) +
  theme(legend.position = "right")
```

#box(image("esd113_complet_typst_v3_files/figure-typst/barchart-freq-1.svg"))

== Graphique circulaire (diagramme en rose)
<graphique-circulaire-diagramme-en-rose>
Ce graphique polaire enroule les 56 numéros autour d'un axe circulaire, permettant de visualiser d'un coup d'œil l'uniformité des tirages :

```r
freq_boules_plot |>
  ggplot(aes(
    x    = reorder(as.factor(numero), as.numeric(numero)),
    y    = frequence,
    fill = frequence
  )) +
  geom_bar(stat = "identity", show.legend = FALSE, color = "white") +
  coord_polar(theta = "x", clip = "off") +
  geom_text(aes(y = 40, label = numero), color = "black", size = 3, fontface = "bold") +
  ylim(-2, max(freq_boules_plot$frequence) + 2) +
  scale_fill_gradient(low = "green", high = "blue") +
  labs(title    = "Répartition circulaire des fréquences",
       subtitle = "Chaque secteur représente un numéro (1 à 56)") +
  theme_void() +
  theme(plot.title    = element_text(face = "bold", hjust = 0.5, size = 11),
        plot.subtitle = element_text(hjust = 0.5, color = "grey40", size = 9),
        plot.margin   = margin(0, 0, 0, 0, "pt"),
        aspect.ratio  = 1)
```

#box(image("esd113_complet_typst_v3_files/figure-typst/polar-chart-1.svg"))

#horizontalrule

= Modélisation probabiliste du Keno
<sec-proba>
== La loi hypergéométrique
<la-loi-hypergéométrique>
#block[
#callout(
body: 
[
Le Keno est un tirage #strong[sans remise] : les boules ne sont pas replacées dans l'urne. La distribution de probabilité adaptée est la #strong[loi hypergéométrique];.

Code LaTeX de la formule :

```latex
$$P(X = x) = \frac{\binom{K}{x}\binom{N-K}{n-x}}{\binom{N}{n}}$$
```

$ P (X = x) = frac(binom(K, x) binom(N - K, n - x), binom(N, n)) $

avec : $N = 56$ (taille de l'urne), $K = 16$ (boules tirées par le Keno), $n = 10$ (numéros cochés par le joueur), $x$ (nombre de bons numéros).

]
, 
title: 
[
Rappel théorique
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
La fonction R correspondante est `dhyper(x, m, n, k)` où `m` est le nombre de boules « succès » dans l'urne, `n` le nombre de boules « échec », et `k` le nombre de tirages.

== Calcul des probabilités de gain
<calcul-des-probabilités-de-gain>
#block[
```r
tibble(
  x      = 0:10,
  `p(x)` = dhyper(0:10, m = 16, n = 40, k = 10),
  chance = round(1 / `p(x)`)
)
```

#block[
```
#> # A tibble: 11 × 3
#>        x      `p(x)`  chance
#>    <int>       <dbl>   <dbl>
#>  1     0 0.0238           42
#>  2     1 0.123             8
#>  3     2 0.259             4
#>  4     3 0.293             3
#>  5     4 0.196             5
#>  6     5 0.0807           12
#>  7     6 0.0206           49
#>  8     7 0.00317         315
#>  9     8 0.000282       3547
#> 10     9 0.0000129     77813
#> 11    10 0.000000225 4446435
```

]
]
== Tableau des gains officiels FDJ
<tableau-des-gains-officiels-fdj>
Le tableau ci-dessous croise les probabilités calculées avec les #strong[gains officiels] publiés par la FDJ (pour une mise de 1 €).

```r
tableau_gains <- tibble(
  x       = 0:10,
  `p(x)`  = dhyper(x, m = 16, n = 40, k = 10)
) |>
  arrange(desc(x)) |>
  filter(!x %in% 1:4) |>
  mutate(`g(x) en €` = c(200000, 2000, 150, 15, 5, 2, 2), .after = x)

tableau_gains |>
  setNames(c("Bonnes boules (x)", "Gain g(x) en €", "Probabilité p(x)")) |>
  tt(digits = 6,
     caption = "Gains officiels FDJ et probabilités associées (mise de 1 €, 10 numéros cochés)") |>
  style_tt(i = 1, bold = TRUE, color = "white", background = "#a12b4e")
```

#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "1_0": 0, "1_1": 0, "1_2": 0
  )

  #let style-array = ( 
    // tinytable cell style after
    (bold: true, color: white, background: rgb("#a12b4e"),),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 3, stroke: 0.05em + black),
 table.hline(y: 8, start: 0, end: 3, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 3, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Bonnes boules (x)], [Gain g(x) en €], [Probabilité p(x)],
    ),
    // tinytable header end

    // tinytable cell content after
[10], [200000], [0.000000224899],
[9], [2000], [0.000012851387],
[8], [150], [0.000281927303],
[7], [15], [0.003174292599],
[6], [5], [0.020553544581],
[5], [2], [0.080719375083],
[0], [2], [0.023805973614],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block

#horizontalrule

= Référence officielle FDJ : tableau complet des gains
<sec-ref-fdj>
== Les tableaux de gains officiels
<les-tableaux-de-gains-officiels>
Les probabilités et gains présentés dans cette section sont calculés à partir des règles officielles du Keno FDJ. Les sources officielles sont consultables en ligne :

- #strong[Probabilités et chances de gagner] : #link("https://www.fdj.fr/mag/questions/article-quelles-les-chances-de-gagner-keno-190326")[fdj.fr --- Quelles sont les chances de gagner au Kéno ?]
- #strong[Statistiques officielles des tirages] : #link("https://www.fdj.fr/jeux-de-tirage/keno/statistiques")[fdj.fr --- Kéno Statistiques]

#block[
#callout(
body: 
[
Les tableaux de gains de ce document sont calculés sur le modèle #strong[16 boules tirées parmi 56];, qui correspond exactement aux données historiques disponibles (`keno_202511.csv`). Ce modèle a été en vigueur jusqu'en 2020 ; la version actuelle du Keno FDJ tire 20 boules parmi 70. Les #strong[gains officiels] (montants en euros) sont identiques entre les deux versions, mais les #strong[probabilités] calculées par `dhyper()` diffèrent. Toutes les analyses de ce document restent cohérentes en se basant systématiquement sur le modèle 16/56.

]
, 
title: 
[
Note sur le modèle utilisé
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
#figure([
#box(image("nouveau-rapport-de-gains-keno-2020.webp", width: 80.0%))
], caption: figure.caption(
position: bottom, 
[
Tableau officiel FDJ --- toutes grilles de 2 à 10 numéros (version 2020)
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


== Construction de la table complète des gains FDJ
<sec-gains-complet>
Nous reproduisons ici le tableau officiel FDJ pour #strong[toutes les grilles] (de 2 à 10 numéros cochés), en calculant les probabilités théoriques avec `dhyper()` et en renseignant les gains officiels conformément au règlement FDJ --- modèle 16 boules tirées sur 56, cohérent avec les données keno\_202511.csv.

#block[
```r
## ── Paramètres du Keno FDJ — modèle des données historiques ─────────────────
N_keno <- 56   # taille de l'urne (version historique — données keno_202511.csv)
K_keno <- 16   # boules tirées par tirage (version historique)

## Table des gains officiels FDJ (mise 1 €) — source : article 8 du règlement
gains_fdj <- list(
  `10` = list(`10` = 200000, `9` = 2000, `8` = 150, `7` = 15,
              `6`  = 5,      `5` = 2,    `0` = 2),
  `9`  = list(`9`  = 30000,  `8` = 100,  `7` = 25,  `6` = 8,
              `5`  = 2,      `4` = 1,    `0` = 2),
  `8`  = list(`8`  = 8000,   `7` = 100,  `6` = 30,  `5` = 5,  `0` = 2),
  `7`  = list(`7`  = 3000,   `6` = 90,   `5` = 5,   `4` = 2),
  `6`  = list(`6`  = 900,    `5` = 30,   `4` = 3),
  `5`  = list(`5`  = 80,     `4` = 10,   `3` = 2),
  `4`  = list(`4`  = 70,     `3` = 3),
  `3`  = list(`3`  = 10,     `2` = 2),
  `2`  = list(`2`  = 6)
)

message("Table des gains FDJ chargée : ", length(gains_fdj), " grilles définies (2 à 10 numéros).")
```

]
#block[
```r
df_gains_long <- purrr::imap_dfr(gains_fdj, function(gains_grille, n_coches_chr) {
  n <- as.integer(n_coches_chr)
  purrr::imap_dfr(gains_grille, function(gain, n_trouves_chr) {
    x <- as.integer(n_trouves_chr)
    p <- dhyper(x, m = K_keno, n = N_keno - K_keno, k = n)
    tibble(
      n_coches   = n,
      n_trouves  = x,
      prob       = p,
      chance     = if (p > 0) round(1 / p) else NA_real_,
      gain_1eur  = gain,
      gain_10eur = gain * 10
    )
  })
}) |>
  arrange(desc(n_coches), desc(n_trouves))

message("Tableau long construit : ", nrow(df_gains_long), " lignes.")
```

]
```r
df_gains_long |>
  filter(n_coches == 10) |>
  select(
    `N° trouvés`      = n_trouves,
    `Probabilité`     = prob,
    `1 chance sur...` = chance,
    `Gain (1 €)`      = gain_1eur,
    `Gain (10 €)`     = gain_10eur
  ) |>
  tt(digits  = 7,
     caption = "Grille à 10 numéros cochés — probabilités et gains officiels FDJ (16 boules sur 56, mise 1 euro)") |>
  style_tt(i = 1, bold = TRUE, color = "white", background = "#a12b4e") |>
  style_tt(j = 4, bold = TRUE)
```

#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "0_3": 0, "2_3": 0, "3_3": 0, "4_3": 0, "5_3": 0, "6_3": 0, "7_3": 0, "1_0": 1, "1_1": 1, "1_2": 1, "1_3": 1, "1_4": 1
  )

  #let style-array = ( 
    // tinytable cell style after
    (bold: true,),
    (bold: true, color: white, background: rgb("#a12b4e"),),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 5, stroke: 0.05em + black),
 table.hline(y: 8, start: 0, end: 5, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 5, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[N° trouvés], [Probabilité], [1 chance sur...], [Gain (1 €)], [Gain (10 €)],
    ),
    // tinytable header end

    // tinytable cell content after
[10], [0.0000002248993], [4446435], [200000], [2000000],
[9], [0.000012851387], [77813], [2000], [20000],
[8], [0.0002819273032], [3547], [150], [1500],
[7], [0.0031742925994], [315], [15], [150],
[6], [0.0205535445812], [49], [5], [50],
[5], [0.0807193750826], [12], [2], [20],
[0], [0.0238059736139], [42], [2], [20],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
```r
tbl_complet <- df_gains_long |>
  mutate(
    prob_fmt   = formatC(prob,   format = "e", digits = 3),
    chance_fmt = formatC(chance, format = "fg", big.mark = " ",
                         flag = "#") |> stringr::str_trim(),
    gain_fmt   = paste0(formatC(gain_1eur, format = "fg", big.mark = " "), " €")
  ) |>
  select(
    `Grille`       = n_coches,
    `N° trouvés`   = n_trouves,
    `p(x)`         = prob_fmt,
    `1 chance sur` = chance_fmt,
    `Gain (1 €)`   = gain_fmt
  )

tbl_complet |>
  tt(caption = "Table complète des gains FDJ — toutes grilles de 2 à 10 numéros cochés (16 boules tirées sur 56, mise 1 euro)") |>
  style_tt(j = 1:2, align = "c") |>
  style_tt(j = 3:5, align = "r")
```

#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "0_0": 0, "1_0": 0, "2_0": 0, "3_0": 0, "4_0": 0, "5_0": 0, "6_0": 0, "7_0": 0, "8_0": 0, "9_0": 0, "10_0": 0, "11_0": 0, "12_0": 0, "13_0": 0, "14_0": 0, "15_0": 0, "16_0": 0, "17_0": 0, "18_0": 0, "19_0": 0, "20_0": 0, "21_0": 0, "22_0": 0, "23_0": 0, "24_0": 0, "25_0": 0, "26_0": 0, "27_0": 0, "28_0": 0, "29_0": 0, "30_0": 0, "31_0": 0, "32_0": 0, "33_0": 0, "34_0": 0, "0_1": 0, "1_1": 0, "2_1": 0, "3_1": 0, "4_1": 0, "5_1": 0, "6_1": 0, "7_1": 0, "8_1": 0, "9_1": 0, "10_1": 0, "11_1": 0, "12_1": 0, "13_1": 0, "14_1": 0, "15_1": 0, "16_1": 0, "17_1": 0, "18_1": 0, "19_1": 0, "20_1": 0, "21_1": 0, "22_1": 0, "23_1": 0, "24_1": 0, "25_1": 0, "26_1": 0, "27_1": 0, "28_1": 0, "29_1": 0, "30_1": 0, "31_1": 0, "32_1": 0, "33_1": 0, "34_1": 0, "0_2": 1, "1_2": 1, "2_2": 1, "3_2": 1, "4_2": 1, "5_2": 1, "6_2": 1, "7_2": 1, "8_2": 1, "9_2": 1, "10_2": 1, "11_2": 1, "12_2": 1, "13_2": 1, "14_2": 1, "15_2": 1, "16_2": 1, "17_2": 1, "18_2": 1, "19_2": 1, "20_2": 1, "21_2": 1, "22_2": 1, "23_2": 1, "24_2": 1, "25_2": 1, "26_2": 1, "27_2": 1, "28_2": 1, "29_2": 1, "30_2": 1, "31_2": 1, "32_2": 1, "33_2": 1, "34_2": 1, "0_3": 1, "1_3": 1, "2_3": 1, "3_3": 1, "4_3": 1, "5_3": 1, "6_3": 1, "7_3": 1, "8_3": 1, "9_3": 1, "10_3": 1, "11_3": 1, "12_3": 1, "13_3": 1, "14_3": 1, "15_3": 1, "16_3": 1, "17_3": 1, "18_3": 1, "19_3": 1, "20_3": 1, "21_3": 1, "22_3": 1, "23_3": 1, "24_3": 1, "25_3": 1, "26_3": 1, "27_3": 1, "28_3": 1, "29_3": 1, "30_3": 1, "31_3": 1, "32_3": 1, "33_3": 1, "34_3": 1, "0_4": 1, "1_4": 1, "2_4": 1, "3_4": 1, "4_4": 1, "5_4": 1, "6_4": 1, "7_4": 1, "8_4": 1, "9_4": 1, "10_4": 1, "11_4": 1, "12_4": 1, "13_4": 1, "14_4": 1, "15_4": 1, "16_4": 1, "17_4": 1, "18_4": 1, "19_4": 1, "20_4": 1, "21_4": 1, "22_4": 1, "23_4": 1, "24_4": 1, "25_4": 1, "26_4": 1, "27_4": 1, "28_4": 1, "29_4": 1, "30_4": 1, "31_4": 1, "32_4": 1, "33_4": 1, "34_4": 1
  )

  #let style-array = ( 
    // tinytable cell style after
    (align: center,),
    (align: right,),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 5, stroke: 0.05em + black),
 table.hline(y: 35, start: 0, end: 5, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 5, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Grille], [N° trouvés], [p(x)], [1 chance sur], [Gain (1 €)],
    ),
    // tinytable header end

    // tinytable cell content after
[10], [10], [2.249e-07], [4 446 435], [200 000 €],
[10], [9], [1.285e-05], [77 813], [2 000 €],
[10], [8], [2.819e-04], [3 547], [150 €],
[10], [7], [3.174e-03], [315.0], [15 €],
[10], [6], [2.055e-02], [49.00], [5 €],
[10], [5], [8.072e-02], [12.00], [2 €],
[10], [0], [2.381e-02], [42.00], [2 €],
[9], [9], [1.510e-06], [662 235], [30 000 €],
[9], [8], [6.795e-05], [14 716], [100 €],
[9], [7], [1.178e-03], [849.0], [25 €],
[9], [6], [1.044e-02], [96.00], [8 €],
[9], [5], [5.269e-02], [19.00], [2 €],
[9], [4], [1.581e-01], [6.000], [1 €],
[9], [0], [3.609e-02], [28.00], [2 €],
[8], [8], [9.060e-06], [110 373], [8 000 €],
[8], [7], [3.221e-04], [3 104], [100 €],
[8], [6], [4.397e-03], [227.0], [30 €],
[8], [5], [3.038e-02], [33.00], [5 €],
[8], [0], [5.414e-02], [18.00], [2 €],
[7], [7], [4.933e-05], [20 272], [3 000 €],
[7], [6], [1.381e-03], [724.0], [90 €],
[7], [5], [1.469e-02], [68.00], [5 €],
[7], [4], [7.753e-02], [13.00], [2 €],
[6], [6], [2.466e-04], [4 055], [900 €],
[6], [5], [5.381e-03], [186.0], [30 €],
[6], [4], [4.372e-02], [23.00], [3 €],
[5], [5], [1.144e-03], [874.0], [80 €],
[5], [4], [1.906e-02], [52.00], [10 €],
[5], [3], [1.144e-01], [9.000], [2 €],
[4], [4], [4.955e-03], [202.0], [70 €],
[4], [3], [6.099e-02], [16.00], [3 €],
[3], [3], [2.020e-02], [49.00], [10 €],
[3], [2], [1.732e-01], [6.000], [2 €],
[2], [2], [7.792e-02], [13.00], [6 €],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
== Espérances de gain par grille
<sec-esperances-grilles>
#block[
#callout(
body: 
[
Pour chaque grille (nombre de numéros cochés $n$), l'espérance de gain se calcule en sommant les gains pondérés par leurs probabilités, sur toutes les combinaisons gagnantes :

Code LaTeX de la formule :

```latex
$$E_n[G] = \sum_{x \in \mathcal{G}_n} g(x) \cdot p(x)$$
```

$ E_n [G] = sum_(x in cal(G)_n) g (x) dot.op p (x) $

où $cal(G)_n$ est l'ensemble des valeurs de $x$ donnant lieu à un gain pour la grille $n$.

]
, 
title: 
[
Rappel théorique
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
```r
df_esperances <- df_gains_long |>
  group_by(n_coches) |>
  summarise(
    esperance = sum(gain_1eur * prob, na.rm = TRUE),
    .groups   = "drop"
  ) |>
  mutate(
    trj_pct   = round(esperance * 100, 2),
    perte_moy = round(1 - esperance, 4)
  ) |>
  arrange(desc(n_coches))

df_esperances |>
  select(
    `N° cochés`                 = n_coches,
    `Espérance E[G]`            = esperance,
    `TRJ (%)`                   = trj_pct,
    `Perte moy. / tirage (EUR)` = perte_moy
  ) |>
  tt(digits  = 4,
     caption = "Espérance de gain et taux de retour joueur (TRJ) par grille — Keno FDJ (mise 1 euro)") |>
  style_tt(j = 3, bold = TRUE, background = "#fde8ef")
```

#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "0_2": 0, "1_2": 0, "2_2": 0, "3_2": 0, "4_2": 0, "5_2": 0, "6_2": 0, "7_2": 0, "8_2": 0, "9_2": 0
  )

  #let style-array = ( 
    // tinytable cell style after
    (bold: true, background: rgb("#fde8ef"),),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 4, stroke: 0.05em + black),
 table.hline(y: 10, start: 0, end: 4, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 4, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[N° cochés], [Espérance E[G]], [TRJ (%)], [Perte moy. / tirage (EUR)],
    ),
    // tinytable header end

    // tinytable cell content after
[10], [0.4724], [47.24], [0.5276],
[9], [0.5007], [50.07], [0.4993],
[8], [0.4968], [49.68], [0.5032],
[7], [0.5008], [50.08], [0.4992],
[6], [0.5146], [51.46], [0.4854],
[5], [0.5108], [51.08], [0.4892],
[4], [0.5298], [52.98], [0.4702],
[3], [0.5483], [54.83], [0.4517],
[2], [0.4675], [46.75], [0.5325],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
#block[
#callout(
body: 
[
Le #strong[taux de retour joueur (TRJ)] est la fraction de la mise que le joueur récupère #strong[en moyenne] sur un très grand nombre de parties. Un TRJ de 50 % signifie que pour 1 € joué, le joueur récupère en moyenne 0,50 € et perd donc 0,50 €. Ce taux est encadré réglementairement par l'ARJEL (Autorité de régulation des jeux en ligne).

]
, 
title: 
[
À retenir
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
```r
df_esperances |>
  ggplot(aes(x = factor(n_coches), y = esperance)) +
  geom_col(aes(fill = esperance), width = 0.65, show.legend = FALSE) +
  geom_hline(yintercept = 1, linetype = "dashed",
             color = "#a12b4e", linewidth = 0.7) +
  geom_text(aes(label = paste0(trj_pct, " %")),
            vjust = -0.5, size = 3.2, fontface = "bold", color = "gray20") +
  scale_fill_gradient(low = "#e8c4d0", high = "#a12b4e") +
  scale_y_continuous(
    labels = scales::label_number(suffix = " EUR", accuracy = 0.01),
    limits = c(0, 1.10),
    expand = expansion(mult = c(0, 0.02))
  ) +
  annotate("text", x = 0.6, y = 1.03, label = "Mise = 1 EUR",
           color = "#a12b4e", size = 3, hjust = 0, fontface = "italic") +
  labs(
    title    = "Espérance de gain selon le nombre de numéros cochés",
    subtitle = "Keno FDJ — mise de 1 euro — modèle 16/56",
    x        = "Nombre de numéros cochés",
    y        = "Espérance de gain (EUR)",
    caption  = "Source : gains officiels FDJ. La ligne pointillée rouge matérialise la mise de 1 EUR.\nEn dessous de cette ligne, le joueur perd en espérance."
  ) +
  theme_minimal() +
  theme(panel.grid.major.x = element_blank())
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/plot-esperances-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Espérance de gain selon le nombre de numéros cochés --- Keno FDJ (mise 1 euro, modèle 16/56). Toutes les barres restent sous la ligne pointillée rouge, confirmant que l'espérance est toujours négative pour le joueur.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
#callout(
body: 
[
Toutes les barres sont #strong[sous la ligne pointillée rouge] (la mise de 1 €), confirmant que l'#strong[espérance de gain est toujours négative pour le joueur];, quelle que soit la grille choisie. Le TRJ affiché au-dessus de chaque barre (en % de la mise) montre que la FDJ reverse entre 50 % et 60 % de la mise en gains --- la différence constituant la marge opératrice.

]
, 
title: 
[
Lecture du graphique
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]

#horizontalrule

= Espérance de gain
<sec-esperance>
== Définition et formule
<définition-et-formule>
#block[
#callout(
body: 
[
L'#strong[espérance mathématique] de gain est la valeur moyenne que le joueur peut espérer gagner par tirage. Elle se calcule comme la somme des gains pondérés par leurs probabilités :

Code LaTeX de la formule :

```latex
$$E[G] = \sum_{x=0}^{10} g(x) \cdot p(x)$$
```

$ E [G] = sum_(x = 0)^10 g (x) dot.op p (x) $

où $g (x)$ est le gain pour $x$ bonnes boules, et $p (x)$ la probabilité d'en obtenir exactement $x$.

]
, 
title: 
[
Rappel théorique
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Calcul avec R
<calcul-avec-r>
#block[
```r
result <- tibble(
  x      = 0:10,
  `p(x)` = dhyper(x, m = 16, n = 40, k = 10)
) |>
  arrange(desc(x)) |>
  filter(!x %in% 1:4) |>
  mutate(`g(x)` = c(200000, 2000, 150, 15, 5, 2, 2), .after = x)

esperance <- result |>
  summarise(esperance = sum(`g(x)` * `p(x)`))

esperance
```

#block[
```
#> # A tibble: 1 × 1
#>   esperance
#>       <dbl>
#> 1     0.472
```

]
]
#quote(block: true)[
#strong[Interprétation :] Pour une mise de 1 €, l'espérance de gain est d'environ #strong[0.472 €];. Cela signifie que le joueur perd en moyenne 0.528 € à chaque tirage --- ce qui traduit la marge de la FDJ.
]

#block[
#callout(
body: 
[
L'espérance de gain est inférieure à 1 euro (la mise). Cela signifie que le joueur perd en moyenne de l'argent à chaque tirage --- c'est la #strong[marge] intégrée par la FDJ dans le jeu. Ce résultat est fondamental en théorie des jeux et illustre pourquoi les jeux d'argent ne peuvent pas être des stratégies de gain à long terme.

]
, 
title: 
[
Point d'attention
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]

#horizontalrule

= Simulations de Monte-Carlo
<sec-montecarlo>
== Principe
<principe>
La #strong[simulation de Monte-Carlo] est une méthode numérique qui consiste à simuler un grand nombre de tirages aléatoires pour estimer des probabilités ou des distributions.

== Premier exemple : simulation simple
<premier-exemple-simulation-simple>
#block[
```r
set.seed(123)

numeros <- c()
for (t in 1:100) {
  numeros <- c(numeros, sample(1:56, 16, replace = FALSE))
}
table(numeros) |> min()
```

#block[
```
#> [1] 20
```

]
]
La même simulation, plus élégamment avec `replicate()` :

#block[
```r
set.seed(123)
numeros_simu <- as.vector(replicate(100, sample(1:56, 16, replace = FALSE)))
table(numeros_simu) |> min()
```

#block[
```
#> [1] 20
```

]
]
== Estimation d'une probabilité par Monte-Carlo
<estimation-dune-probabilité-par-monte-carlo>
On répète l'expérience #strong[N = 100 fois] pour estimer la probabilité qu'un numéro sorte 17 fois ou moins sur 100 tirages :

#block[
```r
set.seed(123)
N <- 100

valmin <- replicate(N, {
  tirages <- replicate(100, sample(1:56, 16, replace = FALSE))
  counts  <- table(factor(as.vector(tirages), levels = 1:56))
  min(counts)
})

cat("Probabilité estimée P(min ≤ 17) =", sum(valmin <= 17) / N)
```

#block[
```
#> Probabilité estimée P(min ≤ 17) = 0.26
```

]
]
== Simulation de Monte-Carlo à grande échelle (1 000 itérations)
<simulation-de-monte-carlo-à-grande-échelle-1-000-itérations>
```r
set.seed(123)
n_simulations     <- 1000
tirages_par_serie <- 100

simuler_min <- function() {
  resultats <- replicate(tirages_par_serie, sample(1:56, 16, replace = FALSE))
  counts    <- table(factor(resultats, levels = 1:56))
  return(min(counts))
}

simus    <- replicate(n_simulations, simuler_min())
df_simus <- data.frame(id = 1:n_simulations, val_min = simus)

ggplot(df_simus, aes(x = id, y = val_min)) +
  geom_point(alpha = 0.3, color = "#282D87", size = 0.9) +
  geom_smooth(method = "lm", color = "#a12b4e", se = TRUE) +
  labs(
    title    = "Simulation de Monte-Carlo : fréquence minimale d'apparition",
    subtitle = "1 000 séries de 100 tirages — Keno (16 boules parmi 56)",
    x        = "Numéro de simulation",
    y        = "Minimum d'apparition sur 100 tirages"
  ) +
  theme_minimal()
```

#box(image("esd113_complet_typst_v3_files/figure-typst/montecarlo-grande-echelle-1.svg"))

```r
seuil_critique <- mean(simus)
cat("En moyenne, sur 100 tirages, le numéro le moins sorti apparaît",
    round(seuil_critique, 1), "fois.")
```

#block[
```
#> En moyenne, sur 100 tirages, le numéro le moins sorti apparaît 18.6 fois.
```

]
#block[
#callout(
body: 
[
La droite de régression (quasiment horizontale) confirme que le processus est #strong[stationnaire] : le minimum d'apparition ne dérive pas au fil des simulations. C'est une propriété attendue d'un tirage véritablement aléatoire et uniforme.

]
, 
title: 
[
À retenir
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]

#horizontalrule

#pagebreak()
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
[
Partie III --- Méthodes de clustering
]
)
]

#horizontalrule

= Introduction au clustering
<sec-intro-clustering>
Ce volet a été réalisé dans le cadre de la même unité d'enseignement #strong[ESD113];. L'objectif principal est de reproduire et d'adapter le #link("https://www.stats.gla.ac.uk/~nd29c/Software/ClusterReviewCode.R")[code R] utilisé dans l'article de référence #strong["A Survey of Popular R Packages for Cluster Analysis"] @flynt2016.

== Qu'est-ce que le clustering ?
<quest-ce-que-le-clustering>
Imaginez que l'on vous donne un grand sac contenant mille pièces de puzzle mélangées, issues de plusieurs boites différentes. Votre mission : les trier #emph[sans voir les images] des boites d'origine. Naturellement, vous examinerez les couleurs, les formes de bordures, les textures --- vous regrouperez les pièces qui #emph[se ressemblent];. Sans le savoir, vous appliquerez l'algorithme mental à la base de tout clustering.

En statistique, le #strong[clustering] (ou #emph[classification non supervisée];) consiste à regrouper automatiquement des observations similaires #strong[sans connaitre à l'avance] les étiquettes ou catégories.

#block[
#callout(
body: 
[
Un algorithme de clustering appliqué à votre liste de courses pourrait découvrir, sans qu'on le lui dise, que vous achetez toujours ensemble des pâtes, de la sauce tomate et du parmesan --- et créer un "groupe culinaire" reflétant ce comportement. C'est de la connaissance extraite automatiquement de l'observation brute.

]
, 
title: 
[
Analogie pédagogique
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Bref panorama historique
<bref-panorama-historique>
=== La petite (et longue) histoire de l'algorithme de Lloyd
<la-petite-et-longue-histoire-de-lalgorithme-de-lloyd>
Si l'on devait décerner le prix de la "patience algorithmique", Stuart Lloyd serait sans doute sur le podium. Imaginez la scène : nous sommes en #strong[1957];, dans les prestigieux Laboratoires Bell. Entre deux tasses de café noir et des montagnes de tubes à vide, Lloyd pose les bases de ce qui deviendra le moteur de calcul le plus utilisé au monde pour le clustering : l'algorithme de quantification par moindres carrés.

Il faudra attendre #strong[1982] --- soit 25 ans après sa conception initiale ! --- pour que le travail de Lloyd #cite(<lloyd1982>, form: "year") soit enfin publié officiellement dans les #emph[IEEE Transactions on Information Theory];. C'est un peu comme si quelqu'un inventait la roue en secret, la rangeait dans son garage, et attendait que tout le monde roule en carrosse pour enfin publier le brevet !

Quelques jalons historiques essentiels :

- #strong[1894] --- Karl Pearson #cite(<pearson1894>, form: "year") utilise les premiers mélanges gaussiens pour analyser des populations de crabes dans la Baie de Naples. C'est l'acte de naissance des modèles de mélanges.
- #strong[Années 1950--1960] --- Les biologistes développent la #emph[taxinomie numérique];. Les premières méthodes hiérarchiques émergent @everitt2011.
- #strong[1963] --- Joe Ward #cite(<ward1963>, form: "year") formalise la méthode de liaison de Ward.
- #strong[1967] --- James MacQueen #cite(<macqueen1967>, form: "year") publie l'article fondateur du #strong[K-means];.
- #strong[1977] --- Dempster, Laird et Rubin #cite(<dempster1977>, form: "year") formalisent l'algorithme #strong[EM];.
- #strong[2002] --- Fraley et Raftery #cite(<fraley2002>, form: "year") publient la référence sur `Mclust`.

== Objectifs et plan du volet clustering
<objectifs-et-plan-du-volet-clustering>
Ce volet guide à travers #strong[trois grandes familles de méthodes];, du plus simple au plus sophistiqué :

+ Simulation de données structurées pour évaluer les algorithmes.
+ K-means, méthode du coude et ses #strong[six variations d'implémentation];.
+ Classification hiérarchique ascendante et dendrogramme.
+ Modèles de mélanges gaussiens avec `Mclust`.

#horizontalrule

= Préparation de l'environnement R pour le clustering
<sec-packages-clustering>
#block[
```r
library(mvtnorm)      # Simulation de lois normales multivariées
library(mclust)       # Modèles de mélanges gaussiens + ARI
library(ggforce)      # Ellipses et hulls ggplot2
library(viridis)      # Palettes daltonisme-friendly
library(ggdendro)     # Dendrogrammes ggplot2
library(broom)        # Extraction standardisée de métriques
library(factoextra)   # Visualisation clustering

conflicts_prefer(dplyr::select)
conflicts_prefer(dplyr::filter)
conflicts_prefer(dplyr::lag)
```

]

#horizontalrule

= Simulation des données : créer un laboratoire contrôlé
<sec-simulation>
== Pourquoi simuler ?
<pourquoi-simuler>
Évaluer une méthode de clustering sur des données réelles pose un problème fondamental : on ne connait pas les #emph[vrais] groupes, puisque c'est précisément ce qu'on cherche. La simulation résout ce problème en créant un monde artificiel où #strong[la vérité est connue à l'avance];.

#block[
#callout(
body: 
[
La simulation est le mannequin de crash-test de la statistique : on connait exactement les forces appliquées, et on mesure comment chaque algorithme s'en sort.

]
, 
title: 
[
À retenir
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
== Fondements mathématiques : la loi normale multivariée
<fondements-mathématiques-la-loi-normale-multivariée>
=== La loi normale univariée
<la-loi-normale-univariée>
La loi normale (loi de Gauss) est la distribution de probabilité la plus fondamentale en statistique @johnson2002. Sa densité est :

```latex
$$f(x) = \frac{1}{\sigma\sqrt{2\pi}} \exp\!\left(-\frac{(x-\mu)^2}{2\sigma^2}\right), \quad x \in \mathbb{R}$$
```

$ f (x) = frac(1, sigma sqrt(2 pi)) exp #h(-1em) (- frac((x - mu)^2, 2 sigma^2)) \, quad x in bb(R) $

où $mu in bb(R)$ est la moyenne (centre) et $sigma^2 > 0$ la variance (dispersion).

=== La loi normale multivariée
<la-loi-normale-multivariée>
Pour $p$ variables observées simultanément, on généralise avec la loi normale multivariée $cal(N)_p (bold(mu) \, bold(Sigma))$, de densité :

```latex
$$f(\boldsymbol{x}) = \frac{1}{(2\pi)^{p/2}|\boldsymbol{\Sigma}|^{1/2}} \exp\!\left(-\frac{1}{2}(\boldsymbol{x}-\boldsymbol{\mu})^\top\boldsymbol{\Sigma}^{-1}(\boldsymbol{x}-\boldsymbol{\mu})\right), \quad \boldsymbol{x} \in \mathbb{R}^p$$
```

$ f (bold(x)) = frac(1, (2 pi)^(p \/ 2) lr(|bold(Sigma)|)^(1 \/ 2)) exp #h(-1em) (- 1 / 2 (bold(x) - bold(mu))^tack.b bold(Sigma)^(- 1) (bold(x) - bold(mu))) \, quad bold(x) in bb(R)^p $

Les paramètres clés sont :

- $bold(mu) = (mu_1 \, dots.h \, mu_p)^tack.b$ : le vecteur de moyennes (centre du nuage de points).
- $bold(Sigma)$ : la matrice de covariance $p times p$, symétrique définie positive, qui décrit la forme et l'orientation du nuage.

=== Le modèle de mélange gaussien
<le-modèle-de-mélange-gaussien>
Notre jeu de données sera un mélange de $K = 3$ gaussiennes bivariées. La densité totale du mélange est :

```latex
$$f(\boldsymbol{x}) = \sum_{k=1}^{K} \pi_k \cdot \mathcal{N}_2(\boldsymbol{x}\,|\,\boldsymbol{\mu}_k, \boldsymbol{\Sigma}_k), \qquad \sum_{k=1}^{K} \pi_k = 1,\; \pi_k > 0$$
```

$ f (bold(x)) = sum_(k = 1)^K pi_k dot.op cal(N)_2 (bold(x) thin \| thin bold(mu)_k \, bold(Sigma)_k) \, #h(2em) sum_(k = 1)^K pi_k = 1 \, #h(0em) pi_k > 0 $

```r
data.frame(
  Groupe     = c("Groupe 1", "Groupe 2", "Groupe 3"),
  Proportion = c("0.30", "0.40", "0.30"),
  Moyenne    = c("(0, 0)", "(3, 5)", "(0, 6)"),
  Covariance = c("Sphérique I₂", "Sphérique I₂", "Elliptique Σ_ell"),
  Difficulte = c("Facile", "Facile", "Difficile (ellipse inclinée)")
) |>
  setNames(c("Groupe", "Proportion π_k", "Moyenne μ_k", "Covariance Σ_k", "Difficulté")) |>
  tt(caption = "Paramètres des trois composantes gaussiennes du mélange simulé.") |>
  style_tt(j = 5, italic = TRUE)
```

#figure([
#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "0_4": 0, "1_4": 0, "2_4": 0, "3_4": 0
  )

  #let style-array = ( 
    // tinytable cell style after
    (italic: true,),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 5, stroke: 0.05em + black),
 table.hline(y: 4, start: 0, end: 5, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 5, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Groupe], [Proportion π_k], [Moyenne μ_k], [Covariance Σ_k], [Difficulté],
    ),
    // tinytable header end

    // tinytable cell content after
[Groupe 1], [0.30], [(0, 0)], [Sphérique I₂], [Facile],
[Groupe 2], [0.40], [(3, 5)], [Sphérique I₂], [Facile],
[Groupe 3], [0.30], [(0, 6)], [Elliptique Σ_ell], [Difficile (ellipse inclinée)],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-params-simulation>


La matrice de covariance elliptique du Groupe 3 est :

```latex
$$\boldsymbol{\Sigma}_{ell} = \begin{pmatrix} 2 & 1.3 \\ 1.3 & 1 \end{pmatrix}$$
```

$ bold(Sigma)_(e l l) = mat(delim: "(", 2, 1.3; 1.3, 1) $

Elle traduit une variance plus forte selon $V_1$ et une corrélation positive entre $V_1$ et $V_2$ (covariance = $1.3 > 0$), ce qui crée l'ellipse inclinée à environ 45 degrés.

== Simulation des variables continues
<simulation-des-variables-continues>
=== Vers une lecture plus nette : l'enveloppe convexe
<vers-une-lecture-plus-nette-lenveloppe-convexe>
Pour obtenir une frontière "physique" nette autour de chaque groupe, nous utilisons le concept d'#strong[enveloppe convexe] (#emph[Convex Hull];). Mathématiquement, l'enveloppe convexe d'un ensemble de points est le plus petit polygone convexe contenant tous ces points.

#block[
#callout(
body: 
[
Imaginez que chaque point de notre graphique soit un clou planté sur une planche. L'enveloppe convexe correspond à la forme que prendrait un élastique tendu que l'on relâcherait autour de tous les clous d'une même couleur. L'élastique s'appuierait uniquement sur les points les plus extérieurs, créant une frontière parfaite et sans "creux".

]
, 
title: 
[
Analogie pédagogique
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== Reproduction des couleurs originales de Flynt & Dean (2016)
<reproduction-des-couleurs-originales-de-flynt-dean-2016>
```r
set.seed(288)

pi_vec <- c(0.3, 0.4, 0.3)
mu <- list(c(0, 0), c(3, 5), c(0, 6))

sigma_sph <- diag(2)
sigma_ell <- matrix(c(2, 1.3, 1.3, 1), nrow = 2, byrow = TRUE)

cl_real <- sample(1:3, size = 600, replace = TRUE, prob = pi_vec)

X_data <- purrr::map_dfr(cl_real, function(i) {
  sigma_i <- if (i == 3L) sigma_ell else sigma_sph
  rmvnorm(n = 1, mean = mu[[i]], sigma = sigma_i) |> as_tibble()
}) |>
  set_names(c("V1", "V2"))

X_plot <- X_data |>
  mutate(Groupe = as.factor(cl_real)) |>
  filter(!is.na(V1) & !is.na(V2))

couleurs_article <- c("1" = "black", "2" = "red", "3" = "green3")

ggplot(X_plot, aes(x = V1, y = V2, color = Groupe)) +
  geom_point(alpha = 0.5, size = 1.2, shape = 18) +
  ggforce::geom_mark_hull(
    aes(fill = Groupe), alpha = 0.10, color = NA,
    concavity = 10000, na.rm = TRUE, expand = unit(2, "mm")
  ) +
  scale_color_manual(values = couleurs_article, name = "Groupe réel",
                     labels = c("Groupe 1 (Black)", "Groupe 2 (Red)", "Groupe 3 (Green)")) +
  scale_fill_manual(values = couleurs_article) +
  labs(title    = "Données simulées : séparation par enveloppes convexes",
       subtitle = "Reproduction des couleurs originales de Flynt & Dean (2016)",
       x = "V1", y = "V2") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  guides(fill = "none")
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-simul-donnees-1.svg"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
#block[
]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-simul-donnees>


#block[
#callout(
body: 
[
Le Groupe 3 (en haut) forme une ellipse inclinée. Le K-means, qui suppose des clusters sphériques, aura du mal à le détecter correctement. Mclust, qui modélise explicitement les ellipses, le capturera bien.

]
, 
title: 
[
Point d'attention
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]

#horizontalrule

= Méthodes de partitionnement géométrique
<sec-partitionnement>
== K-means : la méthode des barycentres
<k-means-la-méthode-des-barycentres>
=== Principe et intuition
<principe-et-intuition>
Le K-means est l'algorithme de clustering le plus célèbre et le plus utilisé au monde @macqueen1967@lloyd1982. Son principe :

#quote(block: true)[
#emph[Chaque individu appartient au groupe dont le centre (la moyenne) lui est le plus proche.]
]

#block[
#callout(
body: 
[
Imaginez 3 personnes dans une salle bondée, chacune criant : "Venez vers moi !" Chaque individu rejoint la plus proche. Puis chaque personne se déplace au centre géographique de son groupe. On recommence jusqu'à stabilisation. C'est exactement l'algorithme K-means.

]
, 
title: 
[
Analogie pédagogique
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== Formalisation mathématique
<formalisation-mathématique>
K-means minimise la #strong[somme des distances au carré intra-cluster] (WSS, #emph[Within-Cluster Sum of Squares];) :

```latex
$$\mathrm{WSS} = \sum_{k=1}^{K} \sum_{\boldsymbol{x}_{i} \in C_{k}} \lVert \boldsymbol{x}_{i} - \boldsymbol{\mu}_{k} \rVert^{2}$$
```

$ upright(W S S) = sum_(k = 1)^K sum_(bold(x)_i in C_k) lr(bar.v.double bold(x)_i - bold(mu)_k bar.v.double)^2 $

=== Choisir K : la méthode du coude
<choisir-k-la-méthode-du-coude>
```r
elbow_data <- tibble(k = 1:9) |>
  mutate(
    model = purrr::map(k, ~ kmeans(X_data, centers = .x, nstart = 50)),
    wss   = purrr::map_dbl(model, ~ .x$tot.withinss)
  )

ggplot(elbow_data, aes(x = k, y = wss)) +
  geom_line(color = "gray70", linewidth = 0.9) +
  geom_point(aes(color = (k == 3)), size = 3.5) +
  scale_color_manual(values = c("black", "#B40000")) +
  scale_x_continuous(breaks = 1:9) +
  labs(title = "Inertie intra-classe selon le nombre de clusters K",
       x     = "Nombre de clusters K",
       y     = "WSS (Within-Cluster Sum of Squares)") +
  guides(color = "none")
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-elbow-1.svg"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
#block[
]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-elbow>


#block[
#callout(
body: 
[
#block[
#set enum(numbering: "(1)", start: 1)
+ il suppose des clusters sphériques, inadapté aux formes elliptiques ; (2) il est sensible aux valeurs aberrantes ; (3) il n'exprime aucune incertitude : chaque individu est assigné définitivement à un seul groupe ; (4) il ne fonctionne que sur des variables continues.
]

]
, 
title: 
[
Limites du K-means
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
=== Six variations pour générer la courbe WSS
<six-variations-pour-générer-la-courbe-wss>
#strong[Variation 1 --- Méthode manuelle]

```r
km1 <- kmeans(X_data, 1, nstart = 50); km2 <- kmeans(X_data, 2, nstart = 50)
km3 <- kmeans(X_data, 3, nstart = 50); km4 <- kmeans(X_data, 4, nstart = 50)
km5 <- kmeans(X_data, 5, nstart = 50); km6 <- kmeans(X_data, 6, nstart = 50)
km7 <- kmeans(X_data, 7, nstart = 50); km8 <- kmeans(X_data, 8, nstart = 50)
km9 <- kmeans(X_data, 9, nstart = 50)

wss_man <- c(km1$tot.withinss, km2$tot.withinss, km3$tot.withinss,
             km4$tot.withinss, km5$tot.withinss, km6$tot.withinss,
             km7$tot.withinss, km8$tot.withinss, km9$tot.withinss)

ggplot(tibble(k = 1:9, wss = wss_man), aes(k, wss)) +
  geom_line(color = "gray60") + geom_point(size = 3) +
  scale_x_continuous(breaks = 1:9) +
  labs(title = "Variation 1 : Méthode manuelle", x = "K", y = "WSS")
```

#box(image("esd113_complet_typst_v3_files/figure-typst/var1-manuelle-1.svg"))

#strong[Variation 2 --- Boucle for]

```r
wss_for <- numeric(9)
for (i in 1:9) {
  wss_for[i] <- kmeans(X_data, centers = i, nstart = 50)$tot.withinss
}

ggplot(tibble(k = 1:9, wss = wss_for), aes(k, wss)) +
  geom_line(color = "gray60") + geom_point(size = 3) +
  scale_x_continuous(breaks = 1:9) +
  labs(title = "Variation 2 : Boucle For", x = "K", y = "WSS")
```

#box(image("esd113_complet_typst_v3_files/figure-typst/var2-for-1.svg"))

#strong[Variation 3 --- sapply]

```r
wss_sapply <- sapply(1:9, function(k) {
  kmeans(X_data, centers = k, nstart = 50)$tot.withinss
})

ggplot(tibble(k = 1:9, wss = wss_sapply), aes(k, wss)) +
  geom_line(color = "steelblue") + geom_point() +
  scale_x_continuous(breaks = 1:9) +
  labs(title = "Variation 3 : sapply (Vectorisation)", x = "K", y = "WSS")
```

#box(image("esd113_complet_typst_v3_files/figure-typst/var3-sapply-1.svg"))

#strong[Variation 4 --- purrr]

```r
elbow_purrr <- tibble(k = 1:9) |>
  mutate(
    model = purrr::map(k, ~ kmeans(X_data, centers = .x, nstart = 50)),
    wss   = purrr::map_dbl(model, ~ .x$tot.withinss)
  )

ggplot(elbow_purrr, aes(k, wss)) +
  geom_line(linewidth = 0.9, color = "gray60") +
  geom_point(aes(color = (k == 3)), size = 4) +
  scale_color_manual(values = c("black", "#B40000"), guide = "none") +
  scale_x_continuous(breaks = 1:9) +
  labs(title = "Variation 4 : purrr (Programmation fonctionnelle)", x = "K", y = "WSS")
```

#box(image("esd113_complet_typst_v3_files/figure-typst/var4-purrr-1.svg"))

#strong[Variation 5 --- broom]

```r
elbow_broom <- tibble(k = 1:9) |>
  mutate(
    model = purrr::map(k, ~ kmeans(X_data, centers = .x, nstart = 50)),
    stats = purrr::map(model, broom::glance)
  ) |>
  tidyr::unnest(stats)

ggplot(elbow_broom, aes(k, tot.withinss)) +
  geom_line(color = "green4") + geom_point() +
  scale_x_continuous(breaks = 1:9) +
  labs(title = "Variation 5 : broom (métriques standardisées)", y = "WSS", x = "K")
```

#box(image("esd113_complet_typst_v3_files/figure-typst/var5-broom-1.svg"))

#strong[Variation 6 --- factoextra (clé en main)]

```r
fviz_nbclust(X_data, kmeans, method = "wss", k.max = 9, nstart = 50) +
  geom_vline(xintercept = 3, linetype = 2, color = "firebrick") +
  labs(title = "Variation 6 : factoextra (Clé en main)")
```

#box(image("esd113_complet_typst_v3_files/figure-typst/var6-factoextra-1.svg"))

#block[
#callout(
body: 
[
Les six courbes WSS produites sont #strong[statistiquement identiques] : toutes indiquent un coude en $k = 3$, confirmant exactement la structure simulée par Flynt & Dean. Le choix de la variation est donc un choix de #strong[style de code] et de contexte d'usage.

]
, 
title: 
[
À retenir
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
```r
data.frame(
  Methode   = c("Manuelle", "Boucle For", "sapply", "purrr", "broom", "factoextra"),
  Avantage  = c("Transparence totale", "Logique universelle", "Concis (Base R)",
                "Traçabilité complète", "Métriques multiples", "Rapidité, esthétique"),
  Inconvenient = c("Très verbeux", "Plus de lignes", "Modèle perdu",
                   "Syntaxe complexe", "Package sup.", "\"Boîte noire\""),
  Usage     = c("Apprentissage", "Débutants", "Scripts légers",
                "Pipelines DS", "Rapports stats", "Exploration")
) |>
  setNames(c("Méthode", "Avantage principal", "Inconvénient", "Usage idéal")) |>
  tt(caption = "Tableau de synthèse des six variations d'implémentation de la méthode du coude.")
```

#figure([
#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
  )

  #let style-array = ( 
    // tinytable cell style after
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 4, stroke: 0.05em + black),
 table.hline(y: 7, start: 0, end: 4, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 4, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Méthode], [Avantage principal], [Inconvénient], [Usage idéal],
    ),
    // tinytable header end

    // tinytable cell content after
[Manuelle], [Transparence totale], [Très verbeux], [Apprentissage],
[Boucle For], [Logique universelle], [Plus de lignes], [Débutants],
[sapply], [Concis (Base R)], [Modèle perdu], [Scripts légers],
[purrr], [Traçabilité complète], [Syntaxe complexe], [Pipelines DS],
[broom], [Métriques multiples], [Package sup.], [Rapports stats],
[factoextra], [Rapidité, esthétique], ["Boîte noire"], [Exploration],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-synthese-variations>


== Superposition K-means / vérité terrain
<superposition-k-means-vérité-terrain>
```r
set.seed(123)
km_res <- kmeans(X_data, centers = 3, nstart = 25)

X_eval <- X_data |>
  mutate(
    Vrai_Groupe = as.factor(cl_real),
    Cluster_KM  = as.factor(km_res$cluster)
  )

ggplot(X_eval, aes(x = V1, y = V2)) +
  geom_point(aes(color = Vrai_Groupe), alpha = 0.6, size = 1.2, shape = 18) +
  ggforce::geom_mark_hull(
    aes(fill = Cluster_KM, group = Cluster_KM),
    alpha = 0.10, color = "gray40", linetype = "solid",
    concavity = 10000, radius = unit(0, "mm"),
    expand = unit(0, "mm"), na.rm = TRUE
  ) +
  scale_color_manual(values = couleurs_article, name = "Vérité Terrain") +
  scale_fill_manual(values = couleurs_article) +
  labs(title    = "Évaluation K-means : Enveloppes Convexes Strictes",
       subtitle = "Polygones reliant les points extrêmes de chaque cluster",
       x = "V1", y = "V2") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  guides(fill = "none")
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-kmeans-eval-1.svg"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
#block[
]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-kmeans-eval>


=== Performance du K-means (K=3)
<performance-du-k-means-k3>
#block[
```r
km3     <- kmeans(X_data, 3, nstart = 50)
tab_km  <- table(cl_real, km3$cluster)
cat("Table de contingence K-means vs vérité terrain :\n")
```

#block[
```
#> Table de contingence K-means vs vérité terrain :
```

]
```r
print(tab_km)
```

#block[
```
#>        
#> cl_real   1   2   3
#>       1   0   0 177
#>       2 227  10   0
#>       3  33 153   0
```

]
```r
reussite_points <- sum(apply(tab_km, 1, max))
total_points    <- sum(tab_km)
taux_reussite   <- (reussite_points / total_points) * 100
taux_erreur     <- 100 - taux_reussite

cat("\nTaux de réussite :", round(taux_reussite, 2), "%")
```

#block[
```
#> 
#> Taux de réussite : 92.83 %
```

]
```r
cat("\nTaux d'erreur    :", round(taux_erreur, 2), "%")
```

#block[
```
#> 
#> Taux d'erreur    : 7.17 %
```

]
]
```r
data.frame(
  Indicateur = c("Points bien classés", "Taux de réussite", "Taux d'erreur"),
  Resultat   = c(paste0(reussite_points, " / ", total_points),
                 paste0(round(taux_reussite, 2), " %"),
                 paste0(round(taux_erreur, 2), " %"))
) |>
  setNames(c("Indicateur de performance", "Résultat")) |>
  tt(caption = "Analyse de la précision du K-means (K=3) sur les données Flynt & Dean.")
```

#figure([
#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
  )

  #let style-array = ( 
    // tinytable cell style after
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 2, stroke: 0.05em + black),
 table.hline(y: 4, start: 0, end: 2, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 2, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Indicateur de performance], [Résultat],
    ),
    // tinytable header end

    // tinytable cell content after
[Points bien classés], [557 / 600],
[Taux de réussite], [92.83 %],
[Taux d'erreur], [7.17 %],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-perf-kmeans>


#block[
#callout(
body: 
[
Si le Groupe 1 valide l'efficacité de l'approche dans des conditions simples, les Groupes 2 et 3 démontrent que la propreté visuelle d'un clustering ne garantit pas sa justesse statistique. Le K-means impose sa propre géométrie (sphérique) aux données au lieu de s'adapter à la leur (elliptique).

]
, 
title: 
[
En conclusion
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]

#horizontalrule

== Classification hiérarchique ascendante (CHA)
<classification-hiérarchique-ascendante-cha>
=== Principe
<principe-1>
La #strong[classification hiérarchique ascendante] (CHA) construit un #strong[dendrogramme] --- un arbre de fusion représentant quels individus ou groupes ont été réunis, et à quelle distance @everitt2011. Elle ne requiert pas de spécifier $K$ à l'avance.

La liaison moyenne (UPGMA) définit la distance entre deux groupes $A$ et $B$ comme la moyenne de toutes les distances inter-individuelles :

```latex
$$d(A, B) = \frac{1}{|A| \cdot |B|} \sum_{i \in A} \sum_{j \in B} d(x_i, x_j)$$
```

$ d (A \, B) = frac(1, lr(|A|) dot.op lr(|B|)) sum_(i in A) sum_(j in B) d (x_i \, x_j) $

```r
d_mat   <- dist(X_data, method = "euclidean")
h_avg   <- hclust(d_mat, method = "average")

ggdendrogram(h_avg, rotate = FALSE, size = 0.15) +
  labs(
    title    = "Dendrogramme de classification hiérarchique",
    subtitle = "Liaison moyenne (UPGMA) --- 600 individus"
  ) +
  theme(axis.text.x  = element_blank(),
        axis.ticks.x = element_blank())
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-dendro-simple-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Dendrogramme de classification hiérarchique (liaison moyenne, 600 individus). La hauteur d'une jonction représente la distance de fusion. Pour K = 3, on coupe au niveau de la 3e plus grande fusion.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-dendro-simple>


=== La méthode hiérarchique CAH sur les données simulées
<la-méthode-hiérarchique-cah-sur-les-données-simulées>
Dans l'article de Flynt & Dean (2016), la méthode du lien moyen peut s'avérer encore moins performante que le K-means sur ces structures, entraînant un taux d'erreur avoisinant les 30 %. La raison fondamentale : la CAH fusionne des sous-groupes de façon #strong[irréversible] (#emph[greedy];), sans pouvoir réassigner un point mal placé.

```r
res.hc <- hclust(dist(X_data), method = "average")

fviz_dend(res.hc,
          k          = 3,
          cex        = 0.15,
          lwd        = 0.30,
          rect       = TRUE,
          rect_fill  = TRUE,
          rect_lty   = 1,
          palette    = c("black", "red", "green3"),
          main       = "Dendrogramme (Average Linkage)",
          xlab       = "Observations",
          ylab       = "Distance Euclidienne",
          ggtheme    = theme_minimal()) +
  scale_linewidth(range = c(0.30, 0.30)) +
  theme(
    axis.text.x     = element_blank(),
    legend.position = "none"
  )
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-dendro-color-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Dendrogramme (lien moyen, 600 individus) avec découpage en 3 clusters selon les couleurs de l'article.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-dendro-color>


=== La version circulaire
<la-version-circulaire>
```r
library(patchwork)
library(grid)

# 1. Construction du plot
p_circ <- fviz_dend(res.hc,
                    k           = 3,
                    type        = "circular",
                    cex         = 0.15,
                    rect        = TRUE,
                    rect_fill   = TRUE,
                    palette     = c("black", "red", "green3"),
                    main        = "Dendrogramme Circulaire (Average Linkage)",
                    ggtheme     = theme_void())

# 2. Patch linewidth sur tous les segments
for (i in seq_along(p_circ$layers)) {
  geom_class <- class(p_circ$layers[[i]]$geom)
  if (any(geom_class %in% c("GeomSegment", "GeomCurve", "GeomPath"))) {
    p_circ$layers[[i]]$aes_params$linewidth <- 0.30
    p_circ$layers[[i]]$aes_params$size      <- 0.30
  }
}

p_circ <- p_circ +
  scale_linewidth(range = c(0.30, 0.30)) +
  theme_void() +
  theme(legend.position = "none")

# 3. Suppression des labels radiaux
gb <- ggplot_build(p_circ)
gb$layout$panel_params[[1]]$r.labels <- character(0)
gb$layout$panel_params[[1]]$r.major  <- numeric(0)
gb$layout$panel_params[[1]]$r.minor  <- numeric(0)
gt <- ggplot_gtable(gb)

# 4. Rendu compatible Quarto
wrap_elements(gt)
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-dendro-circular-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Dendrogramme circulaire (lien moyen, 600 individus) avec découpage en 3 clusters.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-dendro-circular>


=== Le calcul (30 % d'erreur)
<le-calcul-30-derreur>
Pour retrouver les chiffres de l'article, il faut regarder si les points de #strong[différentes couleurs] sont mélangés dans le même cluster :

#block[
```r
hRed  <- hclust(dist(X_data[1:2]), method = "average")
H2cut <- cutree(hRed, k = 3)
table(cl_real, H2cut)
```

#block[
```
#>        H2cut
#> cl_real   1   2   3
#>       1   0 177   0
#>       2 237   0   0
#>       3 182   0   4
```

]
]
Taux de réussite : $(237 + 177 + 4) \/ 600 = 69 \, 7 thin %$ --- Taux d'erreur : $182 \/ 600 = 30 \, 3 thin %$

#block[
#callout(
body: 
[
Alors que le K-means affiche environ 7--10 % d'erreur, la méthode hiérarchique dépasse ici les #strong[30 % d'erreur];. Les deux groupes sphériques, trop proches, sont fusionnés en un "super-cluster" artificiel par le lien moyen, tandis que le groupe vert (elliptique) se retrouve fragmenté.

]
, 
title: 
[
Constat de Flynt & Dean
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
#block[
#callout(
body: 
[
La méthode hiérarchique est utile pour explorer la structure des données, mais pour un partitionnement robuste sur ces données simulées, le K-means (et a fortiori Mclust) reste largement supérieur.

]
, 
title: 
[
À retenir
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]

#horizontalrule

= Méthodes basées sur les modèles probabilistes
<sec-mclust>
== Modèles de mélanges gaussiens : Mclust
<modèles-de-mélanges-gaussiens-mclust>
=== Du déterministe au probabiliste
<du-déterministe-au-probabiliste>
Avec K-means et la CHA, chaque individu est assigné à exactement un groupe, sans la moindre nuance. Les #strong[Modèles de Mélanges Gaussiens] (GMM) apportent une vision plus honnête : chaque individu appartient à chaque groupe avec une certaine probabilité. Formellement :

```latex
$$f(\boldsymbol{x}) = \sum_{k=1}^{K} \pi_k \cdot \mathcal{N}_p(\boldsymbol{x}\,|\,\boldsymbol{\mu}_k, \boldsymbol{\Sigma}_k)$$
```

$ f (bold(x)) = sum_(k = 1)^K pi_k dot.op cal(N)_p (bold(x) thin \| thin bold(mu)_k \, bold(Sigma)_k) $

#block[
#callout(
body: 
[
Le K-means dit : "Tu es un client premium, point." Le GMM dit : "Tu es probablement un client premium à 75 %, standard à 20 % et VIP à 5 %." C'est nettement plus nuancé et réaliste.

]
, 
title: 
[
Analogie pédagogique
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== L'algorithme EM
<lalgorithme-em>
Les paramètres ${ pi_k \, bold(mu)_k \, bold(Sigma)_k }_(k = 1)^K$ sont estimés par l'algorithme EM @dempster1977 :

#strong[Étape E (Expectation)] --- calcul des responsabilités $r_(i k)$ :

```latex
$$r_{ik} = \frac{\pi_k \cdot \mathcal{N}_p(x_i|\,\boldsymbol{\mu}_k, \boldsymbol{\Sigma}_k)}{\sum_{j=1}^{K} \pi_j \cdot \mathcal{N}_p(x_i|\,\boldsymbol{\mu}_j, \boldsymbol{\Sigma}_j)}$$
```

$ r_(i k) = frac(pi_k dot.op cal(N)_p (x_i \| thin bold(mu)_k \, bold(Sigma)_k), sum_(j = 1)^K pi_j dot.op cal(N)_p (x_i \| thin bold(mu)_j \, bold(Sigma)_j)) $

#strong[Étape M (Maximization)] --- mise à jour des paramètres :

```latex
$$\hat{\pi}_k = \frac{1}{n}\sum_i r_{ik}, \qquad \hat{\boldsymbol{\mu}}_k = \frac{\sum_i r_{ik} x_i}{\sum_i r_{ik}}, \qquad \hat{\boldsymbol{\Sigma}}_k = \frac{\sum_i r_{ik}(x_i - \hat{\boldsymbol{\mu}}_k)(x_i - \hat{\boldsymbol{\mu}}_k)^\top}{\sum_i r_{ik}}$$
```

$ hat(pi)_k = 1 / n sum_i r_(i k) \, #h(2em) hat(bold(mu))_k = frac(sum_i r_(i k) x_i, sum_i r_(i k)) \, #h(2em) hat(bold(Sigma))_k = frac(sum_i r_(i k) (x_i - hat(bold(mu))_k) (x_i - hat(bold(mu))_k)^tack.b, sum_i r_(i k)) $

=== Sélection automatique via le BIC
<sélection-automatique-via-le-bic>
Mclust @fraley2002@scrucca2016 sélectionne automatiquement $K$ et la structure de covariance en maximisant le #strong[Critère d'Information Bayésien (BIC)] @schwarz1978 :

```latex
$$\text{BIC} = 2\ln\hat{L} - d\ln n$$
```

$ upright("BIC") = 2 ln hat(L) - d ln n $

#block[
```r
mc_model_v2 <- Mclust(X_data[, 1:2], G = 3)
tab_mc_v2   <- table(Vérité = cl_real, Mclust = mc_model_v2$classification)
print(tab_mc_v2)
```

#block[
```
#>       Mclust
#> Vérité   1   2   3
#>      1   0 177   0
#>      2 229   0   8
#>      3   0   0 186
```

]
```r
reussite_mc      <- sum(apply(tab_mc_v2, 1, max))
taux_reussite_mc <- (reussite_mc / nrow(X_data)) * 100
taux_erreur_mc   <- 100 - taux_reussite_mc

cat("Taux de réussite Mclust :", round(taux_reussite_mc, 2), "%")
```

#block[
```
#> Taux de réussite Mclust : 98.67 %
```

]
```r
cat("\nTaux d'erreur Mclust    :", round(taux_erreur_mc, 2), "%")
```

#block[
```
#> 
#> Taux d'erreur Mclust    : 1.33 %
```

]
]
```r
data.frame(
  Indicateur = c("Points bien capturés", "Taux de réussite (Capture)", "Taux d'erreur"),
  Resultat   = c(paste0(reussite_mc, " / ", nrow(X_data)),
                 paste0(round(taux_reussite_mc, 2), " %"),
                 paste0(round(taux_erreur_mc, 2), " %"))
) |>
  setNames(c("Indicateur", "Résultat")) |>
  tt(caption = "Performance du modèle Mclust (G=3) sur les données Flynt & Dean.") |>
  style_tt(i = 2, bold = TRUE, color = "white", background = "#28a745")
```

#figure([
#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "2_0": 0, "2_1": 0
  )

  #let style-array = ( 
    // tinytable cell style after
    (bold: true, color: white, background: rgb("#28a745"),),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 2, stroke: 0.05em + black),
 table.hline(y: 4, start: 0, end: 2, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 2, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Indicateur], [Résultat],
    ),
    // tinytable header end

    // tinytable cell content after
[Points bien capturés], [592 / 600],
[Taux de réussite (Capture)], [98.67 %],
[Taux d'erreur], [1.33 %],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-perf-mclust>


```r
mc_res_v2 <- Mclust(X_data[, 1:2], G = 3)

X_mclust_v2 <- X_data |>
  mutate(
    Verite         = as.factor(cl_real),
    Cluster_Mclust = as.factor(mc_res_v2$classification)
  )

bleu_v2 <- rgb(0, 70, 127, maxColorValue = 255)

ggplot(X_mclust_v2, aes(x = V1, y = V2)) +
  geom_point(aes(color = Verite), alpha = 0.6, size = 1.2, shape = 18) +
  ggforce::geom_mark_hull(
    aes(fill = Cluster_Mclust, group = Cluster_Mclust,
        label = paste("Cluster", Cluster_Mclust)),
    alpha = 0.10, color = bleu_v2, linetype = "solid",
    concavity = 10000, radius = unit(0, "mm"), expand = unit(0, "mm"),
    label.buffer = unit(5, "mm"), label.fontsize = 9,
    label.fontface = "bold", na.rm = TRUE
  ) +
  scale_color_manual(values = couleurs_article, name = "Vérité Terrain") +
  scale_fill_manual(values = couleurs_article) +
  labs(title    = "Mclust : Identification des structures gaussiennes",
       subtitle = "Les étiquettes désignent les populations identifiées par l'algorithme",
       x = "Variable V1", y = "Variable V2") +
  theme_minimal() +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold")) +
  guides(fill = "none")
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-mclust-hull-v2-1.svg"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
#block[
]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-mclust-hull-v2>


```r
mc_full_fviz <- Mclust(X_data[, 1:2], G = 1:9)
fviz_mclust_bic(mc_full_fviz, palette = "jco", legend = "right",
                ggtheme = theme_minimal())
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-mclust-bic-fviz-v2-1.svg"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
#block[
]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-mclust-bic-fviz-v2>


```r
fviz_mclust(mc_res_v2, what = "classification",
            palette = c("black", "red", "green3"),
            ggtheme = theme_minimal(),
            main    = "Classification Mclust (G=3)")
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-mclust-classif-v2-1.svg"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
#block[
]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-mclust-classif-v2>


```r
ggplot(X_mclust_v2, aes(x = V1, y = V2, color = Cluster_Mclust)) +
  geom_point(alpha = 0.5, size = 1.5, shape = 16) +
  stat_ellipse(aes(fill = Cluster_Mclust), geom = "polygon", alpha = 0.1, level = 0.95) +
  scale_color_manual(values = c("black", "red", "green3")) +
  scale_fill_manual(values  = c("black", "red", "green3")) +
  labs(title    = "Structure des populations identifiées",
       subtitle = "Les ellipses de confiance illustrent la modélisation gaussienne")
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-mclust-ellipses-v2-1.svg"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
#block[
]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-mclust-ellipses-v2>


```r
X_mclust_v2$Uncertainty <- mc_res_v2$uncertainty

ggplot(X_mclust_v2, aes(x = V1, y = V2, color = Uncertainty)) +
  geom_point(size = 2) +
  scale_color_gradient(low = "gray80", high = "firebrick1") +
  labs(title    = "Zones de doute de l'algorithme Mclust",
       subtitle = "Les points rouges marquent les frontières de décision ambiguës",
       color    = "Incertitude")
```

#figure([
#box(image("esd113_complet_typst_v3_files/figure-typst/fig-mclust-uncertainty-v2-1.svg"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
#block[
]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-mclust-uncertainty-v2>


#strong[Calcul du taux de réussite Mclust :]

```latex
$$T_{réussite} = \frac{177 + 229 + 186}{600} = \frac{592}{600} \approx 0{,}9867 \quad \Rightarrow \quad 98{,}67\,\%$$
```

$ T_(r é u s s i t e) = frac(177 + 229 + 186, 600) = 592 / 600 approx 0 \, 9867 quad arrow.r.double quad 98 \, 67 thin % $

#block[
#callout(
body: 
[
En ne forçant pas une structure circulaire, `mclust` parvient à capturer l'intégralité de l'ellipse verte sans déborder sur les groupes voisins. C'est la conclusion majeure de Flynt & Dean : pour des données réelles complexes, #strong[le choix du modèle statistique prime sur la simplicité géométrique];.

]
, 
title: 
[
Le triomphe de Mclust
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]

#horizontalrule

= Comparaison et synthèse des méthodes
<sec-comparaison>
```r
set.seed(42)
km_cmp  <- kmeans(X_data, centers = 3, nstart = 50)
ari_km  <- round(mclust::adjustedRandIndex(km_cmp$cluster, cl_real), 3)

res_hc_cmp <- hclust(dist(X_data), method = "average")
cl_cah     <- cutree(res_hc_cmp, k = 3)
ari_cah    <- round(mclust::adjustedRandIndex(cl_cah, cl_real), 3)

mc_cmp <- Mclust(X_data[, 1:2], G = 3, verbose = FALSE)
ari_mc  <- round(mclust::adjustedRandIndex(mc_cmp$classification, cl_real), 3)

data.frame(
  Methode = c("K-means (K=3)", "CHA — Lien moyen (K=3)", "Mclust GMM (K=3)"),
  Donnees = c("V1, V2", "V1, V2", "V1, V2"),
  Forme   = c("Sphérique", "Quelconque", "Elliptique"),
  K_auto  = c("Non", "Coupure dendro", "BIC auto"),
  ARI     = c(ari_km, ari_cah, ari_mc)
) |>
  setNames(c("Méthode", "Données", "Forme des clusters", "K automatique ?", "ARI vs vérité terrain")) |>
  tt(caption = "Comparaison des méthodes sur les données Flynt & Dean (2016)") |>
  style_tt(j = 5, bold = TRUE)
```

#figure([
#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "0_4": 0, "1_4": 0, "2_4": 0, "3_4": 0
  )

  #let style-array = ( 
    // tinytable cell style after
    (bold: true,),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 5, stroke: 0.05em + black),
 table.hline(y: 4, start: 0, end: 5, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 5, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Méthode], [Données], [Forme des clusters], [K automatique ?], [ARI vs vérité terrain],
    ),
    // tinytable header end

    // tinytable cell content after
[K-means (K=3)], [V1, V2], [Sphérique], [Non], [0.798],
[CHA — Lien moyen (K=3)], [V1, V2], [Quelconque], [Coupure dendro], [0.534],
[Mclust GMM (K=3)], [V1, V2], [Elliptique], [BIC auto], [0.959],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-comparaison-methodes>


#block[
#callout(
body: 
[
Les trois méthodes sont évaluées sur les mêmes variables continues $(V_1 \, V_2)$ et la même vérité terrain, ce qui rend les ARI directement comparables. Mclust domine grâce à sa modélisation elliptique, tandis que la CHA souffre de ses fusions irréversibles (30% d'erreur).

]
, 
title: 
[
Lecture du tableau
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]

#horizontalrule

= Conclusion générale
<sec-conclusion>
== Bilan du parcours : de R aux méthodes non supervisées
<bilan-du-parcours-de-r-aux-méthodes-non-supervisées>
Ce document a constitué un voyage pédagogique en trois actes, tous ancrés dans l'unité d'enseignement ESD113 de Monsieur Karim KILANI.

Le #strong[premier acte] nous a conduits des fondements de R et de Quarto jusqu'à la maîtrise du Tidyverse : manipulation de données, statistiques descriptives, visualisation, et pipe natif. Ces outils constituent la grammaire de base de tout travail d'analyse avec R.

Le #strong[deuxième acte] a appliqué cette grammaire à un cas concret : les données de tirage du Keno. Chemin faisant, nous avons exploré le pivot, la modélisation probabiliste par la loi hypergéométrique, le calcul de l'espérance de gain et la simulation de Monte-Carlo. Ce dernier outil --- répéter à grande échelle des tirages aléatoires pour estimer des distributions --- est l'un des plus puissants de la boîte à outils statistique, et sa mise en œuvre en R s'avère remarquablement concise.

Le #strong[troisième acte] a plongé dans les méthodes de clustering, en reproduisant et en enrichissant les résultats de l'article fondateur de Flynt & Dean (2016). Trois méthodes ont été passées au crible :

+ #strong[K-means] : rapide, explicable, mais contraint par une hypothèse sphérique. Six variations d'implémentation ont montré qu'un même résultat statistique peut s'écrire de la ligne artisanale au graphique automatisé.
+ #strong[La CHA] : précieuse pour l'exploration multi-échelle via le dendrogramme, mais pénalisée par ses fusions irréversibles (30% d'erreur).
+ #strong[Mclust] : champion incontesté, avec #strong[98,67% de réussite];, grâce à sa modélisation elliptique et à la sélection automatique du modèle via le BIC.

== Ce que les données simulées nous ont appris
<ce-que-les-données-simulées-nous-ont-appris>
L'utilisation d'un fil conducteur unique --- les données de Flynt & Dean (2016) --- a mis en lumière une leçon centrale : le #strong[groupe elliptique est le vrai révélateur] des hypothèses implicites de chaque algorithme. K-means (\~7 % d'erreur sur ce groupe), CHA (30 % d'erreur globale), Mclust (1,33 % d'erreur) --- ces chiffres ne décrivent pas trois niveaux de complexité informatique, mais #strong[trois façons différentes de "voir" les données];.

== La hiérarchie de performance (contexte-dépendante)
<la-hiérarchie-de-performance-contexte-dépendante>
Pour ces données continues simulées, la hiérarchie de performance est claire :

```latex
$$\texttt{Mclust} \;>\; \texttt{K-means} \;>\; \texttt{CHA}$$
```

$ mono("Mclust") #h(0em) > #h(0em) mono("K-means") #h(0em) > #h(0em) mono("CHA") $

#table(
  columns: 2,
  align: (auto,auto,),
  table.header([Situation], [Méthode recommandée],),
  table.hline(),
  [Exploration rapide, $N$ grand], [K-means (nstart élevé)],
  [Clusters gaussiens, $K$ inconnu], [Mclust (BIC automatique)],
  [Lecture multi-échelle, exploration], [CHA + dendrogramme],
)
#block[
#callout(
body: 
[
Le clustering n'est pas une vérité : c'est une #strong[hypothèse de travail] que l'analyste fait sur la structure des données. La vraie compétence du data scientist est de choisir --- et de savoir justifier --- pourquoi une méthode est plus adaptée que les autres au problème posé.

]
, 
title: 
[
À retenir
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
== Applications concrètes du clustering dans la vie réelle
<applications-concrètes-du-clustering-dans-la-vie-réelle>
Le clustering n'est pas un exercice académique sur des données simulées : c'est l'un des outils les plus déployés dans les secteurs publics et privés.

#strong[Commerce et marketing --- la segmentation client.] Les enseignes de la grande distribution (Carrefour, Amazon, Fnac) appliquent quotidiennement le K-means ou les GMM à leurs bases de données d'achats. Chaque client se voit attribuer un segment qui pilote les campagnes e-mail, les recommandations produits et les programmes de fidélité. Spotify, Apple Music ou Netflix effectuent la même opération sur les comportements d'écoute ou de visionnage.

#strong[Santé et biologie --- la médecine de précision.] En oncologie, les chercheurs appliquent la CHA ou les GMM à des profils d'expression génique de tumeurs pour en identifier les sous-types moléculaires. C'est cette approche qui a conduit à distinguer plusieurs sous-types de cancer du sein (Luminal A, Luminal B, HER2-enrichi, Triple-négatif), chacun répondant différemment aux traitements.

#strong[Finance --- la détection de fraude.] Les départements de lutte anti-fraude des banques (BNP Paribas, Société Générale, Visa) utilisent des algorithmes de clustering non supervisé pour détecter les comportements de paiement anormaux. Un cluster de transactions nocturnes à l'étranger avec des montants inhabituels émerge automatiquement --- sans qu'on ait besoin de définir à l'avance ce qu'est une fraude.

#strong[Défense et sécurité nationale --- un enjeu croissant.] L'analyse de signaux électromagnétiques (SIGINT) utilise des algorithmes de partitionnement pour regrouper automatiquement les émissions radio selon leur signature spectrale. La fusion de données ISR (Intelligence, Surveillance, Reconnaissance) applique le clustering spatio-temporel pour détecter des patterns comportementaux anormaux sur un théâtre d'opérations. En cybersécurité de défense, les CERT militaires (comme le CALID en France) utilisent la classification non supervisée de logs systèmes pour isoler automatiquement les comportements malveillants --- notamment pour détecter les intrusions persistantes avancées (APT).

#strong[Image et vision par ordinateur.] La compression d'image JPEG utilise le K-means pour réduire la palette de couleurs d'une image. La segmentation d'images satellitaires --- qu'il s'agisse de cartographier des cultures agricoles ou de surveiller l'évolution du couvert forestier --- repose sur des algorithmes de clustering appliqués aux pixels selon leur signature spectrale (visible, infrarouge, radar).

#block[
#callout(
body: 
[
Dans tous ces domaines, la leçon reste la même : le clustering révèle une structure que les données portent en elles mais que l'analyste n'avait pas définie #emph[a priori];. Sa puissance réside précisément dans cette capacité à faire #emph[émerger] de la connaissance à partir de l'observation brute, sans étiquette préalable.

]
, 
title: 
[
À retenir
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
== Pour aller plus loin
<pour-aller-plus-loin>
- #strong[Flynt et Dean] #cite(<flynt2016>, form: "year") : la revue des packages R pour le clustering, article de référence de ce document.
- #strong[Fraley et Raftery] #cite(<fraley2002>, form: "year") : l'article fondateur de `Mclust` et des mélanges gaussiens.
- #strong[Everitt et al.] #cite(<everitt2011>, form: "year") : le livre de référence complet sur le clustering.
- #strong[Wickham et al.] #cite(<wickham2019>, form: "year") : l'écosystème `tidyverse`.

#horizontalrule

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
[
Références bibliographiques
]
)
]
#block[
] <refs>

#horizontalrule

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
[
Rapport de compilation
]
)
]
#block[
#heading(
level: 
2
, 
numbering: 
none
, 
[
Méthode de mesure du temps
]
)
]
Lorsque vous cliquez sur #strong[Render] dans RStudio, la compilation traverse trois phases dont seule la deuxième est mesurable depuis R :

#table(
  columns: (25%, 25%, 25%, 25%),
  align: (auto,auto,auto,center,),
  table.header([Phase], [Outil], [Ce qui se passe], [Mesurable ?],),
  table.hline(),
  [#strong[1 --- Quarto/pandoc];], [Quarto CLI], [Lit le `.qmd`, prépare knitr, lance R], [❌],
  [#strong[2 --- knitr (R)];], [knitr + R], [Exécute tous les chunks. `proc.time()` lancé au `setup`, arrêté au `timer-final-typst`.], [✅],
  [#strong[3 --- Rendu Typst];], [pandoc + typst], [Convertit le `.md` en `.pdf` via le moteur Typst], [❌],
)
#block[
#callout(
body: 
[
La #strong[somme des durées individuelles] mesure le temps CPU pur de chaque chunk. Le #strong[chronomètre global knitr] est supérieur car il inclut aussi le rendu ggplot2, les appels système et les I/O disque #emph[entre] les chunks. Les Phases 1 et 3 sont non mesurables depuis R.

]
, 
title: 
[
Pourquoi le total des chunks est inférieur au temps knitr global ?
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
#block[
#callout(
body: 
[
À la #strong[première compilation];, `[KNITR_TOTAL]` n'est pas encore dans le fichier (écrit par `timer-final-typst` #emph[après] les tableaux). #strong[Dès la deuxième compilation];, toutes les valeurs apparaissent --- le fichier `compilation_stats_typst.txt` contient les données de la session précédente.

]
, 
title: 
[
Disponibilité des données à la 2ème compilation
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
#block[
#heading(
level: 
2
, 
numbering: 
none
, 
[
Environnement système
]
)
]
#figure([
#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "0_0": 0, "1_0": 0, "2_0": 0, "3_0": 0, "4_0": 0, "5_0": 0, "6_0": 0, "7_0": 0
  )

  #let style-array = ( 
    // tinytable cell style after
    (bold: true,),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 2, stroke: 0.05em + black),
 table.hline(y: 8, start: 0, end: 2, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 2, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Paramètre], [Valeur],
    ),
    // tinytable header end

    // tinytable cell content after
[Plateforme], [unix],
[Système d'exploitation], [Ubuntu 24.04.4 LTS],
[Version R], [R version 4.5.3 (2026-03-11)],
[Processeur], [AMD EPYC 7R13 Processor],
[Cœurs logiques], [16],
[RAM totale (Go)], [132.2],
[Début phase knitr], [03/05/2026 07:03:15],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-sysinfo-typst>


#block[
#heading(
level: 
2
, 
numbering: 
none
, 
[
Temps d'exécution des chunks R (Phase 2)
]
)
]
#figure([
#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "0_0": 0, "3_0": 0, "4_0": 0, "5_0": 0, "6_0": 0, "7_0": 0, "8_0": 0, "9_0": 0, "10_0": 0, "11_0": 0, "12_0": 0, "13_0": 0, "14_0": 0, "15_0": 0, "16_0": 0, "17_0": 0, "18_0": 0, "19_0": 0, "20_0": 0, "21_0": 0, "22_0": 0, "23_0": 0, "24_0": 0, "25_0": 0, "26_0": 0, "27_0": 0, "28_0": 0, "29_0": 0, "30_0": 0, "31_0": 0, "32_0": 0, "33_0": 0, "34_0": 0, "35_0": 0, "36_0": 0, "37_0": 0, "38_0": 0, "39_0": 0, "40_0": 0, "41_0": 0, "42_0": 0, "43_0": 0, "44_0": 0, "45_0": 0, "46_0": 0, "47_0": 0, "48_0": 0, "49_0": 0, "50_0": 0, "51_0": 0, "52_0": 0, "53_0": 0, "54_0": 0, "55_0": 0, "56_0": 0, "57_0": 0, "0_1": 0, "3_1": 0, "4_1": 0, "5_1": 0, "6_1": 0, "7_1": 0, "8_1": 0, "9_1": 0, "10_1": 0, "11_1": 0, "12_1": 0, "13_1": 0, "14_1": 0, "15_1": 0, "16_1": 0, "17_1": 0, "18_1": 0, "19_1": 0, "20_1": 0, "21_1": 0, "22_1": 0, "23_1": 0, "24_1": 0, "25_1": 0, "26_1": 0, "27_1": 0, "28_1": 0, "29_1": 0, "30_1": 0, "31_1": 0, "32_1": 0, "33_1": 0, "34_1": 0, "35_1": 0, "36_1": 0, "37_1": 0, "38_1": 0, "39_1": 0, "40_1": 0, "41_1": 0, "42_1": 0, "43_1": 0, "44_1": 0, "45_1": 0, "46_1": 0, "47_1": 0, "48_1": 0, "49_1": 0, "50_1": 0, "51_1": 0, "52_1": 0, "53_1": 0, "54_1": 0, "55_1": 0, "56_1": 0, "57_1": 0, "1_0": 1, "2_0": 1, "1_1": 1, "2_1": 1, "0_3": 2, "3_3": 2, "4_3": 2, "5_3": 2, "6_3": 2, "7_3": 2, "8_3": 2, "9_3": 2, "10_3": 2, "11_3": 2, "12_3": 2, "13_3": 2, "14_3": 2, "15_3": 2, "16_3": 2, "17_3": 2, "18_3": 2, "19_3": 2, "20_3": 2, "21_3": 2, "22_3": 2, "23_3": 2, "24_3": 2, "25_3": 2, "26_3": 2, "27_3": 2, "28_3": 2, "29_3": 2, "30_3": 2, "31_3": 2, "32_3": 2, "33_3": 2, "34_3": 2, "35_3": 2, "36_3": 2, "37_3": 2, "38_3": 2, "39_3": 2, "40_3": 2, "41_3": 2, "42_3": 2, "43_3": 2, "44_3": 2, "45_3": 2, "46_3": 2, "47_3": 2, "48_3": 2, "49_3": 2, "50_3": 2, "51_3": 2, "52_3": 2, "53_3": 2, "54_3": 2, "55_3": 2, "56_3": 2, "57_3": 2, "1_3": 3, "2_3": 3, "0_2": 4, "3_2": 4, "4_2": 4, "5_2": 4, "6_2": 4, "7_2": 4, "8_2": 4, "9_2": 4, "10_2": 4, "11_2": 4, "12_2": 4, "13_2": 4, "14_2": 4, "15_2": 4, "16_2": 4, "17_2": 4, "18_2": 4, "19_2": 4, "20_2": 4, "21_2": 4, "22_2": 4, "23_2": 4, "24_2": 4, "25_2": 4, "26_2": 4, "27_2": 4, "28_2": 4, "29_2": 4, "30_2": 4, "31_2": 4, "32_2": 4, "33_2": 4, "34_2": 4, "35_2": 4, "36_2": 4, "37_2": 4, "38_2": 4, "39_2": 4, "40_2": 4, "41_2": 4, "42_2": 4, "43_2": 4, "44_2": 4, "45_2": 4, "46_2": 4, "47_2": 4, "48_2": 4, "49_2": 4, "50_2": 4, "51_2": 4, "52_2": 4, "53_2": 4, "54_2": 4, "55_2": 4, "56_2": 4, "57_2": 4, "1_2": 5, "2_2": 5
  )

  #let style-array = ( 
    // tinytable cell style after
    (align: center,),
    (background: rgb("#fff3cd"), align: center,),
    (bold: true, align: right,),
    (bold: true, background: rgb("#fff3cd"), align: right,),
    (mono: true,),
    (mono: true, background: rgb("#fff3cd"),),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 4, stroke: 0.05em + black),
 table.hline(y: 58, start: 0, end: 4, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 4, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Rang], [Statut], [Chunk R], [Duree (sec)],
    ),
    // tinytable header end

    // tinytable cell content after
[1], [LENT], [fig-dendro-color], [32.64],
[2], [LENT], [fig-dendro-circular], [14.14],
[3], [MOYEN], [fig-mclust-bic-fviz-v2], [1.90],
[4], [MOYEN], [montecarlo-grande-echelle], [1.86],
[5], [OK], [fig-simul-donnees], [0.72],
[6], [OK], [packages-clustering], [0.59],
[7], [OK], [var6-factoextra], [0.41],
[8], [OK], [fig-mclust-hull-v2], [0.41],
[9], [OK], [fig-dendro-simple], [0.40],
[10], [OK], [fig-mclust-classif-v2], [0.38],
[11], [OK], [ggplot-hist], [0.31],
[12], [OK], [fig-elbow], [0.28],
[13], [OK], [fig-kmeans-eval], [0.27],
[14], [OK], [plot-esperances], [0.26],
[15], [OK], [palmares-fdj], [0.25],
[16], [OK], [var2-for], [0.22],
[17], [OK], [fig-mclust-ellipses-v2], [0.22],
[18], [OK], [barchart-freq], [0.21],
[19], [OK], [var4-purrr], [0.21],
[20], [OK], [var5-broom], [0.21],
[21], [OK], [var1-manuelle], [0.20],
[22], [OK], [var3-sapply], [0.20],
[23], [OK], [polar-chart], [0.19],
[24], [OK], [fig-mclust-uncertainty-v2], [0.17],
[25], [OK], [freq-boules], [0.16],
[26], [OK], [tbl-comparaison-methodes], [0.16],
[27], [OK], [load-data], [0.15],
[28], [OK], [mclust-fit], [0.13],
[29], [OK], [montecarlo-proba], [0.10],
[30], [OK], [hist-base], [0.07],
[31], [OK], [gains-tableau-complet], [0.07],
[32], [OK], [seq-entiers], [0.06],
[33], [OK], [gains-calcul-long], [0.06],
[34], [OK], [stats-desc], [0.05],
[35], [OK], [pivot-exemple], [0.05],
[36], [OK], [keno-long], [0.05],
[37], [OK], [tableau-gains], [0.04],
[38], [OK], [gains-tableau-10], [0.04],
[39], [OK], [esperances-grilles], [0.04],
[40], [OK], [tbl-params-simulation], [0.04],
[41], [OK], [tbl-perf-mclust], [0.03],
[42], [OK], [tbl-sysinfo-typst], [0.03],
[43], [OK], [tidyverse-select], [0.02],
[44], [OK], [proba-gain], [0.02],
[45], [OK], [esperance], [0.02],
[46], [OK], [montecarlo-simple], [0.02],
[47], [OK], [tbl-synthese-variations], [0.02],
[48], [OK], [perf-kmeans], [0.02],
[49], [OK], [tbl-perf-kmeans], [0.02],
[50], [OK], [calcul-cah], [0.02],
[51], [OK], [base-r], [0.01],
[52], [OK], [filter-mpg], [0.01],
[53], [OK], [pivot-keno], [0.01],
[54], [OK], [format-dates], [0.01],
[55], [OK], [gains-data], [0.01],
[56], [OK], [montecarlo-replicate], [0.01],
[57], [OK], [seq-cdm], [0.00],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-timers-typst>


#block[
#heading(
level: 
2
, 
numbering: 
none
, 
[
Bilan global des phases
]
)
]
#figure([
#show figure: set block(breakable: true)

#block[ // start block

  #let style-dict = (
    // tinytable style-dict after
    "0_0": 0, "1_0": 0, "2_0": 0, "3_0": 0, "5_0": 0, "0_2": 0, "1_2": 0, "2_2": 0, "3_2": 0, "5_2": 0, "4_0": 1, "4_2": 1, "0_1": 2, "1_1": 2, "2_1": 2, "3_1": 2, "5_1": 2, "4_1": 3
  )

  #let style-array = ( 
    // tinytable cell style after
    (align: left,),
    (background: rgb("#d4edda"), align: left,),
    (bold: true, align: right,),
    (bold: true, background: rgb("#d4edda"), align: right,),
  )

  // Helper function to get cell style
  #let get-style(x, y) = {
    let key = str(y) + "_" + str(x)
    if key in style-dict { style-array.at(style-dict.at(key)) } else { none }
  }

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 { return it }
    
    let style = get-style(it.x, it.y)
    if style == none { return it }
    
    let tmp = it
    if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
    if ("color" in style) { tmp = text(fill: style.color, tmp) }
    if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
    if ("underline" in style) { tmp = underline(tmp) }
    if ("italic" in style) { tmp = emph(tmp) }
    if ("bold" in style) { tmp = strong(tmp) }
    if ("mono" in style) { tmp = math.mono(tmp) }
    if ("strikeout" in style) { tmp = strike(tmp) }
    if ("smallcaps" in style) { tmp = smallcaps(tmp) }
    tmp
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto),
    stroke: none,
    rows: auto,
    align: (x, y) => {
      let style = get-style(x, y)
      if style != none and "align" in style { style.align } else { left }
    },
    fill: (x, y) => {
      let style = get-style(x, y)
      if style != none and "background" in style { style.background }
    },
 table.hline(y: 1, start: 0, end: 3, stroke: 0.05em + black),
 table.hline(y: 6, start: 0, end: 3, stroke: 0.08em + black),
 table.hline(y: 0, start: 0, end: 3, stroke: 0.08em + black),
    // tinytable lines before

    // tinytable header start
    table.header(
      repeat: true,
[Phase], [Durée mesurée], [Remarque],
    ),
    // tinytable header end

    // tinytable cell content after
[Phase 1 -- Quarto / pandoc], [Non mesurable], [~2-5 sec estimees],
[Phase 2a -- Execution chunks R (somme)], [58.30 sec], [Mesure chunk par chunk],
[Phase 2b -- Overhead knitr (I/O, rendus)], [~-2.0 sec], [Rendu ggplot2, I/O fichiers],
[Phase 2 -- Total knitr mesure], [56.3 sec], [Seule valeur exacte],
[Phase 3 -- Rendu Typst (pandoc)], [Non mesurable], [Generalement < 10 sec pour Typst],

    // tinytable footer after

  ) // end table

  ]) // end align

] // end block
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-bilan-typst>


#block[
#callout(
body: 
[
Au lancement de chaque compilation, le chunk `setup` lit le fichier `compilation_stats_typst.txt` #emph[avant] de l'écraser, et sauvegarde en mémoire le `[KNITR_TOTAL]` de la session précédente. Cette valeur est ainsi disponible #strong[dès la première compilation] qui suit une compilation complète. Les tableaux affichent donc : la somme des chunks R de la compilation #emph[en cours];, et le total knitr de la compilation #emph[précédente] --- ce qui est la seule approche fiable, puisque `timer-final-typst` écrit ce total #emph[après] que tous les tableaux ont été générés.

]
, 
title: 
[
Comment fonctionne le timer ?
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]




#bibliography("refs-esd113.bib")

