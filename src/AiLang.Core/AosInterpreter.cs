namespace AiLang.Core;

public sealed class AosRuntime
{
    public Dictionary<string, AosValue> Env { get; } = new(StringComparer.Ordinal);
    public HashSet<string> Permissions { get; } = new(StringComparer.Ordinal) { "math" };
    public HashSet<string> ReadOnlyBindings { get; } = new(StringComparer.Ordinal);
    public AosNode? Program { get; set; }
}

public sealed class AosInterpreter
{
    private bool _strictUnknown;
    private int _evalDepth;
    private const int MaxEvalDepth = 4096;

    public AosValue EvaluateProgram(AosNode program, AosRuntime runtime)
    {
        _strictUnknown = false;
        return Evaluate(program, runtime, runtime.Env);
    }

    public AosValue EvaluateExpression(AosNode expr, AosRuntime runtime)
    {
        _strictUnknown = false;
        return Evaluate(expr, runtime, runtime.Env);
    }

    public AosValue EvaluateExpressionStrict(AosNode expr, AosRuntime runtime)
    {
        _strictUnknown = true;
        return Evaluate(expr, runtime, runtime.Env);
    }

    private AosValue Evaluate(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        try
        {
            return EvalNode(node, runtime, env);
        }
        catch (ReturnSignal signal)
        {
            return signal.Value;
        }
    }

    private AosValue EvalNode(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        _evalDepth++;
        if (_evalDepth > MaxEvalDepth)
        {
            throw new InvalidOperationException($"Evaluation depth exceeded at {node.Kind}#{node.Id}.");
        }

        try
        {
            var value = EvalCore(node, runtime, env);

            if (_strictUnknown && value.Kind == AosValueKind.Unknown)
            {
                throw new InvalidOperationException($"Unknown value from node {node.Kind}#{node.Id}.");
            }

            return value;
        }
        finally
        {
            _evalDepth--;
        }
    }

    private AosValue EvalCore(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        switch (node.Kind)
        {
            case "Program":
                AosValue last = AosValue.Void;
                foreach (var child in node.Children)
                {
                    last = EvalNode(child, runtime, env);
                }
                return last;
            case "Let":
                if (!node.Attrs.TryGetValue("name", out var nameAttr) || nameAttr.Kind != AosAttrKind.Identifier)
                {
                    return AosValue.Unknown;
                }
                var name = nameAttr.AsString();
                if (runtime.ReadOnlyBindings.Contains(name))
                {
                    throw new InvalidOperationException($"Cannot assign read-only binding '{name}'.");
                }
                if (node.Children.Count != 1)
                {
                    return AosValue.Unknown;
                }
                var value = EvalNode(node.Children[0], runtime, env);
                env[name] = value;
                return AosValue.Void;
            case "Var":
                if (!node.Attrs.TryGetValue("name", out var varAttr) || varAttr.Kind != AosAttrKind.Identifier)
                {
                    return AosValue.Unknown;
                }
                return env.TryGetValue(varAttr.AsString(), out var bound) ? bound : AosValue.Unknown;
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
                return EvalCall(node, runtime, env);
            case "Fn":
                return EvalFunction(node, runtime, env);
            case "Eq":
                return EvalEq(node, runtime, env);
            case "Add":
                return EvalAdd(node, runtime, env);
            case "ToString":
                return EvalToString(node, runtime, env);
            case "StrConcat":
                return EvalStrConcat(node, runtime, env);
            case "StrEscape":
                return EvalStrEscape(node, runtime, env);
            case "MakeBlock":
                return EvalMakeBlock(node, runtime, env);
            case "AppendChild":
                return EvalAppendChild(node, runtime, env);
            case "MakeErr":
                return EvalMakeErr(node, runtime, env);
            case "MakeLitString":
                return EvalMakeLitString(node, runtime, env);
            case "NodeKind":
                return EvalNodeKind(node, runtime, env);
            case "NodeId":
                return EvalNodeId(node, runtime, env);
            case "AttrCount":
                return EvalAttrCount(node, runtime, env);
            case "AttrKey":
                return EvalAttrKey(node, runtime, env);
            case "AttrValueKind":
                return EvalAttrValueKind(node, runtime, env);
            case "AttrValueString":
                return EvalAttrValueString(node, runtime, env);
            case "AttrValueInt":
                return EvalAttrValueInt(node, runtime, env);
            case "AttrValueBool":
                return EvalAttrValueBool(node, runtime, env);
            case "ChildCount":
                return EvalChildCount(node, runtime, env);
            case "ChildAt":
                return EvalChildAt(node, runtime, env);
            case "If":
                if (node.Children.Count < 2)
                {
                    return AosValue.Unknown;
                }
                var cond = EvalNode(node.Children[0], runtime, env);
                var condValue = cond.Kind == AosValueKind.Bool && cond.AsBool();
                if (cond.Kind != AosValueKind.Bool)
                {
                    return AosValue.Unknown;
                }
                if (condValue)
                {
                    return EvalNode(node.Children[1], runtime, env);
                }
                if (node.Children.Count >= 3)
                {
                    return EvalNode(node.Children[2], runtime, env);
                }
                return AosValue.Void;
            case "Block":
                AosValue result = AosValue.Void;
                foreach (var child in node.Children)
                {
                    result = EvalNode(child, runtime, env);
                }
                return result;
            case "Return":
                if (node.Children.Count == 1)
                {
                    throw new ReturnSignal(EvalNode(node.Children[0], runtime, env));
                }
                throw new ReturnSignal(AosValue.Void);
            default:
                return AosValue.Unknown;
        }
    }

