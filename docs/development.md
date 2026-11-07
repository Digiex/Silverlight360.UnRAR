# Development

## What's here

| | |
|---|---|
| `src/extract.cpp` | The DLL's extraction API, on UnRAR's own library interface (`dll.hpp`) |
| `src/runtime.c`, `src/runtime.h` | The C and C++ runtime xsdk's title start would set up, set up by `unrar360_init` instead, with a bounded heap |
| `src/posix.c`, `src/compat.h` | The POSIX calls UnRAR's Unix build makes that xsdk doesn't have |
| `src/export.h` | `UNRAR360_EXPORT`, which gives a function an ordinal for elf2xex |
| `unrar360.ld`, `Makefile` | The DLL's layout, at base `0x8F000000`, and its build |
| `third_party/unrar` | UnRAR's source, which `tools\Configure.ps1` fetches (git ignores it) |
| `csharp/RarExtractor.cs` | The C# side: `DllImport`s by ordinal, and progress read from a pinned buffer |
| `csharp/Silverlight360.UnRAR.csproj` | Builds it as `Silverlight360.UnRAR.dll`, a Silverlight360 class library, with its XML documentation |
| `sample/` | A Silverlight360 app that extracts each test archive and checks the result |
| `tests/` | The test archives' maker, and a check of what the sample extracted |
| `tools/Configure.ps1`, `tools/Config.ps1` | Sets up the build ([Building](building.md)), and reads what it saved |
| `tools/Release.ps1` | Builds a release and publishes it on GitHub |
| `docs/`, `mkdocs.yml` | This site |

The C side and the C# side share the layout of the progress buffer (`src/extract.cpp`, and the offsets at the top of `RarExtractor.cs`), big-endian; a change to one is a change to both. The exports are by ordinal, `#1` to `#5`: the `UNRAR360_EXPORT` lines in the sources, and the `DllImport`s.

## Releasing

```powershell
.\tools\Release.ps1 -DryRun     # builds and zips, shows the notes, publishes nothing
.\tools\Release.ps1             # 0.1.0 first, then the last release's patch raised
.\tools\Release.ps1 -Bump Minor
```

As Silverdash360's and Silverlight360.Https's release scripts do:

1. The release is made from the commit as it is: nothing may be uncommitted, and the commit must be on GitHub already. Nothing is pushed.
2. The version is `-Version` if given, else the last release's (the highest `v<version>` tag) with its patch, or `-Bump`'s part, raised. It's tagged `v<version>` on the commit, by `gh`.
3. The DLL is built from scratch in WSL (`make clean`, then `make`), with what `tools\Configure.ps1` set up.
4. `Silverlight360.UnRAR.dll` and `Silverlight360.UnRAR.xml` are built from `csharp\Silverlight360.UnRAR.csproj` by Silverlight360's `tools\Build-XboxApp.ps1`, so a release needs Silverlight360 configured.
5. `Silverlight360.UnRAR-<version>.zip`, in `build\release`, has in a `Silverlight360.UnRAR` folder `unrar360.xex`, `Silverlight360.UnRAR.dll`, `Silverlight360.UnRAR.xml`, `README.md`, `LICENSE.md`, `THIRD-PARTY-NOTICES.md`, `licenses\` and `BUILD.txt`, which records the commits of Silverlight360.UnRAR and xsdk it was built from, UnRAR's version, and the toolchain.
6. The release's notes are the commits since the last release, and the zip is its file.

It needs the GitHub CLI (`gh`), signed in, unless `-DryRun`. Test a build before releasing it ([Testing](testing.md)): the script builds it, it doesn't run it.

## The docs

This site is the `docs` folder, built with [MkDocs](https://www.mkdocs.org/) (`mkdocs.yml`). A push to `master` that changes it publishes it to GitHub Pages (`.github/workflows/docs.yml`). To preview it:

```bash
pip install mkdocs==1.6.1
python -m mkdocs serve
```
