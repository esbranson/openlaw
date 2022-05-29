# Open Law

This project builds toward a toolset for the conversion and analysis of legislative, regulatory and judicial documents with the [Akoma Ntoso](http://www.akomantoso.org/) legal document standard.

Help by converting legal documents—anything!—into Akoma Ntoso XML, and of course applications consuming the same. This project is only meant as a working demonstration of the possibilities, and for my own personal goals.

# Rationale

"Ignorance of the law is no excuse," as the saying goes, but a majority of citizens, nationals and residents are not informed about the law due to its inaccessibility, cost, language, complexity, volume, and rapid change. The law shapes economics and society, and thus the majority are denied the full profits of their democratic labor.

Overcoming these barriers is a necessary step for true government and political transparency.

# Architecture

This code buils towards a standards-based presentation of "the law" over the World Wide Web.

## Utilities

A minimal toolchain for analysis of legal information.

The `akncat` utility provides functionality similar to the UNIX `cat` utility but for Akoma Ntoso documents. There is also an [NLTK](http://www.nltk.org/) corpus reader for natural language processing. The PowerShell module provides convenience functions relevant to .NET environments.

## Data

The current legal datasets have conversions to Akoma Ntoso:

* ~~United States Code~~: Cornell LII LexCraft was superseded by USLM, previous codebase was largely abandoned.
* ~~California codified statutes~~: Out of date?
* ~~Colorado Revised Statutes~~: Out of date?

# Caveat emptor

These legal dataset conversions are experimental, and should not be considered a faithful or official reproduction. They are currently non-conformant to the Akoma Ntoso standard and no tests are done for their validity or compatibility. Given the nature of the collection processes, e.g., lack of documentation, much has been interpreted and misinterpreted. The code may break things!