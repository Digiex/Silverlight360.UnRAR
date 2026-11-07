using System;
using System.Collections.Generic;
using System.Threading;
using System.Windows.Controls;
using System.Windows.Threading;
using Silverlight360;
using Silverlight360.UnRAR;

namespace UnRarSample
{
    /// <summary>
    /// Extracts each archive in hdd:\Content\UnRarTest\in into a folder of its
    /// own in hdd:\Content\UnRarTest\out, and checks what each returns. Under
    /// xenia-edge, hdd:\Content is the --content_root folder;
    /// tests\make_archives.ps1 makes the archives and tests\verify_output.py
    /// checks the files that come out.
    /// </summary>
    public partial class MainPage : UserControl
    {
        private const string In = @"hdd:\Content\UnRarTest\in\";
        private const string Out = @"hdd:\Content\UnRarTest\out\";

        private sealed class Case
        {
            public string Archive;
            public string Password;
            public int Expected;
            public long CancelAfterBytes;
        }

        private readonly List<Case> cases = new List<Case>
        {
            new Case { Archive = "rar5.rar" },
            new Case { Archive = "rar4.rar" },
            new Case { Archive = "store.rar" },
            new Case { Archive = "solid.rar" },
            new Case { Archive = "password.rar", Password = "xbox360" },
            new Case { Archive = "split.part1.rar" },
            new Case { Archive = "missing.rar", Expected = 15 },
            new Case { Archive = "password.rar", Password = "wrong", Expected = RarExtractor.BadPassword },
            new Case { Archive = "large.rar", CancelAfterBytes = 16 << 20, Expected = -1 },
            new Case { Archive = "large.rar" },
        };

        private readonly RarExtractor extractor = new RarExtractor();
        private readonly DispatcherTimer timer = new DispatcherTimer();
        private int passed;
        private int failed;

        public MainPage()
        {
            InitializeComponent();
            timer.Interval = TimeSpan.FromMilliseconds(500);
            timer.Tick += delegate
            {
                ProgressText.Text = extractor.FilesDone + " files, " + (extractor.BytesDone >> 10) + " KB: " +
                    extractor.CurrentFile;
            };
            Loaded += delegate
            {
                timer.Start();
                new Thread(RunCases).Start();
            };
        }

        private void RunCases()
        {
            try
            {
                RarExtractor.Start(RarExtractor.DefaultHeapBytes);
                Report("Silverlight360.UnRAR: version 0x" + RarExtractor.Version.ToString("X8"));
            }
            catch (Exception e)
            {
                Report("FAIL: start -> " + e.Message);
                return;
            }
            for (int i = 0; i < cases.Count; i++)
            {
                Run(i, cases[i]);
            }
            Report("Silverlight360.UnRAR: checks: " + passed + " passed, " + failed + " failed");
        }

        private void Run(int index, Case test)
        {
            string name = test.Archive + (test.Password != null ? " (password " + test.Password + ")" : "") +
                (test.CancelAfterBytes > 0 ? " (cancelled after " + (test.CancelAfterBytes >> 20) + " MB)" : "");
            string destination = Out + index + "-" + test.Archive.Replace(".rar", "");
            DebugLog.WriteLine("Silverlight360.UnRAR: " + name + "...");
            Timer cancel = null;
            if (test.CancelAfterBytes > 0)
            {
                // Watches from another thread, as an app's Cancel button would.
                cancel = new Timer(delegate
                {
                    if (extractor.BytesDone >= test.CancelAfterBytes)
                    {
                        extractor.Cancel();
                    }
                }, null, TimeSpan.Zero, TimeSpan.FromMilliseconds(5));
            }
            int start = Environment.TickCount;
            int result = extractor.Extract(In + test.Archive, destination, test.Password);
            int milliseconds = Environment.TickCount - start;
            if (cancel != null)
            {
                cancel.Dispose();
            }
            // A cancelled extraction's code is UnRAR's; any but success will do.
            bool ok = test.Expected == -1 ? result != RarExtractor.Success : result == test.Expected;
            string line = name + " -> " + RarExtractor.Describe(result) + ", " + extractor.FilesDone + " entries, " +
                extractor.BytesDone + " bytes in " + milliseconds + " ms, heap peak " +
                (RarExtractor.HeapPeak >> 10) + " KB" +
                (result != RarExtractor.Success ? " (" + extractor.Message + ")" : "");
            if (ok)
            {
                passed++;
                Report("PASS: " + line);
            }
            else
            {
                failed++;
                Report("FAIL: " + line);
            }
        }

        private void Report(string line)
        {
            DebugLog.WriteLine(line);
            Dispatcher.BeginInvoke(delegate { ResultsText.Text += line + "\n"; });
        }

        public void ShowError(Exception error)
        {
            Report("Unhandled: " + error.GetType().Name + ": " + error.Message);
        }
    }
}
