namespace AiLang.Core;

public sealed partial class AosInterpreter
{
    private static void AddEvalTraceStep(AosRuntime runtime, AosNode node, Dictionary<string, AosValue> env)
    {
        if (!runtime.TraceEnabled)
        {
            runtime.DebugRecorder?.RecordAstStep(node, env, runtime.CallStack);
            return;
        }

        runtime.TraceSteps.Add(new AosNode(
            "Step",
            "auto",
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["kind"] = new AosAttrValue(AosAttrKind.String, node.Kind),
                ["nodeId"] = new AosAttrValue(AosAttrKind.String, node.Id)
            },
            new List<AosNode>(),
            node.Span));

        runtime.DebugRecorder?.RecordAstStep(node, env, runtime.CallStack);
    }
}
