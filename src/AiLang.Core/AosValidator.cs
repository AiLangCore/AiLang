namespace AiLang.Core;

public sealed class AosValidationResult
{
    public AosValidationResult(List<AosDiagnostic> diagnostics)
    {
        Diagnostics = diagnostics;
    }

    public List<AosDiagnostic> Diagnostics { get; }
}

public sealed class AosValidator
{
    private readonly List<AosDiagnostic> _diagnostics = new();
    private readonly HashSet<string> _ids = new(StringComparer.Ordinal);
    private readonly AosStructuralValidator _structuralValidator = new();

    public AosValidationResult Validate(AosNode root, Dictionary<string, AosValueKind>? envTypes, HashSet<string> permissions)
        => Validate(root, envTypes, permissions, runStructural: true);

    public AosValidationResult Validate(AosNode root, Dictionary<string, AosValueKind>? envTypes, HashSet<string> permissions, bool runStructural)
    {
        _diagnostics.Clear();
        _ids.Clear();

        if (runStructural)
        {
            var structural = _structuralValidator.Validate(root);
            if (structural.Count > 0)
            {
                _diagnostics.AddRange(structural);
                return new AosValidationResult(_diagnostics.ToList());
            }
        }

        var env = envTypes is null
            ? new Dictionary<string, AosValueKind>(StringComparer.Ordinal)
            : new Dictionary<string, AosValueKind>(envTypes, StringComparer.Ordinal);
        PredeclareFunctions(root, env);
        ValidateNode(root, env, permissions);
        return new AosValidationResult(_diagnostics.ToList());
    }

