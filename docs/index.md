# Silverlight360.UnRAR

Extracts RAR archives on the Xbox 360's own drives from a [Silverlight360](https://github.com/Digiex/Silverlight360) app. UnRAR 7.3.2's library, built with xsdk into a DLL of its own, `unrar360.xex`, does the reading, decompressing and writing natively; the app passes paths and watches progress through `RarExtractor`.

```csharp
using (var rar = new RarExtractor())
{
    // On a thread of its own: Extract returns when the archive is done.
    int result = rar.Extract(@"hdd:\Downloads\game.part1.rar", @"hdd:\Games\Game", null);
    if (result != RarExtractor.Success)
        Show(RarExtractor.Describe(result) + ": " + rar.Message);
}
```

Paths are the console's, as xsdk names its drives: `hdd:\` the hard disk's data partition, `usb:\` (or `usb0:` to `usb2:`) the USB drives, `game:\` the app's own folder. The archive never passes through managed memory, so its size doesn't matter. An app's own code runs interpreted on the console, and decompressing in C# would be far too slow ([Silverlight360's Performance](https://digiex.github.io/Silverlight360/performance/)).

RAR5 and RAR4 archives, stored, solid, encrypted and split into volumes, are extracted; a 61 MB archive of a 75 MB package takes under a second in xenia-edge.

## Getting it

A [release](https://github.com/Digiex/Silverlight360.UnRAR/releases) has what an app needs, built:

| | |
|---|---|
| `unrar360.xex` | The DLL, at base `0x8F000000` |
| `Silverlight360.UnRAR.dll`, `Silverlight360.UnRAR.xml` | The C# side, `RarExtractor`, with its documentation for IntelliSense. It needs Silverlight360.Common, which an app built with Silverlight360 has |
| `licenses/unrar.txt`, `THIRD-PARTY-NOTICES.md` | UnRAR's license, which goes with the DLL |
| `LICENSE.md`, `README.md`, `BUILD.txt` | Silverlight360.UnRAR's license, and what the release was built from |

Then see [Adding it to an app](using.md). To build it yourself, see [Building](building.md).

## Where it runs

In [xenia-edge](https://github.com/jessenic/xenia-edge), where every check of the sample passes, and on a console (retail kernel 2.0.17559, running unsigned code), where the DLL loads in a Silverlight app's process beside [Silverlight360.Https](https://digiex.github.io/Silverlight360.Https/). See [Testing](testing.md) for what was checked where.
