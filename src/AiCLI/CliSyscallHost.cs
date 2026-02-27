using AiVM.Core;

namespace AiCLI;

internal sealed class CliSyscallHost : DefaultSyscallHost
{
    private readonly Queue<VmUiEvent> _replayEvents = new();
    private bool _replayEnabled;

    public override string[] ProcessArgv()
    {
        return Environment.GetCommandLineArgs();
    }

    public void LoadReplayEvents(string path)
    {
        _replayEvents.Clear();
        foreach (var evt in ParseEventFixture(path))
        {
            _replayEvents.Enqueue(evt);
        }
        _replayEnabled = true;
    }

    public override VmUiEvent UiPollEvent(int windowHandle)
    {
        if (_replayEnabled)
        {
            if (_replayEvents.Count == 0)
            {
                return new VmUiEvent("none", string.Empty, -1, -1, string.Empty, string.Empty, string.Empty, false);
            }

            return _replayEvents.Dequeue();
        }

        return base.UiPollEvent(windowHandle);
    }

    private static List<VmUiEvent> ParseEventFixture(string path)
    {
        var rows = CliToml.ParseArrayOfTables(path, "event");
        var events = new List<VmUiEvent>();
        foreach (var row in rows)
        {
            var type = CliToml.GetString(row, "type", "none");
            var targetId = CliToml.GetString(row, "target_id", string.Empty);
            var x = CliToml.GetInt(row, "x", -1);
            var y = CliToml.GetInt(row, "y", -1);
            var key = CliToml.GetString(row, "key", string.Empty);
            var text = CliToml.GetString(row, "text", string.Empty);
            var modifiers = CliToml.GetString(row, "modifiers", string.Empty);
            var repeat = CliToml.GetBool(row, "repeat", false);
            events.Add(new VmUiEvent(type, targetId, x, y, key, text, modifiers, repeat));
        }

        return events;
    }
}
