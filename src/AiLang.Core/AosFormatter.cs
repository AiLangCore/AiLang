namespace AiLang.Core;

public static class AosFormatter
{
    private static readonly Lazy<AosNode> FormatterProgram = new(LoadFormatterProgram);

    public static string Format(AosNode node)
    {
        var program = FormatterProgram.Value;
        var runtime = new AosRuntime();
        runtime.Permissions.Clear();

        var validator = new AosValidator();
        var validation = validator.Validate(program, null, runtime.Permissions, runStructural: false);
        if (validation.Diagnostics.Count > 0)
        {
            throw new InvalidOperationException($"Formatter validation failed: {validation.Diagnostics[0].Message}");
        }

        var interpreter = new AosInterpreter();
        interpreter.EvaluateProgram(program, runtime);

        runtime.Env["__input"] = AosValue.FromNode(node);
        var callNode = new AosNode(
            "Call",
            "format_call",
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["target"] = new AosAttrValue(AosAttrKind.Identifier, "format")
            },
            new List<AosNode>
            {
                new(
                    "Var",
                    "format_input",
                    new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
                    {
                        ["name"] = new AosAttrValue(AosAttrKind.Identifier, "__input")
                    },
                    new List<AosNode>(),
                    new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)))
            },
            new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)));

        var result = interpreter.EvaluateExpression(callNode, runtime);
        if (result.Kind != AosValueKind.String)
        {
            throw new InvalidOperationException("Formatter did not return a string.");
        }
        return result.AsString();
    }

    private static AosNode LoadFormatterProgram()
    {
        return AosCompilerAssets.LoadRequiredProgram("format.aos");
    }
}
