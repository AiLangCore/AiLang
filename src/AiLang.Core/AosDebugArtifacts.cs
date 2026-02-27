using System.Globalization;
using System.Security.Cryptography;
using System.Text;

namespace AiLang.Core;

public sealed class AosDebugRecorder
{
    private int _nextId = 1;
    private int _nextSnapshot = 1;
    private int _nextSyscall = 1;
    private int _nextEvent = 1;
    private int _nextDiag = 1;

    public string RunId { get; }
    public List<AosNode> VmTrace { get; } = new();
    public List<AosNode> StateSnapshots { get; } = new();
    public List<AosNode> Syscalls { get; } = new();
    public List<AosNode> LifecycleEvents { get; } = new();
    public List<AosNode> Diagnostics { get; } = new();

    public AosDebugRecorder(string runId)
    {
        RunId = runId;
    }

    public static string ComputeRunId(string seed)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(seed));
        return Convert.ToHexString(hash).ToLowerInvariant()[..12];
    }

    public void RecordAstStep(AosNode node, IReadOnlyDictionary<string, AosValue> env, IReadOnlyCollection<string> callStack)
    {
        var stepId = $"dbg_step_{_nextId.ToString(CultureInfo.InvariantCulture)}";
        _nextId++;
        VmTrace.Add(new AosNode(
            "Step",
            stepId,
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["vm"] = new AosAttrValue(AosAttrKind.String, "ast"),
                ["nodeId"] = new AosAttrValue(AosAttrKind.String, node.Id),
                ["op"] = new AosAttrValue(AosAttrKind.String, node.Kind),
                ["function"] = new AosAttrValue(AosAttrKind.String, callStack.Count == 0 ? string.Empty : callStack.Last()),
                ["pc"] = new AosAttrValue(AosAttrKind.Int, -1)
            },
            new List<AosNode>(),
            node.Span));

        RecordStateSnapshot("ast", node.Id, env, callStack, Array.Empty<string>(), Array.Empty<string>());
    }

    public void RecordVmStep(
        string functionName,
        int pc,
        string op,
        IReadOnlyList<string> stack,
        IReadOnlyList<string> locals,
        IReadOnlyDictionary<string, AosValue> env,
        IReadOnlyCollection<string> callStack)
    {
        var stepId = $"dbg_step_{_nextId.ToString(CultureInfo.InvariantCulture)}";
        _nextId++;
        VmTrace.Add(new AosNode(
            "Step",
            stepId,
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["vm"] = new AosAttrValue(AosAttrKind.String, "bytecode"),
                ["nodeId"] = new AosAttrValue(AosAttrKind.String, functionName),
                ["op"] = new AosAttrValue(AosAttrKind.String, op),
                ["function"] = new AosAttrValue(AosAttrKind.String, functionName),
                ["pc"] = new AosAttrValue(AosAttrKind.Int, pc)
            },
            new List<AosNode>(),
            new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0))));

        RecordStateSnapshot("bytecode", functionName, env, callStack, stack, locals);
    }

    public void RecordSyscall(string target, IReadOnlyList<string> args, string result, string phase)
    {
        var id = $"dbg_sys_{_nextSyscall.ToString(CultureInfo.InvariantCulture)}";
        _nextSyscall++;
        var children = new List<AosNode>(args.Count);
        for (var i = 0; i < args.Count; i++)
        {
            children.Add(new AosNode(
                "Arg",
                $"{id}_arg_{i.ToString(CultureInfo.InvariantCulture)}",
                new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
                {
                    ["value"] = new AosAttrValue(AosAttrKind.String, args[i])
                },
                new List<AosNode>(),
                new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0))));
        }

        Syscalls.Add(new AosNode(
            "Syscall",
            id,
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["target"] = new AosAttrValue(AosAttrKind.String, target),
                ["result"] = new AosAttrValue(AosAttrKind.String, result),
                ["phase"] = new AosAttrValue(AosAttrKind.String, phase)
            },
            children,
            new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0))));
    }

    public void RecordEvent(string kind, string payload)
    {
        var id = $"dbg_evt_{_nextEvent.ToString(CultureInfo.InvariantCulture)}";
        _nextEvent++;
        LifecycleEvents.Add(new AosNode(
            "Event",
            id,
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["kind"] = new AosAttrValue(AosAttrKind.String, kind),
                ["payload"] = new AosAttrValue(AosAttrKind.String, payload)
            },
            new List<AosNode>(),
            new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0))));
    }

    public void RecordDiagnostic(string code, string message, string nodeId)
    {
        var id = $"dbg_diag_{_nextDiag.ToString(CultureInfo.InvariantCulture)}";
        _nextDiag++;
        Diagnostics.Add(new AosNode(
            "Diagnostic",
            id,
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["code"] = new AosAttrValue(AosAttrKind.String, code),
                ["message"] = new AosAttrValue(AosAttrKind.String, message),
                ["nodeId"] = new AosAttrValue(AosAttrKind.String, nodeId)
            },
            new List<AosNode>(),
            new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0))));
    }

    public static AosNode BuildListNode(string kind, string id, IReadOnlyList<AosNode> children)
    {
        return new AosNode(
            kind,
            id,
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal),
            new List<AosNode>(children),
            new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)));
    }

    private void RecordStateSnapshot(
        string vm,
        string stepNodeId,
        IReadOnlyDictionary<string, AosValue> env,
        IReadOnlyCollection<string> callStack,
        IReadOnlyList<string> stack,
        IReadOnlyList<string> locals)
    {
        var id = $"dbg_snap_{_nextSnapshot.ToString(CultureInfo.InvariantCulture)}";
        _nextSnapshot++;
        var children = new List<AosNode>
        {
            BuildStringList("env", $"{id}_env", env
                .OrderBy(kv => kv.Key, StringComparer.Ordinal)
                .Select(kv => $"{kv.Key}={FormatValue(kv.Value)}")
                .ToList()),
            BuildStringList("callStack", $"{id}_call", callStack.ToList()),
            BuildStringList("stack", $"{id}_stack", stack.ToList()),
            BuildStringList("locals", $"{id}_locals", locals.ToList())
        };

        StateSnapshots.Add(new AosNode(
            "Snapshot",
            id,
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["vm"] = new AosAttrValue(AosAttrKind.String, vm),
                ["stepNodeId"] = new AosAttrValue(AosAttrKind.String, stepNodeId)
            },
            children,
            new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0))));
    }

    private static AosNode BuildStringList(string kind, string id, IReadOnlyList<string> values)
    {
        var children = new List<AosNode>(values.Count);
        for (var i = 0; i < values.Count; i++)
        {
            children.Add(new AosNode(
                "Item",
                $"{id}_item_{i.ToString(CultureInfo.InvariantCulture)}",
                new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
                {
                    ["value"] = new AosAttrValue(AosAttrKind.String, values[i])
                },
                new List<AosNode>(),
                new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0))));
        }

        return new AosNode(
            kind,
            id,
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal),
            children,
            new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)));
    }

    private static string FormatValue(AosValue value)
    {
        return value.Kind switch
        {
            AosValueKind.String => "\"" + Escape(value.AsString()) + "\"",
            AosValueKind.Int => value.AsInt().ToString(CultureInfo.InvariantCulture),
            AosValueKind.Bool => value.AsBool() ? "true" : "false",
            AosValueKind.Void => "void",
            AosValueKind.Node => value.AsNode().Kind + "#" + value.AsNode().Id,
            AosValueKind.Function => "fn",
            _ => "unknown"
        };
    }

    private static string Escape(string text) =>
        text
            .Replace("\\", "\\\\", StringComparison.Ordinal)
            .Replace("\"", "\\\"", StringComparison.Ordinal)
            .Replace("\n", "\\n", StringComparison.Ordinal)
            .Replace("\r", "\\r", StringComparison.Ordinal)
            .Replace("\t", "\\t", StringComparison.Ordinal);
}
