# openlaw

This builds toward a minimal toolset for the display and analysis of legislative, regulatory, and judicial documents with the [Akoma Ntoso](http://www.akomantoso.org/) and related legal document standards.

## Rationale

"Ignorance of the law is no excuse," as the saying goes, but a majority of citizens, nationals and residents are not informed about the law due to its inaccessibility, cost, language, complexity, volume, and rapid change. The law shapes economics and society, and thus the majority are denied the full profits of their democratic labor.

Overcoming these barriers is a necessary step for democratic control of government and polical parties. This is meant as a working demonstration of using standard formats to reduce the burden.

## Utilities

* The `akncat` utility provides functionality similar to the UNIX [`cat`](https://en.wikipedia.org/wiki/Cat_(Unix)) utility but for Akoma Ntoso documents.
* The `Import-AkomaNtoso` [PowerShell](https://en.wikipedia.org/wiki/Windows_Terminal) cmdlet provides similarly for the .NET environment.
* There is also an [NLTK](http://www.nltk.org/) corpus reader for natural language processing in Python.

## Data

The current legal datasets have conversions to Akoma Ntoso:

* Colorado Revised Statutes: ¯\_(ツ)_/¯
* ~~United States Code~~: Cornell LII LexCraft was superseded by USLM.
* ~~California codified statutes~~: Out of date?

## License

Copyright is waived, see the CC0 in the LICENSE file.

## Caveat emptor

This is by me for me. These legal dataset conversions are experimental, and should not be considered a faithful or official reproduction. They are currently not conformant to the Akoma Ntoso standard and no tests are done for their validity or compatibility. Given the nature of the collection processes, e.g., lack of documentation, much has been interpreted and misinterpreted. The code will probably break things! See the LICENSE file.
