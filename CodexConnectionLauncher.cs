using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows.Forms;

internal static class CodexConnectionLauncher
{
    [STAThread]
    private static int Main(string[] args)
    {
        var executableName = Path.GetFileNameWithoutExtension(Application.ExecutablePath) ?? string.Empty;
        var restartRequested = args.Any(arg => string.Equals(arg, "--restart", StringComparison.OrdinalIgnoreCase))
            || executableName.IndexOf("restart", StringComparison.OrdinalIgnoreCase) >= 0
            || executableName.IndexOf("\u91cd\u542f", StringComparison.Ordinal) >= 0;
        var installRoot = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CodexConnection");
        var scriptName = restartRequested ? "Restart-CodexConnection.ps1" : "Start-CodexScopedProxy.ps1";
        var scriptPath = Path.Combine(installRoot, scriptName);
        var logPath = Path.Combine(installRoot, "logs", restartRequested ? "restart.log" : "launcher.log");

        if (!File.Exists(scriptPath))
        {
            ShowFailure("Codex Connection is not installed or was removed. Run the setup program again.");
            return 1;
        }

        try
        {
            var powerShellPath = Path.Combine(Environment.SystemDirectory, "WindowsPowerShell", "v1.0", "powershell.exe");
            var startInfo = new ProcessStartInfo
            {
                FileName = powerShellPath,
                Arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + scriptPath + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                WorkingDirectory = installRoot
            };
            using (var process = Process.Start(startInfo))
            {
                process.WaitForExit();
                if (process.ExitCode != 0)
                {
                    ShowFailure("Codex Connection could not complete. See the local log:\n" + logPath);
                    return process.ExitCode;
                }
            }
            return 0;
        }
        catch (Exception error)
        {
            ShowFailure("Codex Connection could not start.\n" + error.Message + "\n\nLog: " + logPath);
            return 1;
        }
    }

    private static void ShowFailure(string message)
    {
        MessageBox.Show(message, "Codex Connection", MessageBoxButtons.OK, MessageBoxIcon.Error);
    }
}
