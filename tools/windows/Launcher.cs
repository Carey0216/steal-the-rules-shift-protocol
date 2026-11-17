using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

internal static class Launcher
{
    private const uint SpiGetStickyKeys = 0x003A;
    private const uint SpiSetStickyKeys = 0x003B;
    private const uint StickyKeysOn = 0x00000001;
    private const uint HotkeyActive = 0x00000004;

    [StructLayout(LayoutKind.Sequential)]
    private struct StickyKeys
    {
        internal uint Size;
        internal uint Flags;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool SystemParametersInfo(uint action, uint size, ref StickyKeys data, uint flags);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);

    [DllImport("kernel32.dll")]
    private static extern ulong GetTickCount64();

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int MessageBox(IntPtr window, string text, string caption, uint type);

    [STAThread]
    private static int Main(string[] args)
    {
        bool ownsInstance;
        using (var instance = new Mutex(true, @"Local\ShiftProtocol.Launcher", out ownsInstance))
        {
            if (!ownsInstance)
                return 0;
            try
            {
                using (var shortcut = new StickyHotkeyScope())
                using (var game = OpenGame(args))
                {
                    while (!game.WaitForExit(24))
                    {
                        uint foregroundProcess;
                        GetWindowThreadProcessId(GetForegroundWindow(), out foregroundProcess);
                        shortcut.SetForeground(foregroundProcess == (uint)game.Id);
                    }
                    return game.ExitCode;
                }
            }
            catch (Exception error)
            {
                MessageBox(IntPtr.Zero, error.Message, "SHIFT PROTOCOL", 0x10);
                return 1;
            }
            finally
            {
                instance.ReleaseMutex();
            }
        }
    }

    private static Process OpenGame(string[] args)
    {
        string runtime = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "runtime");
        string executable = Path.Combine(runtime, "ShiftProtocolGame.exe");
        if (!File.Exists(executable) || !File.Exists(Path.Combine(runtime, "ShiftProtocolGame.pck")))
            throw new FileNotFoundException("Extract the complete ZIP before opening ShiftProtocol.exe.");
        return Process.Start(new ProcessStartInfo(executable, JoinArguments(args))
        {
            WorkingDirectory = runtime,
            UseShellExecute = false
        });
    }

    private static string JoinArguments(string[] args)
    {
        var command = new StringBuilder();
        foreach (string argument in args)
        {
            if (command.Length != 0)
                command.Append(' ');
            command.Append('"');
            int slashes = 0;
            foreach (char character in argument)
            {
                if (character == '\\')
                {
                    slashes++;
                    continue;
                }
                if (character == '"')
                    command.Append('\\', slashes + 1);
                command.Append('\\', slashes);
                slashes = 0;
                command.Append(character);
            }
            command.Append('\\', slashes * 2);
            command.Append('"');
        }
        return command.ToString();
    }

    private sealed class StickyHotkeyScope : IDisposable
    {
        private readonly string recovery;
        private readonly long bootTime;
        private bool suppressed;

        internal StickyHotkeyScope()
        {
            bootTime = DateTime.UtcNow.Ticks - (long)GetTickCount64() * TimeSpan.TicksPerMillisecond;
            string folder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "ShiftProtocol");
            int session = Process.GetCurrentProcess().SessionId;
            recovery = Path.Combine(folder, "sticky-shortcut-" + session + ".recovery");
            RecoverInterruptedSession();
        }

        internal void SetForeground(bool foreground)
        {
            if (!foreground)
            {
                Restore();
                return;
            }
            if (suppressed)
                return;
            StickyKeys state;
            if (!Read(out state) || (state.Flags & (StickyKeysOn | HotkeyActive)) != HotkeyActive)
                return;
            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(recovery));
                File.WriteAllText(recovery, bootTime.ToString(CultureInfo.InvariantCulture));
            }
            catch (IOException)
            {
                return;
            }
            catch (UnauthorizedAccessException)
            {
                return;
            }
            state.Flags &= ~HotkeyActive;
            suppressed = Write(state);
            if (!suppressed)
                ForgetRecovery();
        }

        public void Dispose()
        {
            // The launcher remains alive if the game crashes or is terminated.
            Restore();
        }

        private void RecoverInterruptedSession()
        {
            if (!File.Exists(recovery))
                return;
            try
            {
                long recordedBoot;
                if (long.TryParse(File.ReadAllText(recovery), NumberStyles.Integer, CultureInfo.InvariantCulture, out recordedBoot)
                    && Math.Abs((double)recordedBoot - bootTime) < TimeSpan.FromSeconds(10).Ticks)
                {
                    suppressed = true;
                    Restore();
                }
                else
                    ForgetRecovery();
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }

        private void Restore()
        {
            if (!suppressed)
                return;
            StickyKeys state;
            if (!Read(out state))
                return;
            if ((state.Flags & HotkeyActive) == 0)
            {
                state.Flags |= HotkeyActive;
                if (!Write(state))
                    return;
            }
            suppressed = false;
            ForgetRecovery();
        }

        private void ForgetRecovery()
        {
            try { File.Delete(recovery); }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }

        private static bool Read(out StickyKeys state)
        {
            state = new StickyKeys { Size = (uint)Marshal.SizeOf(typeof(StickyKeys)) };
            return SystemParametersInfo(SpiGetStickyKeys, state.Size, ref state, 0);
        }

        private static bool Write(StickyKeys state)
        {
            // Do not persist the temporary change or modify any other accessibility flag.
            return SystemParametersInfo(SpiSetStickyKeys, state.Size, ref state, 0);
        }
    }
}
