# Building

The DLL builds in WSL (or on Linux) with xsdk's toolchain. Clone it, then set up the rest, in PowerShell:

```powershell
git clone https://github.com/Digiex/Silverlight360.UnRAR.git
cd Silverlight360.UnRAR
.\tools\Configure.ps1
```

`Configure.ps1` gets what the build needs, each the way that suits it:

| | | |
|---|---|---|
| **UnRAR's source** | UnRAR 7.3.2, which RARLAB publishes only as a tarball | `unrarsrc-7.3.2.tar.gz` downloaded from rarlab.com into `third_party\`, checked against its SHA-256, and unpacked into `third_party\unrar`; git ignores both. Another version is a change of `$unrarVersion` and `$unrarSha256` in the script |
| **xsdk** | [jessenic/xsdk](https://github.com/jessenic/xsdk), branch `dll-modules`, the build XboxNGen uses: its `elf2xex.py` has `--dll`, and its `build/libxsdk.a` is what the DLL links | Found from `-Xsdk`, `XSDK`, XboxNGen's configuration beside this repository, or a checkout two folders up (`C:\Proj\xsdk`) or beside it; otherwise cloned two folders up, if you say so. `libxsdk.a` is built if it isn't |
| **xsdk's toolchain** | GCC 15.3, binutils and newlib for `powerpc-xsdk-elf`, in WSL | Found in `~/xsdk-gcc` or at `-Toolchain`; otherwise built there with xsdk's `tools/toolchain/build.sh`, if you say so: about 10 minutes, and a 136 MB download of their sources |
| **Silverlight360** | The SDK, for `Silverlight360.UnRAR.dll` and the sample | Found from `-Silverlight360`, its environment variable, or a checkout beside this repository; otherwise cloned there, if you say so |

It also checks WSL has `make`, `cmake`, `ninja`, `python3` and `git` (`sudo apt install build-essential cmake ninja-build python3 git` in Debian). `-NonInteractive` asks nothing: `-CloneXsdk`, `-BuildToolchain` and `-CloneSilverlight360` say what it may fetch or build. It writes `config.mk` (`XSDK` and `TOOLCHAIN` as WSL sees them, for the Makefile), `config.props` (for the C# projects) and `config.json` (for `tools\Release.ps1`); git ignores them, and `-Show` prints them.

Then, in WSL, in the repository's folder:

```bash
make -j$(nproc)
```

That writes `unrar360.xex` (750 KB). UnRAR's source is built as it comes, with `src/compat.h` included ahead of it for what xsdk lacks, so it isn't modified. `make clean` starts over; the Makefile's `XSDK`, `TOOLCHAIN` and `ELF2XEX` can be given on its command line to build with something else.

## Silverlight360.UnRAR.dll

The C# side builds as a Silverlight360 class library, in PowerShell, with Silverlight360 where `.\tools\Configure.ps1 -Show` says (here beside this repository, as `XboxSilverlightSdk`):

```powershell
..\XboxSilverlightSdk\tools\Build-XboxApp.ps1 -Project .\csharp\Silverlight360.UnRAR.csproj
```

That writes `csharp\bin\Release\Silverlight360.UnRAR.dll` and `Silverlight360.UnRAR.xml`, its documentation for IntelliSense, with `Silverlight360.Common.dll`, which it references, beside them.

## The sample

`sample/` is a Silverlight360 app that extracts each test archive and checks the result:

```powershell
..\XboxSilverlightSdk\tools\Build-XboxApp.ps1 -Project .\sample\UnRarSample.csproj
```

See [Testing](testing.md) for running it.