    private AosValueKind ValidateNode(AosNode node, Dictionary<string, AosValueKind> env, HashSet<string> permissions)
    {
        if (!_ids.Add(node.Id))
        {
            _diagnostics.Add(new AosDiagnostic("VAL001", $"Duplicate node id '{node.Id}'.", node.Id, node.Span));
        }

        switch (node.Kind)
        {
            case "Program":
                foreach (var child in node.Children)
                {
                    ValidateNode(child, env, permissions);
                }
                return AosValueKind.Void;
            case "Let":
                RequireAttr(node, "name");
                RequireChildren(node, 1, 1);
                if (node.Children.Count == 1 && node.Children[0].Kind == "Fn" &&
                    node.Attrs.TryGetValue("name", out var fnNameAttr) && fnNameAttr.Kind == AosAttrKind.Identifier)
                {
                    env[fnNameAttr.AsString()] = AosValueKind.Function;
                }

                var letType = node.Children.Count == 1 ? ValidateNode(node.Children[0], env, permissions) : AosValueKind.Unknown;
                if (node.Attrs.TryGetValue("name", out var nameAttr) && nameAttr.Kind == AosAttrKind.Identifier)
                {
                    env[nameAttr.AsString()] = letType;
                }
                return AosValueKind.Void;
            case "Var":
                RequireAttr(node, "name");
                RequireChildren(node, 0, 0);
                if (node.Attrs.TryGetValue("name", out var varNameAttr) && varNameAttr.Kind == AosAttrKind.Identifier)
                {
                    if (env.TryGetValue(varNameAttr.AsString(), out var varType))
                    {
                        return varType;
                    }
                    _diagnostics.Add(new AosDiagnostic("VAL010", $"Unknown variable '{varNameAttr.AsString()}'.", node.Id, node.Span));
                }
                return AosValueKind.Unknown;
            case "Lit":
                RequireAttr(node, "value");
                RequireChildren(node, 0, 0);
                if (node.Attrs.TryGetValue("value", out var litVal))
                {
                    return litVal.Kind switch
                    {
                        AosAttrKind.String => AosValueKind.String,
                        AosAttrKind.Int => AosValueKind.Int,
                        AosAttrKind.Bool => AosValueKind.Bool,
                        _ => AosValueKind.Unknown
                    };
                }
                return AosValueKind.Unknown;
            case "Call":
                RequireAttr(node, "target");
                var target = node.Attrs.TryGetValue("target", out var targetVal) ? targetVal.AsString() : string.Empty;
                var argTypes = node.Children.Select(child => ValidateNode(child, env, permissions)).ToList();
                return ValidateCall(node, target, argTypes, env, permissions);
            case "Fn":
                RequireAttr(node, "params");
                RequireChildren(node, 1, 1);
                if (node.Children.Count == 1 && node.Children[0].Kind != "Block")
                {
                    _diagnostics.Add(new AosDiagnostic("VAL050", "Fn body must be Block.", node.Id, node.Span));
                }
                if (node.Children.Count == 1)
                {
                    var fnEnv = new Dictionary<string, AosValueKind>(env, StringComparer.Ordinal);
                    if (node.Attrs.TryGetValue("params", out var paramsAttr) && paramsAttr.Kind == AosAttrKind.Identifier)
                    {
                        var names = paramsAttr.AsString().Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
                        foreach (var name in names)
                        {
                            if (!string.IsNullOrWhiteSpace(name))
                            {
                                fnEnv[name] = AosValueKind.Unknown;
                            }
                        }
                    }
                    ValidateNode(node.Children[0], fnEnv, permissions);
                }
                return AosValueKind.Function;
            case "Eq":
                RequireChildren(node, 2, 2);
                if (node.Children.Count == 2)
                {
                    var leftType = ValidateNode(node.Children[0], env, permissions);
                    var rightType = ValidateNode(node.Children[1], env, permissions);
                    if (leftType != rightType && leftType != AosValueKind.Unknown && rightType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL051", "Eq operands must have same type.", node.Id, node.Span));
                    }
                }
                return AosValueKind.Bool;
            case "Add":
                RequireChildren(node, 2, 2);
                if (node.Children.Count == 2)
                {
                    var leftType = ValidateNode(node.Children[0], env, permissions);
                    var rightType = ValidateNode(node.Children[1], env, permissions);
                    if (leftType != AosValueKind.Int && leftType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL052", "Add left operand must be int.", node.Id, node.Span));
                    }
                    if (rightType != AosValueKind.Int && rightType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL053", "Add right operand must be int.", node.Id, node.Span));
                    }
                }
                return AosValueKind.Int;
            case "ToString":
                RequireChildren(node, 1, 1);
                if (node.Children.Count == 1)
                {
                    var valueType = ValidateNode(node.Children[0], env, permissions);
                    if (valueType != AosValueKind.Int && valueType != AosValueKind.Bool && valueType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL054", "ToString expects int or bool.", node.Id, node.Span));
                    }
                }
                return AosValueKind.String;
            case "StrConcat":
                RequireChildren(node, 2, 2);
                if (node.Children.Count == 2)
                {
                    var leftType = ValidateNode(node.Children[0], env, permissions);
                    var rightType = ValidateNode(node.Children[1], env, permissions);
                    if (leftType != AosValueKind.String && leftType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL055", "StrConcat left operand must be string.", node.Id, node.Span));
                    }
                    if (rightType != AosValueKind.String && rightType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL056", "StrConcat right operand must be string.", node.Id, node.Span));
                    }
                }
                return AosValueKind.String;
            case "StrEscape":
                RequireChildren(node, 1, 1);
                if (node.Children.Count == 1)
                {
                    var valueType = ValidateNode(node.Children[0], env, permissions);
                    if (valueType != AosValueKind.String && valueType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL057", "StrEscape expects string.", node.Id, node.Span));
                    }
                }
                return AosValueKind.String;
            case "MakeBlock":
                RequireChildren(node, 1, 1);
                if (node.Children.Count == 1)
                {
                    var idType = ValidateNode(node.Children[0], env, permissions);
                    if (idType != AosValueKind.String && idType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL058", "MakeBlock expects string id.", node.Id, node.Span));
                    }
                }
                return AosValueKind.Node;
            case "AppendChild":
                RequireChildren(node, 2, 2);
                if (node.Children.Count == 2)
                {
                    var parentType = ValidateNode(node.Children[0], env, permissions);
                    var childType = ValidateNode(node.Children[1], env, permissions);
                    if (parentType != AosValueKind.Node && parentType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL059", "AppendChild expects node parent.", node.Id, node.Span));
                    }
                    if (childType != AosValueKind.Node && childType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL060", "AppendChild expects node child.", node.Id, node.Span));
                    }
                }
                return AosValueKind.Node;
            case "MakeErr":
                RequireChildren(node, 4, 4);
                ValidateChildrenAsStrings(node, env, permissions, "VAL061");
                return AosValueKind.Node;
            case "MakeLitString":
                RequireChildren(node, 2, 2);
                ValidateChildrenAsStrings(node, env, permissions, "VAL062");
                return AosValueKind.Node;
            case "NodeKind":
            case "NodeId":
                RequireChildren(node, 1, 1);
                if (node.Children.Count == 1)
                {
                    var nodeType = ValidateNode(node.Children[0], env, permissions);
                    if (nodeType != AosValueKind.Node && nodeType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL060", $"{node.Kind} expects node.", node.Id, node.Span));
                    }
                }
                return AosValueKind.String;
            case "AttrCount":
            case "ChildCount":
                RequireChildren(node, 1, 1);
                if (node.Children.Count == 1)
                {
                    var nodeType = ValidateNode(node.Children[0], env, permissions);
                    if (nodeType != AosValueKind.Node && nodeType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL061", $"{node.Kind} expects node.", node.Id, node.Span));
                    }
                }
                return AosValueKind.Int;
            case "AttrKey":
            case "AttrValueKind":
            case "AttrValueString":
                RequireChildren(node, 2, 2);
                ValidateNodeChildPair(node, env, permissions, "VAL062");
                return AosValueKind.String;
            case "AttrValueInt":
                RequireChildren(node, 2, 2);
                ValidateNodeChildPair(node, env, permissions, "VAL063");
                return AosValueKind.Int;
            case "AttrValueBool":
                RequireChildren(node, 2, 2);
                ValidateNodeChildPair(node, env, permissions, "VAL064");
                return AosValueKind.Bool;
            case "ChildAt":
                RequireChildren(node, 2, 2);
                ValidateNodeChildPair(node, env, permissions, "VAL065");
                return AosValueKind.Node;
            case "If":
                RequireChildren(node, 2, 3);
                if (node.Children.Count >= 1)
                {
                    var condType = ValidateNode(node.Children[0], env, permissions);
                    if (condType != AosValueKind.Bool && condType != AosValueKind.Unknown)
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL020", "If condition must be bool.", node.Id, node.Span));
                    }
                }
                if (node.Children.Count >= 2)
                {
                    if (node.Children[1].Kind != "Block")
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL021", "If then-branch must be Block.", node.Id, node.Span));
                    }
                }
                if (node.Children.Count == 3)
                {
                    if (node.Children[2].Kind != "Block")
                    {
                        _diagnostics.Add(new AosDiagnostic("VAL022", "If else-branch must be Block.", node.Id, node.Span));
                    }
                }

