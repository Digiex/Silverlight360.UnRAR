# Silverlight360.UnRAR

Extracts RAR archives on the Xbox 360's own drives from a [Silverlight360](https://github.com/Digiex/Silverlight360) app. UnRAR 7.3.2's library, built with xsdk into a DLL of its own, `unrar360.xex`, does the reading, decompressing and writing natively; the app passes paths and watches progress through `RarExtractor`.

**Documentation: <https://digiex.github.io/Silverlight360.UnRAR/>**

```csharp
using (var rar = new RarExtractor())
{
    // On a thread of its own: Extract returns when the archive is done.
    int result = rar.Extract(@"hdd:\Downloads\game.part1.rar", @"hdd:\Games\Game", null);
    if (result != RarExtractor.Success)
        Show(RarExtractor.Describe(result) + ": " + rar.Message);
}
```

RAR5 and RAR4 archives, stored, solid, encrypted and split into volumes. The archive never passes through managed memory, so its size doesn't matter, and decompressing runs natively, not in the console's interpreted app code.

- **Using it:** a [release](https://github.com/Digiex/Silverlight360.UnRAR/releases) has `unrar360.xex`, `Silverlight360.UnRAR.dll` with its XML documentation, and UnRAR's license, which goes with them. See [Adding it to an app](https://digiex.github.io/Silverlight360.UnRAR/using/) and the [API](https://digiex.github.io/Silverlight360.UnRAR/api/).
- **Building it:** run `.\tools\Configure.ps1`, which fetches UnRAR's source and sets up xsdk and its toolchain, then `make` in WSL. See [Building](https://digiex.github.io/Silverlight360.UnRAR/building/).
- **Testing it:** the sample app's checks, in xenia-edge or on a console. See [Testing](https://digiex.github.io/Silverlight360.UnRAR/testing/).

## License

Silverlight360.UnRAR is licensed under the PolyForm Noncommercial License 1.0.0, with an additional condition: projects made with it must reference this repository. See [LICENSE.md](LICENSE.md).

UnRAR's source is freeware under its own license, [licenses/unrar.txt](licenses/unrar.txt), which goes with `unrar360.xex` (see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)). It allows using the source to handle RAR archives in any software, but not to make a RAR-compatible archiver or to recreate RAR's compression. The repository doesn't hold the source: `tools\Configure.ps1` downloads it from rarlab.com.
