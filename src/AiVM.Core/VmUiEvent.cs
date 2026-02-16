namespace AiVM.Core;

public readonly record struct VmUiEvent(
    string Type,
    string TargetId,
    int X,
    int Y,
    string Key,
    string Text,
    string Modifiers,
    bool Repeat)
{
    // Backward-compatible constructor for older call sites that only provided a generic detail payload.
    public VmUiEvent(string type, string detail, int x, int y)
        : this(
            type,
            string.Empty,
            x,
            y,
            string.Equals(type, "key", StringComparison.Ordinal) ? detail : string.Empty,
            string.Empty,
            string.Empty,
            false)
    {
    }
}
