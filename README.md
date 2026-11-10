# ESD113 — Probabilités et statistique avec R

**De l'introduction à R au clustering : Keno, Tidyverse et méthodes non supervisées**

Document de synthèse rédigé dans le cadre de l'unité d'enseignement ESD113 du CNAM.
Il est écrit avec [Quarto](https://quarto.org) et R, et tout le code est exécuté à la compilation.

- **Lire en ligne (HTML)** : <https://albanpjy.github.io/ESD113/>
- **Version PDF** : <https://albanpjy.github.io/ESD113/esd113_complet_plus_19_pdf_posit.pdf>

## Contenu

| Partie | Sujet |
|---|---|
| I | Introduction à R, Quarto, Markdown et au Tidyverse ; premières visualisations (ggplot2, plotly) |
| II | Projet Keno : analyse des tirages FDJ, fréquences des boules, modélisation probabiliste, espérance de gain, simulation de Monte-Carlo |
| III | Classification non supervisée : K-means, classification hiérarchique (dendrogrammes), modèles de mélange gaussiens (mclust) |

## Organisation du dépôt

| Emplacement | Rôle |
|---|---|
| `index.qmd` / `index.html` | Source et rendu de la version HTML, publiée par GitHub Pages |
| `esd113_complet_plus_19_pdf.qmd` / `…_posit.pdf` | Source et rendu de la version PDF courante (LaTeX) |
| `keno_202511.csv` | Historique des tirages Keno (FDJ) utilisé dans la partie II |
| `references_complet.bib`, `custom.css`, images | Ressources nécessaires à la compilation |
| `compilation_stats*.txt` | Temps de compilation par bloc, écrits et relus par le document lui-même |
| `doc/` | Articles de référence |
| `rsconnect/` | Configuration de publication RPubs générée par RStudio |
| `archives/pdf/` | Versions PDF antérieures (15 à 18), sources et rendus |
| `archives/typst/` | Essais de mise en page Typst (v3 à v5) avec leurs styles, bibliographie et figures |
| `archives/html/` | Copie de la version HTML v7 et anciennes ressources du site |
| `archives/divers/` | Fichiers non utilisés par la version courante |

Les versions archivées sont conservées pour mémoire et ne sont plus maintenues ; pour les recompiler, il faut les replacer à la racine, à côté de leurs ressources.

## Recompiler

Prérequis : R ≥ 4.5, Quarto, et pour le PDF une distribution LaTeX (`quarto install tinytex`).

```bash
quarto render index.qmd
```

```bash
quarto render esd113_complet_plus_19_pdf.qmd
```

Les paquets R utilisés sont chargés au début de chaque fichier `.qmd`
(tidyverse, plotly, factoextra, mclust, kableExtra…).

## Auteur

Alban Videloup — auditeur CNAM.
