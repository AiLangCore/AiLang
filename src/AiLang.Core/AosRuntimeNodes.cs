namespace AiLang.Core;

public static class AosRuntimeNodes
{
    private static readonly AosSpan ZeroSpan = new(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0));

    public static AosNode BuildArgvNode(string[] values)
    {
        return BuildStringListNode("argv", "argv", values);
    }

    public static AosNode BuildStringListNode(string rootId, string childIdPrefix, string[] values)
    {
        var children = new List<AosNode>(values.Length);
        for (var i = 0; i < values.Length; i++)
        {
            children.Add(new AosNode(
                "Lit",
                $"{childIdPrefix}{i}",
                new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
                {
                    ["value"] = new AosAttrValue(AosAttrKind.String, values[i])
                },
                new List<AosNode>(),
                ZeroSpan));
        }

        return new AosNode(
            "Block",
            rootId,
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal),
            children,
            ZeroSpan);
    }

    public static AosNode BuildFsStatNode(string type, int size, int mtimeUnixMs)
    {
        return new AosNode(
            "Stat",
            "stat",
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["type"] = new AosAttrValue(AosAttrKind.String, type),
                ["size"] = new AosAttrValue(AosAttrKind.Int, size),
                ["mtime"] = new AosAttrValue(AosAttrKind.Int, mtimeUnixMs)
            },
            new List<AosNode>(),
            ZeroSpan);
    }

    public static AosNode BuildUdpPacketNode(string host, int port, string data)
    {
        return new AosNode(
            "UdpPacket",
            "udpPacket",
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["host"] = new AosAttrValue(AosAttrKind.String, host),
                ["port"] = new AosAttrValue(AosAttrKind.Int, port),
                ["data"] = new AosAttrValue(AosAttrKind.String, data)
            },
            new List<AosNode>(),
            ZeroSpan);
    }

    public static AosNode BuildUiEventNode(
        string type,
        string targetId,
        int x,
        int y,
        string key,
        string text,
        string modifiers,
        bool repeat)
    {
        return new AosNode(
            "UiEvent",
            "uiEvent",
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["type"] = new AosAttrValue(AosAttrKind.String, type),
                ["targetId"] = new AosAttrValue(AosAttrKind.String, targetId),
                ["x"] = new AosAttrValue(AosAttrKind.Int, x),
                ["y"] = new AosAttrValue(AosAttrKind.Int, y),
                ["key"] = new AosAttrValue(AosAttrKind.String, key),
                ["text"] = new AosAttrValue(AosAttrKind.String, text),
                ["modifiers"] = new AosAttrValue(AosAttrKind.String, modifiers),
                ["repeat"] = new AosAttrValue(AosAttrKind.Bool, repeat)
            },
            new List<AosNode>(),
            ZeroSpan);
    }

    public static AosNode BuildUiWindowSizeNode(int width, int height)
    {
        return new AosNode(
            "UiWindowSize",
            "uiWindowSize",
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["width"] = new AosAttrValue(AosAttrKind.Int, width),
                ["height"] = new AosAttrValue(AosAttrKind.Int, height)
            },
            new List<AosNode>(),
            ZeroSpan);
    }
}