                var thenType = node.Children.Count >= 2 ? ValidateNode(node.Children[1], new Dictionary<string, AosValueKind>(env), permissions) : AosValueKind.Void;
                var elseType = node.Children.Count == 3 ? ValidateNode(node.Children[2], new Dictionary<string, AosValueKind>(env), permissions) : AosValueKind.Void;

                if (node.Children.Count == 2)
                {
                    return AosValueKind.Void;
                }

                if (thenType == elseType)
                {
                    return thenType;
                }

                if (thenType == AosValueKind.Unknown || elseType == AosValueKind.Unknown)
                {
                    return AosValueKind.Unknown;
                }

                _diagnostics.Add(new AosDiagnostic("VAL023", "If branches must return the same type.", node.Id, node.Span));
                return AosValueKind.Unknown;
            case "Block":
                var blockType = AosValueKind.Void;
                foreach (var child in node.Children)
                {
                    blockType = ValidateNode(child, env, permissions);
                }
                return blockType;
            case "Return":
                RequireChildren(node, 0, 1);
                if (node.Children.Count == 1)
                {
                    return ValidateNode(node.Children[0], env, permissions);
                }
                return AosValueKind.Void;
            default:
                _diagnostics.Add(new AosDiagnostic("VAL999", $"Unknown node kind '{node.Kind}'.", node.Id, node.Span));
                return AosValueKind.Unknown;
        }
    }

    private AosValueKind ValidateCall(AosNode node, string target, List<AosValueKind> argTypes, Dictionary<string, AosValueKind> env, HashSet<string> permissions)
    {
        if (string.IsNullOrWhiteSpace(target))
        {
            _diagnostics.Add(new AosDiagnostic("VAL030", "Call target is required.", node.Id, node.Span));
            return AosValueKind.Unknown;
        }

        if (target == "math.add")
        {
            RequirePermission(node, "math", permissions);
            if (argTypes.Count != 2)
            {
                _diagnostics.Add(new AosDiagnostic("VAL031", "math.add expects 2 arguments.", node.Id, node.Span));
            }
            else
            {
                if (argTypes[0] != AosValueKind.Int && argTypes[0] != AosValueKind.Unknown)
                {
                    _diagnostics.Add(new AosDiagnostic("VAL032", "math.add arg 1 must be int.", node.Id, node.Span));
                }
                if (argTypes[1] != AosValueKind.Int && argTypes[1] != AosValueKind.Unknown)
                {
                    _diagnostics.Add(new AosDiagnostic("VAL033", "math.add arg 2 must be int.", node.Id, node.Span));
                }
            }
            return AosValueKind.Int;
        }


        if (target == "console.print")
        {
            RequirePermission(node, "console", permissions);
            if (argTypes.Count != 1)
            {
                _diagnostics.Add(new AosDiagnostic("VAL034", "console.print expects 1 argument.", node.Id, node.Span));
            }
            else if (argTypes[0] != AosValueKind.String && argTypes[0] != AosValueKind.Unknown)
            {
                _diagnostics.Add(new AosDiagnostic("VAL035", "console.print arg must be string.", node.Id, node.Span));
            }
            return AosValueKind.Void;
        }

        if (target == "io.print")
        {
            RequirePermission(node, "io", permissions);
            if (argTypes.Count != 1)
            {
                _diagnostics.Add(new AosDiagnostic("VAL070", "io.print expects 1 argument.", node.Id, node.Span));
            }
            return AosValueKind.Void;
        }

        if (target == "io.write")
        {
            RequirePermission(node, "io", permissions);
            if (argTypes.Count != 1)
            {
                _diagnostics.Add(new AosDiagnostic("VAL072", "io.write expects 1 argument.", node.Id, node.Span));
            }
            else if (argTypes[0] != AosValueKind.String && argTypes[0] != AosValueKind.Unknown)
            {
                _diagnostics.Add(new AosDiagnostic("VAL073", "io.write arg must be string.", node.Id, node.Span));
            }
            return AosValueKind.Void;
        }

        if (target == "io.readLine")
        {
            RequirePermission(node, "io", permissions);
            if (argTypes.Count != 0)
            {
                _diagnostics.Add(new AosDiagnostic("VAL071", "io.readLine expects 0 arguments.", node.Id, node.Span));
            }
            return AosValueKind.String;
        }

        if (target == "io.readAllStdin")
        {
            RequirePermission(node, "io", permissions);
            if (argTypes.Count != 0)
            {
                _diagnostics.Add(new AosDiagnostic("VAL074", "io.readAllStdin expects 0 arguments.", node.Id, node.Span));
            }
            return AosValueKind.String;
        }

        if (target == "io.readFile")
        {
            RequirePermission(node, "io", permissions);
            if (argTypes.Count != 1)
            {
                _diagnostics.Add(new AosDiagnostic("VAL081", "io.readFile expects 1 argument.", node.Id, node.Span));
            }
            else if (argTypes[0] != AosValueKind.String && argTypes[0] != AosValueKind.Unknown)
            {
                _diagnostics.Add(new AosDiagnostic("VAL082", "io.readFile arg must be string.", node.Id, node.Span));
            }
            return AosValueKind.String;
        }

        if (target == "io.fileExists")
        {
            RequirePermission(node, "io", permissions);
            if (argTypes.Count != 1)
            {
                _diagnostics.Add(new AosDiagnostic("VAL083", "io.fileExists expects 1 argument.", node.Id, node.Span));
            }
            else if (argTypes[0] != AosValueKind.String && argTypes[0] != AosValueKind.Unknown)
            {
                _diagnostics.Add(new AosDiagnostic("VAL084", "io.fileExists arg must be string.", node.Id, node.Span));
            }
            return AosValueKind.Bool;
        }

        if (target == "compiler.parse")
        {
            RequirePermission(node, "compiler", permissions);
            if (argTypes.Count != 1)
            {
                _diagnostics.Add(new AosDiagnostic("VAL075", "compiler.parse expects 1 argument.", node.Id, node.Span));
            }
            else if (argTypes[0] != AosValueKind.String && argTypes[0] != AosValueKind.Unknown)
            {
                _diagnostics.Add(new AosDiagnostic("VAL076", "compiler.parse arg must be string.", node.Id, node.Span));
            }
            return AosValueKind.Node;
        }

        if (target == "compiler.format")
        {
            RequirePermission(node, "compiler", permissions);
            if (argTypes.Count != 1)
            {
                _diagnostics.Add(new AosDiagnostic("VAL077", "compiler.format expects 1 argument.", node.Id, node.Span));
            }
            else if (argTypes[0] != AosValueKind.Node && argTypes[0] != AosValueKind.Unknown)
            {
                _diagnostics.Add(new AosDiagnostic("VAL078", "compiler.format arg must be node.", node.Id, node.Span));
            }
            return AosValueKind.String;
        }

        if (target == "compiler.validate")
        {
            RequirePermission(node, "compiler", permissions);
            if (argTypes.Count != 1)
            {
                _diagnostics.Add(new AosDiagnostic("VAL079", "compiler.validate expects 1 argument.", node.Id, node.Span));
            }
            else if (argTypes[0] != AosValueKind.Node && argTypes[0] != AosValueKind.Unknown)
            {
                _diagnostics.Add(new AosDiagnostic("VAL080", "compiler.validate arg must be node.", node.Id, node.Span));
            }
            return AosValueKind.Node;
        }

        if (target == "compiler.validateHost")
        {
            RequirePermission(node, "compiler", permissions);
            if (argTypes.Count != 1)
            {
                _diagnostics.Add(new AosDiagnostic("VAL087", "compiler.validateHost expects 1 argument.", node.Id, node.Span));
            }
            else if (argTypes[0] != AosValueKind.Node && argTypes[0] != AosValueKind.Unknown)
            {
                _diagnostics.Add(new AosDiagnostic("VAL088", "compiler.validateHost arg must be node.", node.Id, node.Span));
            }
            return AosValueKind.Node;
        }

        if (target == "compiler.test")
        {
            RequirePermission(node, "compiler", permissions);
            if (argTypes.Count != 1)
            {
                _diagnostics.Add(new AosDiagnostic("VAL085", "compiler.test expects 1 argument.", node.Id, node.Span));
            }
            else if (argTypes[0] != AosValueKind.String && argTypes[0] != AosValueKind.Unknown)
            {
                _diagnostics.Add(new AosDiagnostic("VAL086", "compiler.test arg must be string.", node.Id, node.Span));
            }
            return AosValueKind.Int;
        }

        if (!target.Contains('.') && env.TryGetValue(target, out var fnType) && fnType == AosValueKind.Function)
        {
            return AosValueKind.Unknown;
        }

        _diagnostics.Add(new AosDiagnostic("VAL036", $"Unknown call target '{target}'.", node.Id, node.Span));
        return AosValueKind.Unknown;
    }

    private void RequireAttr(AosNode node, string name)
    {
        if (!node.Attrs.ContainsKey(name))
        {
            _diagnostics.Add(new AosDiagnostic("VAL002", $"Missing attribute '{name}'.", node.Id, node.Span));
        }
    }

    private void RequireChildren(AosNode node, int min, int max)
    {
        if (node.Children.Count < min || node.Children.Count > max)
        {
            _diagnostics.Add(new AosDiagnostic("VAL003", $"{node.Kind} expects {min}-{max} children.", node.Id, node.Span));
        }
    }

    private void RequirePermission(AosNode node, string permission, HashSet<string> permissions)
    {
        if (!permissions.Contains(permission))
        {
            _diagnostics.Add(new AosDiagnostic("VAL040", $"Permission '{permission}' denied.", node.Id, node.Span));
        }
    }

    private void ValidateNodeChildPair(AosNode node, Dictionary<string, AosValueKind> env, HashSet<string> permissions, string code)
    {
        if (node.Children.Count != 2)
        {
            return;
        }
        var targetType = ValidateNode(node.Children[0], env, permissions);
        var indexType = ValidateNode(node.Children[1], env, permissions);
        if (targetType != AosValueKind.Node && targetType != AosValueKind.Unknown)
        {
            _diagnostics.Add(new AosDiagnostic(code, $"{node.Kind} expects node as first child.", node.Id, node.Span));
        }
        if (indexType != AosValueKind.Int && indexType != AosValueKind.Unknown)
        {
            _diagnostics.Add(new AosDiagnostic(code, $"{node.Kind} expects int index as second child.", node.Id, node.Span));
        }
    }

    private void ValidateChildrenAsStrings(AosNode node, Dictionary<string, AosValueKind> env, HashSet<string> permissions, string code)
    {
        foreach (var child in node.Children)
        {
            var valueType = ValidateNode(child, env, permissions);
            if (valueType != AosValueKind.String && valueType != AosValueKind.Unknown)
            {
                _diagnostics.Add(new AosDiagnostic(code, $"{node.Kind} expects string arguments.", node.Id, node.Span));
                return;
            }
        }
    }

    private void PredeclareFunctions(AosNode node, Dictionary<string, AosValueKind> env)
    {
        if (node.Kind == "Let" && node.Children.Count == 1 && node.Children[0].Kind == "Fn")
        {
            if (node.Attrs.TryGetValue("name", out var nameAttr) && nameAttr.Kind == AosAttrKind.Identifier)
            {
                env[nameAttr.AsString()] = AosValueKind.Function;
            }
        }

        foreach (var child in node.Children)
        {
            PredeclareFunctions(child, env);
        }
    }
}
