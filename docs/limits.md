# Limits

- **FATX names.** The console's file system takes names of up to 42 characters; an archive holding longer ones fails at that file with "can't create a file".
- **No file times or owners.** xsdk has no `utimensat` or `lchown`, so extracted files keep the time they were written. The read-only attribute is set, through xsdk's `chmod`.
- **One thread.** UnRAR's own threads (`RAR_SMP`) are left out; the console has six hardware threads to try them on.
- **Memory.** The heap is reserved up front (128 MB unless `Start` says otherwise) and committed as used. An archive whose dictionary doesn't fit fails with "not enough memory". RAR5's dictionaries go up to 4 GB and RAR7's further.
- **A fatal error in the DLL** (an `abort`) stops the extraction's thread for good rather than the app, and the log says why: there's no way to end only the DLL.
- **The log** is the host title's, `default.log` in `game:\`, where `game:` can be written.
- **One base address.** The DLL is linked at `0x8F000000`, one of the bases free in a Silverlight app's process on the console; another DLL in the same app needs another.
- **Extracting only.** UnRAR's license allows handling RAR archives, not making them (see [Licenses](licenses.md)).
