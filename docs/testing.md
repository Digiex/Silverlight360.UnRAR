# Testing

## In xenia-edge

```powershell
.\tests\make_archives.ps1 -ContentRoot $env:TEMP\unrar-content -Work $env:TEMP\unrar-tree -Large path\to\large.rar
..\XboxSilverlightSdk\tools\Test-XboxApp.ps1 -Xex .\sample\bin\Release\xbox\default.xex -Output $env:TEMP\unrar-run `
    -ExtraArgs "--content_root=$env:TEMP\unrar-content" -Seconds 60
python tests\verify_output.py $env:TEMP\unrar-tree\manifest.json $env:TEMP\unrar-content\UnRarTest\out `
    0-rar5 1-rar4 2-store 3-solid 4-password 5-split.part1
```

`make_archives.ps1` writes a 5 MB test tree and archives it six ways with WinRAR's `Rar.exe`, and copies `-Large`, any large archive, in as `large.rar`. xenia-edge's hard disk is its content folder, `hdd:\Content`, so the archives go in `<content root>\UnRarTest\in` and come out in `UnRarTest\out`. The log has a `PASS:` or `FAIL:` line for each case. Clear `out` between runs: xenia-edge shows a folder in a content-type folder that holds one file, as a package's `.data` folder can, as that one file, so a second run can't write into it.

What passed in xenia-edge, 2026-11-07, with the DLL at `0x8F000000`, built against xsdk's `dll-modules` `libxsdk.a`:

- RAR5, RAR4, stored, solid, encrypted and split archives of the 5 MB tree, every file matching its hash (`verify_output.py`);
- a missing archive and a wrong password, with their codes;
- a 61 MB archive of a 75 MB Games on Demand package in 871 ms, and cancelling it after 16 MB;
- the heap peaked at 8.4 MB.

On 2026-11-02, at the old base, the large archive also came out byte for byte as WinRAR extracts it.

## On a console

Before an app calls a new build, check that the console loads it: a DllImport of a module that can't load turns into a call through null, which can power the console off. The CLR loads a DllImport module as `GAME:\<name>` with `XexLoadImage` flags 9; Silverdash360's debug server does the same with `xex.probe GAME:\unrar360.xex 9`, then unloads it.

What ran on a console, 2026-11-07 (retail kernel 2.0.17559, running unsigned code): `XexLoadImage` loaded the DLL at `0x8F000000` (status 0) in Silverdash360's process, with Silverlight360.Https's DLL loaded at `0x8D000000`. The first build, at `0x8C000000`, couldn't have: that base is taken in a Silverlight app's process there. An extraction on a console hasn't been run yet.