    private AosValue EvalCall(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
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
            var left = EvalNode(node.Children[0], runtime, env);
            var right = EvalNode(node.Children[1], runtime, env);
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
            var arg = EvalNode(node.Children[0], runtime, env);
            if (arg.Kind != AosValueKind.String)
            {
                return AosValue.Unknown;
            }
            Console.WriteLine(arg.AsString());
            return AosValue.Void;
        }

        if (target == "io.print")
        {
            if (!runtime.Permissions.Contains("io"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 1)
            {
                return AosValue.Unknown;
            }

            var value = EvalNode(node.Children[0], runtime, env);
            if (value.Kind == AosValueKind.Unknown)
            {
                return AosValue.Unknown;
            }

            Console.WriteLine(ValueToDisplayString(value));
            return AosValue.Void;
        }

        if (target == "io.write")
        {
            if (!runtime.Permissions.Contains("io"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 1)
            {
                return AosValue.Unknown;
            }

            var value = EvalNode(node.Children[0], runtime, env);
            if (value.Kind != AosValueKind.String)
            {
                return AosValue.Unknown;
            }

            Console.Write(value.AsString());
            return AosValue.Void;
        }

        if (target == "io.readLine")
        {
            if (!runtime.Permissions.Contains("io"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 0)
            {
                return AosValue.Unknown;
            }

            var line = Console.ReadLine();
            return AosValue.FromString(line ?? string.Empty);
        }

        if (target == "io.readAllStdin")
        {
            if (!runtime.Permissions.Contains("io"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 0)
            {
                return AosValue.Unknown;
            }

            return AosValue.FromString(Console.In.ReadToEnd());
        }

        if (target == "io.readFile")
        {
            if (!runtime.Permissions.Contains("io"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 1)
            {
                return AosValue.Unknown;
            }

            var pathValue = EvalNode(node.Children[0], runtime, env);
            if (pathValue.Kind != AosValueKind.String)
            {
                return AosValue.Unknown;
            }

            return AosValue.FromString(File.ReadAllText(pathValue.AsString()));
        }

        if (target == "io.fileExists")
        {
            if (!runtime.Permissions.Contains("io"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 1)
            {
                return AosValue.Unknown;
            }

            var pathValue = EvalNode(node.Children[0], runtime, env);
            if (pathValue.Kind != AosValueKind.String)
            {
                return AosValue.Unknown;
            }

            return AosValue.FromBool(File.Exists(pathValue.AsString()));
        }

        if (target == "compiler.parse")
        {
            if (!runtime.Permissions.Contains("compiler"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 1)
            {
                return AosValue.Unknown;
            }

            var text = EvalNode(node.Children[0], runtime, env);
            if (text.Kind != AosValueKind.String)
            {
                return AosValue.Unknown;
            }

            var tokenizer = new AosTokenizer(text.AsString());
            var tokens = tokenizer.Tokenize();
            var parser = new AosParser(tokens);
            var parse = parser.ParseSingle();
            parse.Diagnostics.AddRange(tokenizer.Diagnostics);

            if (parse.Root is not null && parse.Diagnostics.Count == 0 && parse.Root.Kind == "Program")
            {
                return AosValue.FromNode(parse.Root);
            }

            var diagnostic = parse.Diagnostics.FirstOrDefault();
            if (diagnostic is null && parse.Root is not null && parse.Root.Kind != "Program")
            {
                diagnostic = new AosDiagnostic("PAR001", "Expected Program root.", parse.Root.Id, parse.Root.Span);
            }
            diagnostic ??= new AosDiagnostic("PAR000", "Parse failed.", "unknown", null);
            return AosValue.FromNode(CreateErrNode("parse_err", diagnostic.Code, diagnostic.Message, diagnostic.NodeId ?? "unknown", node.Span));
        }

        if (target == "compiler.format")
        {
            if (!runtime.Permissions.Contains("compiler"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 1)
            {
                return AosValue.Unknown;
            }

            var input = EvalNode(node.Children[0], runtime, env);
            if (input.Kind != AosValueKind.Node)
            {
                return AosValue.Unknown;
            }

            return AosValue.FromString(AosFormatter.Format(input.AsNode()));
        }

        if (target == "compiler.validate")
        {
            if (!runtime.Permissions.Contains("compiler"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 1)
            {
                return AosValue.Unknown;
            }

            var input = EvalNode(node.Children[0], runtime, env);
            if (input.Kind != AosValueKind.Node)
            {
                return AosValue.Unknown;
            }

            var validator = new AosValidator();
            var diagnostics = validator.Validate(input.AsNode(), null, runtime.Permissions, runStructural: false).Diagnostics;
            return AosValue.FromNode(CreateDiagnosticsNode(diagnostics, node.Span));
        }

        if (target == "compiler.test")
        {
            if (!runtime.Permissions.Contains("compiler"))
            {
                return AosValue.Unknown;
            }
            if (node.Children.Count != 1)
            {
                return AosValue.Unknown;
            }

            var dirValue = EvalNode(node.Children[0], runtime, env);
            if (dirValue.Kind != AosValueKind.String)
            {
                return AosValue.Unknown;
            }

            return AosValue.FromInt(RunGoldenTests(dirValue.AsString()));
        }

        if (!env.TryGetValue(target, out var functionValue))
        {
            runtime.Env.TryGetValue(target, out functionValue);
        }

        if (functionValue is not null && functionValue.Kind == AosValueKind.Function)
        {
            var args = node.Children.Select(child => EvalNode(child, runtime, env)).ToList();
            return EvalFunctionCall(functionValue.AsFunction(), args, runtime);
        }

        return AosValue.Unknown;
    }

    private AosValue EvalFunction(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (!node.Attrs.TryGetValue("params", out var paramsAttr) || paramsAttr.Kind != AosAttrKind.Identifier)
        {
            return AosValue.Unknown;
        }

        if (node.Children.Count != 1 || node.Children[0].Kind != "Block")
        {
            return AosValue.Unknown;
        }

        var parameters = paramsAttr.AsString()
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList();

        var captured = new Dictionary<string, AosValue>(env, StringComparer.Ordinal);
        var function = new AosFunction(parameters, node.Children[0], captured);
        return AosValue.FromFunction(function);
    }

    private AosValue EvalFunctionCall(AosFunction function, List<AosValue> args, AosRuntime runtime)
    {
        if (function.Parameters.Count != args.Count)
        {
            return AosValue.Unknown;
        }

        var localEnv = new Dictionary<string, AosValue>(runtime.Env, StringComparer.Ordinal);
        foreach (var entry in function.CapturedEnv)
        {
            localEnv[entry.Key] = entry.Value;
        }
        for (var i = 0; i < function.Parameters.Count; i++)
        {
            localEnv[function.Parameters[i]] = args[i];
        }

        try
        {
            return EvalNode(function.Body, runtime, localEnv);
        }
        catch (ReturnSignal signal)
        {
            return signal.Value;
        }
    }

    private AosValue EvalEq(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 2)
        {
            return AosValue.Unknown;
        }
        var left = EvalNode(node.Children[0], runtime, env);
        var right = EvalNode(node.Children[1], runtime, env);
        if (left.Kind != right.Kind)
        {
            return AosValue.FromBool(false);
        }
        return left.Kind switch
        {
            AosValueKind.String => AosValue.FromBool(left.AsString() == right.AsString()),
            AosValueKind.Int => AosValue.FromBool(left.AsInt() == right.AsInt()),
            AosValueKind.Bool => AosValue.FromBool(left.AsBool() == right.AsBool()),
            _ => AosValue.FromBool(false)
        };
    }

    private AosValue EvalAdd(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 2)
        {
            return AosValue.Unknown;
        }
        var left = EvalNode(node.Children[0], runtime, env);
        var right = EvalNode(node.Children[1], runtime, env);
        if (left.Kind != AosValueKind.Int || right.Kind != AosValueKind.Int)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromInt(left.AsInt() + right.AsInt());
    }

    private AosValue EvalToString(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 1)
        {
            return AosValue.Unknown;
        }
        var value = EvalNode(node.Children[0], runtime, env);
        return value.Kind switch
        {
            AosValueKind.Int => AosValue.FromString(value.AsInt().ToString()),
            AosValueKind.Bool => AosValue.FromString(value.AsBool() ? "true" : "false"),
            _ => AosValue.Unknown
        };
    }

    private AosValue EvalStrConcat(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 2)
        {
            return AosValue.Unknown;
        }
        var left = EvalNode(node.Children[0], runtime, env);
        var right = EvalNode(node.Children[1], runtime, env);
        if (left.Kind != AosValueKind.String || right.Kind != AosValueKind.String)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromString(left.AsString() + right.AsString());
    }

    private AosValue EvalStrEscape(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 1)
        {
            return AosValue.Unknown;
        }
        var value = EvalNode(node.Children[0], runtime, env);
        if (value.Kind != AosValueKind.String)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromString(EscapeString(value.AsString()));
    }

    private AosValue EvalMakeBlock(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 1)
        {
            return AosValue.Unknown;
        }
        var idValue = EvalNode(node.Children[0], runtime, env);
        if (idValue.Kind != AosValueKind.String)
        {
            return AosValue.Unknown;
        }
        var result = new AosNode("Block", idValue.AsString(), new Dictionary<string, AosAttrValue>(StringComparer.Ordinal), new List<AosNode>(), node.Span);
        return AosValue.FromNode(result);
    }

    private AosValue EvalAppendChild(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 2)
        {
            return AosValue.Unknown;
        }
        var parentValue = EvalNode(node.Children[0], runtime, env);
        var childValue = EvalNode(node.Children[1], runtime, env);
        if (parentValue.Kind != AosValueKind.Node || childValue.Kind != AosValueKind.Node)
        {
            return AosValue.Unknown;
        }
        var parent = parentValue.AsNode();
        var child = childValue.AsNode();
        var newAttrs = new Dictionary<string, AosAttrValue>(parent.Attrs, StringComparer.Ordinal);
        var newChildren = new List<AosNode>(parent.Children) { child };
        var result = new AosNode(parent.Kind, parent.Id, newAttrs, newChildren, parent.Span);
        return AosValue.FromNode(result);
    }

    private AosValue EvalMakeErr(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 4)
        {
            return AosValue.Unknown;
        }
        var idValue = EvalNode(node.Children[0], runtime, env);
        var codeValue = EvalNode(node.Children[1], runtime, env);
        var messageValue = EvalNode(node.Children[2], runtime, env);
        var nodeIdValue = EvalNode(node.Children[3], runtime, env);
        if (idValue.Kind != AosValueKind.String || codeValue.Kind != AosValueKind.String || messageValue.Kind != AosValueKind.String || nodeIdValue.Kind != AosValueKind.String)
        {
            return AosValue.Unknown;
        }
        var attrs = new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
        {
            ["code"] = new AosAttrValue(AosAttrKind.Identifier, codeValue.AsString()),
            ["message"] = new AosAttrValue(AosAttrKind.String, messageValue.AsString()),
            ["nodeId"] = new AosAttrValue(AosAttrKind.Identifier, nodeIdValue.AsString())
        };
        var result = new AosNode("Err", idValue.AsString(), attrs, new List<AosNode>(), node.Span);
        return AosValue.FromNode(result);
    }

