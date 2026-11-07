# Adding it to an app

An app needs the C# side and the DLL beside `default.xex`:

- **`Silverlight360.UnRAR.dll`**, `RarExtractor`, with `Silverlight360.UnRAR.xml` beside it for IntelliSense: a reference to the release's DLL, or a `ProjectReference` to the repository's `csharp/Silverlight360.UnRAR.csproj`.
- **`unrar360.xex`**, as `Content`.

The C# side uses `NativeBuffer` from Silverlight360's [common library](https://digiex.github.io/Silverlight360/common-library/), Silverlight360.Common, for the progress the DLL writes. An app built with Silverlight360 references that library already, and its build puts `Silverlight360.Common.dll` in the package.

In the app's project, as `sample/UnRarSample.csproj` has them:

```xml
<ItemGroup>
  <ProjectReference Include="..\Silverlight360.UnRAR\csharp\Silverlight360.UnRAR.csproj" />
  <!-- or, from a release: <Reference Include="Silverlight360.UnRAR"><HintPath>..\Silverlight360.UnRAR\Silverlight360.UnRAR.dll</HintPath></Reference> -->
</ItemGroup>
<ItemGroup>
  <Content Include="..\Silverlight360.UnRAR\unrar360.xex"><Link>unrar360.xex</Link></Content>
</ItemGroup>
```

Ship the release's `licenses/unrar.txt` and `THIRD-PARTY-NOTICES.md` with them: `unrar360.xex` is built from UnRAR's source, under its own license. Silverlight360.UnRAR's own license asks for a visible reference to <https://github.com/Digiex/Silverlight360.UnRAR> in the app's documentation, credits or "about" information (see [Licenses](licenses.md)).

## Extracting

`Extract` blocks until the archive is done, so call it on a thread of its own, never the UI's, and read the progress from the UI's:

```csharp
var rar = new RarExtractor();
ThreadPool.QueueUserWorkItem(delegate
{
    int result = rar.Extract(@"usb:\Downloads\movie.rar", @"hdd:\Videos\Movie", null);
    Deployment.Current.Dispatcher.BeginInvoke(() =>
        Show(result == RarExtractor.Success ? "Done" : RarExtractor.Describe(result) + ": " + rar.Message));
    rar.Dispose();
});

// On a timer on the UI thread:
Status.Text = rar.FilesDone + " files, " + rar.BytesDone / (1 << 20) + " MB: " + rar.CurrentFile;
```

- **One extraction at a time per extractor.** `Cancel`, `FilesDone`, `BytesDone` and `CurrentFile` are for other threads.
- **Folders are kept** as the archive has them, and those missing are made. A split archive's other volumes must be beside the first.
- **A password** goes to `Extract`; a wrong one returns `BadPassword`, and none for an encrypted archive `MissingPassword`.
- **The first extraction starts the DLL** with a heap of `DefaultHeapBytes` (128 MB, reserved and committed as it's used): RAR5's 32 MB dictionary and more. Call `RarExtractor.Start(bytes)` before the first one for another size; `HeapPeak` says what an extraction needed (8.4 MB for the test archives).
- **The DLL loads at `0x8F000000`.** In a Silverlight app's process on the console, `0x8A000000`, `0x8C000000` and `0x8E000000` are taken and Silverlight360.Https has `0x8D000000`, so another DLL of the app's own needs a base of its own. A DllImport of a module that can't load turns into a call through null, which can power the console off, so check a new build loads first (see [Testing](testing.md)).

See [API](api.md) for everything an extractor has.
