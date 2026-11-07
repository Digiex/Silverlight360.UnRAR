# API

`Silverlight360.UnRAR.dll` (`csharp/RarExtractor.cs`), namespace `Silverlight360.UnRAR`.

## RarExtractor

| | |
|---|---|
| `new RarExtractor()` | An extractor; the first one's `Extract` starts the DLL if `Start` hasn't |
| `int Extract(string archive, string destination, string password)` | Extracts every file of the archive into the destination folder, keeping the archive's folders and making those missing; `password` may be null. Returns `Success` or one of UnRAR's `ERAR_` codes (below) |
| `void Cancel()` | From another thread: stops the extraction at its next block of data; `Extract` returns 21 |
| `int FilesDone` | Entries extracted so far, folders among them |
| `long BytesDone` | Bytes written so far |
| `string CurrentFile` | The file being extracted, or the last |
| `string Message` | What went wrong, after an `Extract` that didn't return `Success`: the file and UnRAR's error |
| `static string Describe(int code)` | A code's meaning, as "wrong password" |
| `void Dispose()` | Frees the extractor's progress buffer |

The DLL, for all extractors:

| | |
|---|---|
| `const uint DefaultHeapBytes` | 128 MB: the heap `Extract` starts the DLL with if `Start` hasn't |
| `static void Start(uint heapBytes)` | Starts the DLL with a heap of up to `heapBytes`, reserved now and committed as it's used; once |
| `static uint Version` | The wrapper's API version, then UnRAR's library version, 16 bits each |
| `static uint HeapCommitted`, `static uint HeapPeak` | The DLL's heap in use now, and the most it has held at once: what to size `Start` by |

## Codes

| | Code | |
|---|---|---|
| `Success` | 0 | Extracted |
| | 11 | Not enough memory: the archive's dictionary doesn't fit the heap |
| | 12, 13 | Damaged data, or a damaged archive |
| | 14 | Unknown format |
| | 15 | Can't open the archive |
| | 16, 17 | Can't create or close a file, such as a name over FATX's 42 characters |
| | 18, 19 | Read or write error |
| | 21 | Stopped (`Cancel`), or an unknown error |
| `MissingPassword` | 22 | The archive is encrypted and no password was given |
| `BadPassword` | 24 | Wrong password |
| | 25 | Dictionary too large |
