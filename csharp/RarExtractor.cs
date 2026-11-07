using System;
using System.Runtime.InteropServices;
using Silverlight360;

namespace Silverlight360.UnRAR
{
    /// <summary>
    /// Extracts RAR archives on the console's drives with unrar360.xex, which
    /// goes in the package beside default.xex. Paths are the console's, as
    /// xsdk names its drives: "hdd:\Games\a.rar", "usb:\a.rar", "game:\a.rar".
    /// The native side reads and writes the files itself, so an archive never
    /// passes through managed memory.
    /// </summary>
    /// <remarks>
    /// Extract blocks until the archive is done, so call it on a thread of
    /// its own. One extraction at a time per RarExtractor; Progress and
    /// Cancel are for other threads, such as the UI's.
    /// </remarks>
    public sealed class RarExtractor : IDisposable
    {
        /// <summary>The heap Start gives the DLL by default: room for RAR5's 32 MB dictionary and more.</summary>
        public const uint DefaultHeapBytes = 128u << 20;

        // dll.hpp's ERAR_ codes.
        public const int Success = 0;
        public const int MissingPassword = 22;
        public const int BadPassword = 24;

        private const string Module = "unrar360.xex";

        // src/extract.cpp's Progress, big-endian.
        private const int CancelOffset = 0;
        private const int FilesOffset = 4;
        private const int BytesOffset = 8;
        private const int NameOffset = 16;
        private const int NameBytes = 256;
        private const int MessageOffset = NameOffset + NameBytes;
        private const int MessageBytes = 256;
        private const int ProgressBytes = MessageOffset + MessageBytes;

        private static readonly object startLock = new object();
        private static bool started;

        private readonly NativeBuffer progress = new NativeBuffer(ProgressBytes);

        [DllImport(Module, EntryPoint = "#1")]
        private static extern uint unrar360_version();

        [DllImport(Module, EntryPoint = "#2")]
        private static extern int unrar360_init(uint heapBytes);

        [DllImport(Module, EntryPoint = "#3", CharSet = CharSet.Ansi)]
        private static extern int unrar360_extract(string archive, string destination, string password, uint progress);

        [DllImport(Module, EntryPoint = "#4")]
        private static extern uint unrar360_heap_committed();

        [DllImport(Module, EntryPoint = "#5")]
        private static extern uint unrar360_heap_peak();

        /// <summary>
        /// Sets the DLL's runtime up with a heap of up to heapBytes, reserved
        /// now and committed as it's used. Once; Extract does it with
        /// DefaultHeapBytes if nothing has.
        /// </summary>
        public static void Start(uint heapBytes)
        {
            lock (startLock)
            {
                if (started)
                {
                    return;
                }
                int status = unrar360_init(heapBytes);
                if (status != 0)
                {
                    throw new InvalidOperationException("unrar360_init failed: 0x" + status.ToString("X8"));
                }
                started = true;
            }
        }

        /// <summary>The wrapper's API version, then UnRAR's library version, a 16-bit half each.</summary>
        public static uint Version
        {
            get { return unrar360_version(); }
        }

        /// <summary>The DLL's heap in use, in bytes.</summary>
        public static uint HeapCommitted
        {
            get { return unrar360_heap_committed(); }
        }

        /// <summary>The most the DLL's heap has held at once, in bytes: what to size Start's heap by.</summary>
        public static uint HeapPeak
        {
            get { return unrar360_heap_peak(); }
        }

        /// <summary>
        /// Extracts every file of the archive into the destination folder,
        /// keeping the archive's folders and making those missing. A split
        /// archive's other volumes must be beside the first. Returns Success
        /// or one of dll.hpp's ERAR_ codes; Describe names them.
        /// </summary>
        public int Extract(string archive, string destination, string password)
        {
            Start(DefaultHeapBytes);
            Array.Clear(progress.Bytes, 0, ProgressBytes);
            // UnRAR's Unix build splits paths at '/' alone; the console takes either.
            return unrar360_extract(ToUnrarPath(archive), ToUnrarPath(destination), password, progress.Address);
        }

        /// <summary>Asks the extraction to stop at its next block of data.</summary>
        public void Cancel()
        {
            progress.SetU32(CancelOffset, 1);
        }

        /// <summary>Entries extracted so far, folders among them.</summary>
        public int FilesDone
        {
            get { return (int)progress.U32(FilesOffset); }
        }

        public long BytesDone
        {
            get { return (long)progress.U64(BytesOffset); }
        }

        /// <summary>The file being extracted, or the last.</summary>
        public string CurrentFile
        {
            get { return progress.Ansi(NameOffset, NameBytes); }
        }

        /// <summary>What went wrong, after an Extract that didn't return Success.</summary>
        public string Message
        {
            get { return progress.Ansi(MessageOffset, MessageBytes); }
        }

        public static string Describe(int code)
        {
            switch (code)
            {
                case 0: return "success";
                case 11: return "not enough memory";
                case 12: return "damaged data";
                case 13: return "damaged archive";
                case 14: return "unknown format";
                case 15: return "can't open the archive";
                case 16: return "can't create a file";
                case 17: return "can't close a file";
                case 18: return "read error";
                case 19: return "write error";
                case 20: return "buffer too small";
                case 21: return "stopped, or an unknown error";
                case 22: return "password needed";
                case 23: return "reference error";
                case 24: return "wrong password";
                case 25: return "dictionary too large";
                case 26: return "user limit";
                default: return "error " + code;
            }
        }

        public void Dispose()
        {
            progress.Dispose();
        }

        private static string ToUnrarPath(string path)
        {
            return path.Replace('\\', '/');
        }
    }
}
