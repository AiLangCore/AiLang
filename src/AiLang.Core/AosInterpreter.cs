namespace AiLang.Core;

public sealed class AosRuntime
{
    public Dictionary<string, AosValue> Env { get; } = new(StringComparer.Ordinal);
    public HashSet<string> Permissions { get; } = new(StringComparer.Ordinal) { "math" };
    public AosNode? Program { get; set; }
}

public sealed class AosInterpreter
{
    public AosValue EvaluateProgram(AosNode program, AosRuntime runtime)
    {
        return Evaluate(program, runtime, isExpression: false);
    }

    public AosValue EvaluateExpression(AosNode expr, AosRuntime runtime)
    {
        return Evaluate(expr, runtime, isExpression: true);
    }

    private AosValue Evaluate(AosNode node, AosRuntime runtime, bool isExpression)
    {
        try
        {
            return EvalNode(node, runtime);
        }
        catch (ReturnSignal signal)
        {
            return signal.Value;
        }
    }

    private AosValue EvalNode(AosNode node, AosRuntime runtime)
    {
        switch (node.Kind)
        {
            case "Program":
                AosValue last = AosValue.Void;
                foreach (var child in node.Children)
                {
                    last = EvalNode(child, runtime);
                }
                return last;
            case "Let":
                if (!node.Attrs.TryGetValue("name", out var nameAttr) || nameAttr.Kind != AosAttrKind.Identifier)
                {
                    return AosValue.Unknown;
                }
                if (node.Children.Count != 1)
                {
                    return AosValue.Unknown;
                }
                var value = EvalNode(node.Children[0], runtime);
                runtime.Env[nameAttr.AsString()] = value;
                return AosValue.Void;
            case "Var":
                if (!node.Attrs.TryGetValue("name", out var varAttr) || varAttr.Kind != AosAttrKind.Identifier)
                {
                    return AosValue.Unknown;
                }
                return runtime.Env.TryGetValue(varAttr.AsString(), out var bound) ? bound : AosValue.Unknown;
            case "Lit":
                if (!node.Attrs.TryGetValue("value", out var litAttr))
                {
                    return AosValue.Unknown;
                }
                return litAttr.Kind switch
                {
                    AosAttrKind.String => AosValue.FromString(litAttr.AsString()),
                    AosAttrKind.Int => AosValue.FromInt(litAttr.AsInt()),
                    AosAttrKind.Bool => AosValue.FromBool(litAttr.AsBool()),
                    _ => AosValue.Unknown
                };
            case "Call":
                return EvalCall(node, runtime);
            case "If":
                if (node.Children.Count < 2)
                {
                    return AosValue.Unknown;
                }
                var cond = EvalNode(node.Children[0], runtime);
                var condValue = cond.Kind == AosValueKind.Bool && cond.AsBool();
                if (cond.Kind != AosValueKind.Bool)
                {
                    return AosValue.Unknown;
                }
                if (condValue)
                {
                    return EvalNode(node.Children[1], runtime);
                }
                if (node.Children.Count >= 3)
                {
                    return EvalNode(node.Children[2], runtime);
                }
                return AosValue.Void;
            case "Block":
                AosValue result = AosValue.Void;
                foreach (var child in node.Children)
                {
                    result = EvalNode(child, runtime);
                }
                return result;
            case "Return":
                if (node.Children.Count == 1)
                {
                    throw new ReturnSignal(EvalNode(node.Children[0], runtime));
                }
                throw new ReturnSignal(AosValue.Void);
            default:
                return AosValue.Unknown;
        }
    }

    private AosValue EvalCall(AosNode node, AosRuntime runtime)
    {
        if (!node.Attrs.TryGetValue("target", out var targetAttr) || targetAttr.Kind != AosAttrKind.Identifier)
        {
            return AosValue.Unknown;
        }

        var target = targetAttr.AsString();
        if (target == "math.add")
        {
            if (!runtime.Permissions.Contains("math"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 2)
            {
                return AosValue.Unknown;
            }
            var left = EvalNode(node.Children[0], runtime);
            var right = EvalNode(node.Children[1], runtime);
            if (left.Kind != AosValueKind.Int || right.Kind != AosValueKind.Int)
            {
                return AosValue.Unknown;
            }
            return AosValue.FromInt(left.AsInt() + right.AsInt());
        }

        if (target == "console.print")
        {
            if (!runtime.Permissions.Contains("console"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 1)
            {
                return AosValue.Unknown;
            }
            var arg = EvalNode(node.Children[0], runtime);
            if (arg.Kind != AosValueKind.String)
            {
                return AosValue.Unknown;
            }
            Console.WriteLine(arg.AsString());
            return AosValue.Void;
        }

        return AosValue.Unknown;
    }

    private sealed class ReturnSignal : Exception
    {
        public ReturnSignal(AosValue value)
        {
            Value = value;
        }

        public AosValue Value { get; }
    }
}
