namespace AiLang.Core;

public enum AosValueKind
{
    String,
    Int,
    Bool,
    Void,
    Node,
    Function,
    Unknown
}

public sealed record AosValue(AosValueKind Kind, object? Data)
{
    public static readonly AosValue Void = new(AosValueKind.Void, null);
    public static readonly AosValue Unknown = new(AosValueKind.Unknown, null);
    public static readonly AosValue NullNode = new(AosValueKind.Node, null);

    public static AosValue FromString(string value) => new(AosValueKind.String, value);
    public static AosValue FromInt(int value) => new(AosValueKind.Int, value);
    public static AosValue FromBool(bool value) => new(AosValueKind.Bool, value);
    public static AosValue FromNode(AosNode node) => new(AosValueKind.Node, node);
    public static AosValue FromFunction(AosFunction function) => new(AosValueKind.Function, function);

    public string AsString() => (string)Data!;
    public int AsInt() => (int)Data!;
    public bool AsBool() => (bool)Data!;
    public AosNode AsNode() => (AosNode)Data!;
    public AosFunction AsFunction() => (AosFunction)Data!;
}

public enum AosAttrKind
{
    String,
    Int,
    Bool,
    Identifier
}

public sealed record AosAttrValue(AosAttrKind Kind, object Value)
{
    public string AsString() => (string)Value;
    public int AsInt() => (int)Value;
    public bool AsBool() => (bool)Value;
}

public readonly struct AosPosition
{
    public AosPosition(int index, int line, int column)
    {
        Index = index;
        Line = line;
        Column = column;
    }

    public int Index { get; }
    public int Line { get; }
    public int Column { get; }
}

public readonly struct AosSpan
{
    public AosSpan(AosPosition start, AosPosition end)
    {
        Start = start;
        End = end;
    }

    public AosPosition Start { get; }
    public AosPosition End { get; }
}

public sealed class AosNode
{
    public AosNode(string kind, string id, Dictionary<string, AosAttrValue> attrs, List<AosNode> children, AosSpan span)
    {
        Kind = kind;
        Id = id;
        Attrs = attrs;
        Children = children;
        Span = span;
    }

    public string Kind { get; }
    public string Id { get; }
    public Dictionary<string, AosAttrValue> Attrs { get; }
    public List<AosNode> Children { get; }
    public AosSpan Span { get; }
}

public sealed record AosDiagnostic(string Code, string Message, string? NodeId, AosSpan? Span);

public sealed class AosFunction
{
    public AosFunction(List<string> parameters, AosNode body, Dictionary<string, AosValue> capturedEnv)
    {
        Parameters = parameters;
        Body = body;
        CapturedEnv = capturedEnv;
    }

    public List<string> Parameters { get; }
    public AosNode Body { get; }
    public Dictionary<string, AosValue> CapturedEnv { get; }
}