    private AosValue EvalMakeLitString(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 2)
        {
            return AosValue.Unknown;
        }
        var idValue = EvalNode(node.Children[0], runtime, env);
        var strValue = EvalNode(node.Children[1], runtime, env);
        if (idValue.Kind != AosValueKind.String || strValue.Kind != AosValueKind.String)
        {
            return AosValue.Unknown;
        }
        var attrs = new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
        {
            ["value"] = new AosAttrValue(AosAttrKind.String, strValue.AsString())
        };
        var result = new AosNode("Lit", idValue.AsString(), attrs, new List<AosNode>(), node.Span);
        return AosValue.FromNode(result);
    }

    private AosValue EvalNodeKind(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 1)
        {
            return AosValue.Unknown;
        }
        var target = EvalNode(node.Children[0], runtime, env);
        if (target.Kind != AosValueKind.Node)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromString(target.AsNode().Kind);
    }

    private AosValue EvalNodeId(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 1)
        {
            return AosValue.Unknown;
        }
        var target = EvalNode(node.Children[0], runtime, env);
        if (target.Kind != AosValueKind.Node)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromString(target.AsNode().Id);
    }

    private AosValue EvalAttrCount(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 1)
        {
            return AosValue.Unknown;
        }
        var target = EvalNode(node.Children[0], runtime, env);
        if (target.Kind != AosValueKind.Node)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromInt(target.AsNode().Attrs.Count);
    }

    private AosValue EvalAttrKey(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        var (targetNode, index) = ResolveNodeIndex(node, runtime, env);
        if (targetNode is null)
        {
            return AosValue.Unknown;
        }
        var keys = targetNode.Attrs.Keys.OrderBy(k => k, StringComparer.Ordinal).ToList();
        if (index < 0 || index >= keys.Count)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromString(keys[index]);
    }

    private AosValue EvalAttrValueKind(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        var (targetNode, index) = ResolveNodeIndex(node, runtime, env);
        if (targetNode is null)
        {
            return AosValue.Unknown;
        }
        var entry = GetAttrEntry(targetNode, index);
        if (entry is null)
        {
            return AosValue.Unknown;
        }
        var attr = entry.Value.Value;
        return AosValue.FromString(attr.Kind.ToString().ToLowerInvariant());
    }

    private AosValue EvalAttrValueString(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        var (targetNode, index) = ResolveNodeIndex(node, runtime, env);
        if (targetNode is null)
        {
            return AosValue.Unknown;
        }
        var entry = GetAttrEntry(targetNode, index);
        if (entry is null)
        {
            return AosValue.Unknown;
        }
        var attr = entry.Value.Value;
        return attr.Kind switch
        {
            AosAttrKind.String => AosValue.FromString(attr.AsString()),
            AosAttrKind.Identifier => AosValue.FromString(attr.AsString()),
            _ => AosValue.Unknown
        };
    }

    private AosValue EvalAttrValueInt(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        var (targetNode, index) = ResolveNodeIndex(node, runtime, env);
        if (targetNode is null)
        {
            return AosValue.Unknown;
        }
        var entry = GetAttrEntry(targetNode, index);
        if (entry is null || entry.Value.Value.Kind != AosAttrKind.Int)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromInt(entry.Value.Value.AsInt());
    }

    private AosValue EvalAttrValueBool(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        var (targetNode, index) = ResolveNodeIndex(node, runtime, env);
        if (targetNode is null)
        {
            return AosValue.Unknown;
        }
        var entry = GetAttrEntry(targetNode, index);
        if (entry is null || entry.Value.Value.Kind != AosAttrKind.Bool)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromBool(entry.Value.Value.AsBool());
    }

    private AosValue EvalChildCount(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 1)
        {
            return AosValue.Unknown;
        }
        var target = EvalNode(node.Children[0], runtime, env);
        if (target.Kind != AosValueKind.Node)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromInt(target.AsNode().Children.Count);
    }

    private AosValue EvalChildAt(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        var (targetNode, index) = ResolveNodeIndex(node, runtime, env);
        if (targetNode is null)
        {
            return AosValue.Unknown;
        }
        if (index < 0 || index >= targetNode.Children.Count)
        {
            return AosValue.Unknown;
        }
        return AosValue.FromNode(targetNode.Children[index]);
    }

    private (AosNode? node, int index) ResolveNodeIndex(AosNode node, AosRuntime runtime, Dictionary<string, AosValue> env)
    {
        if (node.Children.Count != 2)
        {
            return (null, -1);
        }
        var target = EvalNode(node.Children[0], runtime, env);
        var indexValue = EvalNode(node.Children[1], runtime, env);
        if (target.Kind != AosValueKind.Node || indexValue.Kind != AosValueKind.Int)
        {
            return (null, -1);
        }
        return (target.AsNode(), indexValue.AsInt());
    }

    private static KeyValuePair<string, AosAttrValue>? GetAttrEntry(AosNode node, int index)
    {
        var entries = node.Attrs.OrderBy(k => k.Key, StringComparer.Ordinal).ToList();
        if (index < 0 || index >= entries.Count)
        {
            return null;
        }
        return entries[index];
    }

    private static string EscapeString(string value)
    {
        var sb = new System.Text.StringBuilder();
        foreach (var ch in value)
        {
            switch (ch)
            {
                case '\"': sb.Append("\\\\\""); break;
                case '\\': sb.Append("\\\\"); break;
                case '\n': sb.Append("\\n"); break;
                case '\r': sb.Append("\\r"); break;
                case '\t': sb.Append("\\t"); break;
                default: sb.Append(ch); break;
            }
        }
        return sb.ToString();
    }

    private static string ValueToDisplayString(AosValue value)
    {
        return value.Kind switch
        {
            AosValueKind.String => value.AsString(),
            AosValueKind.Int => value.AsInt().ToString(),
            AosValueKind.Bool => value.AsBool() ? "true" : "false",
            AosValueKind.Void => "void",
            AosValueKind.Node => $"{value.AsNode().Kind}#{value.AsNode().Id}",
            AosValueKind.Function => "function",
            _ => "unknown"
        };
    }

    private static AosNode CreateErrNode(string id, string code, string message, string nodeId, AosSpan span)
    {
        return new AosNode(
            "Err",
            id,
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["code"] = new AosAttrValue(AosAttrKind.Identifier, code),
                ["message"] = new AosAttrValue(AosAttrKind.String, message),
                ["nodeId"] = new AosAttrValue(AosAttrKind.Identifier, nodeId)
            },
            new List<AosNode>(),
            span);
    }

    private static AosNode CreateDiagnosticsNode(List<AosDiagnostic> diagnostics, AosSpan span)
    {
        var children = new List<AosNode>(diagnostics.Count);
        for (var i = 0; i < diagnostics.Count; i++)
        {
            var diagnostic = diagnostics[i];
            children.Add(CreateErrNode(
                $"diag{i}",
                diagnostic.Code,
                diagnostic.Message,
                diagnostic.NodeId ?? "unknown",
                span));
        }

        return new AosNode(
            "Block",
            "diagnostics",
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal),
            children,
            span);
    }

    private static int RunGoldenTests(string directory)
    {
        if (!Directory.Exists(directory))
        {
            Console.WriteLine($"FAIL {directory} (directory not found)");
            return 1;
        }

        var inputFiles = Directory.GetFiles(directory, "*.in.aos", SearchOption.TopDirectoryOnly)
            .OrderBy(path => path, StringComparer.Ordinal)
            .ToList();

        var failCount = 0;
        foreach (var inputPath in inputFiles)
        {
            var stem = inputPath[..^".in.aos".Length];
            var outPath = $"{stem}.out.aos";
            var errPath = $"{stem}.err";
            var testName = Path.GetFileName(stem);
            var source = File.ReadAllText(inputPath);

            string actual;
            string expected;

            if (File.Exists(errPath))
            {
                expected = NormalizeGoldenText(File.ReadAllText(errPath));
                actual = ExecuteCheck(source);
            }
            else if (File.Exists(outPath))
            {
                expected = NormalizeGoldenText(File.ReadAllText(outPath));
                var fmtActual = ExecuteFmt(source);
                var runActual = ExecuteRun(source);
                actual = expected == fmtActual ? fmtActual : runActual;
            }
            else
            {
                failCount++;
                Console.WriteLine($"FAIL {testName}");
                continue;
            }

            if (actual == expected)
            {
                Console.WriteLine($"PASS {testName}");
            }
            else
            {
                failCount++;
                Console.WriteLine($"FAIL {testName}");
            }
        }

        return failCount == 0 ? 0 : 1;
    }

    private static string NormalizeGoldenText(string value)
    {
        var normalized = value.Replace("\r\n", "\n", StringComparison.Ordinal);
        while (normalized.EndsWith("\n", StringComparison.Ordinal))
        {
            normalized = normalized[..^1];
        }
        return normalized;
    }

    private static string ExecuteFmt(string source)
    {
        var parse = ParseSource(source);
        if (parse.Root is null)
        {
            return FormatDiagnosticErr(parse.Diagnostics.FirstOrDefault(), "PAR000");
        }

        if (parse.Diagnostics.Count > 0)
        {
            return FormatDiagnosticErr(parse.Diagnostics[0], parse.Diagnostics[0].Code);
        }

        return AosFormatter.Format(parse.Root);
    }

    private static string ExecuteCheck(string source)
    {
        var parse = ParseSource(source);
        if (parse.Root is null)
        {
            return FormatDiagnosticErr(parse.Diagnostics.FirstOrDefault(), "PAR000");
        }

        if (parse.Diagnostics.Count > 0)
        {
            return FormatDiagnosticErr(parse.Diagnostics[0], parse.Diagnostics[0].Code);
        }

        var permissions = new HashSet<string>(StringComparer.Ordinal) { "math", "io", "compiler", "console" };
        var validator = new AosValidator();
        var validation = validator.Validate(parse.Root, null, permissions, runStructural: false);
        if (validation.Diagnostics.Count == 0)
        {
            return "Ok#ok0(type=void)";
        }

        var first = validation.Diagnostics[0];
        return AosFormatter.Format(CreateErrNode("diag0", first.Code, first.Message, first.NodeId ?? "unknown", parse.Root.Span));
    }

    private static string ExecuteRun(string source)
    {
        var parse = ParseSource(source);
        if (parse.Root is null)
        {
            return FormatDiagnosticErr(parse.Diagnostics.FirstOrDefault(), "PAR000");
        }

        if (parse.Diagnostics.Count > 0)
        {
            return FormatDiagnosticErr(parse.Diagnostics[0], parse.Diagnostics[0].Code);
        }

        var runtime = new AosRuntime();
        runtime.Permissions.Add("console");
        runtime.Permissions.Add("io");
        runtime.Permissions.Add("compiler");

        var validator = new AosValidator();
        var validation = validator.Validate(parse.Root, null, runtime.Permissions, runStructural: false);
        if (validation.Diagnostics.Count > 0)
        {
            var first = validation.Diagnostics[0];
            return AosFormatter.Format(CreateErrNode("diag0", first.Code, first.Message, first.NodeId ?? "unknown", parse.Root.Span));
        }

        var interpreter = new AosInterpreter();
        var result = interpreter.EvaluateProgram(parse.Root, runtime);
        return FormatOkValue(result, parse.Root.Span);
    }

    private static AosParseResult ParseSource(string source)
    {
        var tokenizer = new AosTokenizer(source);
        var tokens = tokenizer.Tokenize();
        var parser = new AosParser(tokens);
        var parse = parser.ParseSingle();
        parse.Diagnostics.AddRange(tokenizer.Diagnostics);
        return parse;
    }

    private static string FormatDiagnosticErr(AosDiagnostic? diagnostic, string fallbackCode)
    {
        var code = diagnostic?.Code ?? fallbackCode;
        var message = diagnostic?.Message ?? "Parse failed.";
        var nodeId = diagnostic?.NodeId ?? "unknown";
        var node = CreateErrNode("err0", code, message, nodeId, new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)));
        return AosFormatter.Format(node);
    }

    private static string FormatOkValue(AosValue value, AosSpan span)
    {
        var attrs = new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
        {
            ["type"] = new AosAttrValue(AosAttrKind.Identifier, value.Kind.ToString().ToLowerInvariant())
        };

        if (value.Kind == AosValueKind.String)
        {
            attrs["value"] = new AosAttrValue(AosAttrKind.String, value.AsString());
        }
        else if (value.Kind == AosValueKind.Int)
        {
            attrs["value"] = new AosAttrValue(AosAttrKind.Int, value.AsInt());
        }
        else if (value.Kind == AosValueKind.Bool)
        {
            attrs["value"] = new AosAttrValue(AosAttrKind.Bool, value.AsBool());
        }

        var ok = new AosNode("Ok", "ok0", attrs, new List<AosNode>(), span);
        return AosFormatter.Format(ok);
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
