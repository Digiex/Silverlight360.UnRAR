# Licenses

Silverlight360.UnRAR itself, its C and C++ code, `RarExtractor.cs`, its build and its documentation, is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0) with an additional condition: any project made with it must include a visible reference to <https://github.com/Digiex/Silverlight360.UnRAR> in its documentation, credits or "about" information. A project made with it includes an app shipped with `unrar360.xex` or `Silverlight360.UnRAR.dll`. See [LICENSE.md](https://github.com/Digiex/Silverlight360.UnRAR/blob/master/LICENSE.md).

`unrar360.xex` is built from UnRAR's source, which keeps its own license, by Alexander Roshal: [licenses/unrar.txt](https://github.com/Digiex/Silverlight360.UnRAR/blob/master/licenses/unrar.txt), with [THIRD-PARTY-NOTICES.md](https://github.com/Digiex/Silverlight360.UnRAR/blob/master/THIRD-PARTY-NOTICES.md). An app that ships the DLL ships that license with it; a release has it in its `licenses` folder. In short, it:

- allows using UnRAR's source to handle RAR archives in any software, free of charge;
- doesn't allow using it to make a RAR-compatible archiver, or to recreate RAR's compression;
- asks that a modified copy of the source keep its second paragraph, the one starting "UnRAR source code", in the license or documentation and in the source's comments. This project doesn't modify the source: it's built as it comes, with `src/compat.h` included ahead of it.

The repository doesn't hold UnRAR's source: `tools\Configure.ps1` downloads it from rarlab.com, checked against its SHA-256.
