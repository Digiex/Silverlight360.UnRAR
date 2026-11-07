# Contributing

Bug reports, fixes and improvements are welcome on [GitHub](https://github.com/Digiex/Silverlight360.UnRAR).

1. Say what you're changing in an issue first if it's more than a small fix, so the work isn't done twice.
2. Run `.\tools\Configure.ps1`, build it ([Building](building.md)) and run the sample's checks in xenia-edge ([Testing](testing.md)). A change to the DLL's loading, its memory or its layout should be tried on a console too, with the DLL probed first.
3. Keep UnRAR's source as it comes: what xsdk lacks goes in `src/compat.h` and `src/posix.c`, not in a change to the source. A move to a newer UnRAR is a change of the version and SHA-256 in `tools\Configure.ps1`.
4. Keep `RarExtractor.cs` building for Silverlight 3's C#, and the API in [API](api.md) up to date with what it has.
5. Open a pull request against `master`. The docs site is built for it, so a broken link shows before the merge.

Don't send code or files from the Xbox 360 SDK, or from projects whose licenses don't allow it.

## License

Silverlight360.UnRAR is licensed under the [PolyForm Noncommercial License 1.0.0](https://github.com/Digiex/Silverlight360.UnRAR/blob/master/LICENSE.md) with an additional condition. By opening a pull request, you agree that your contribution is licensed under the same terms.
