using AiLang.Core;

if (args.Length == 0)
{
    PrintUsage();
    Environment.ExitCode = 1;
    return;
}

if (args[0] == "repl")
{
    var session = new AosReplSession();
    string? line;
    while ((line = Console.ReadLine()) is not null)
    {
        if (string.IsNullOrWhiteSpace(line))
        {
            continue;
        }

        var output = session.ExecuteLine(line);
        Console.WriteLine(output);
    }
    return;
}

if (args[0] != "run")
{
    PrintUsage();
    Environment.ExitCode = 1;
    return;
}

if (args.Length < 2)
{
    PrintUsage();
    Environment.ExitCode = 1;
    return;
}

try
{
    var source = File.ReadAllText(args[1]);
    var argv = args.Skip(2).ToArray();
    var parse = Parse(source);
    if (parse.Root is null || parse.Diagnostics.Count > 0)
    {
        var diagnostic = parse.Diagnostics.FirstOrDefault() ?? new AosDiagnostic("PAR000", "Parse failed.", "unknown", null);
        Console.WriteLine(FormatErr("err1", diagnostic.Code, diagnostic.Message, diagnostic.NodeId ?? "unknown"));
        Environment.ExitCode = 2;
        return;
    }

    if (parse.Root.Kind != "Program")
    {
        Console.WriteLine(FormatErr("err1", "RUN002", "run expects Program root.", parse.Root.Id));
        Environment.ExitCode = 2;
        return;
    }

    var runtime = new AosRuntime();
    runtime.Permissions.Add("console");
    runtime.Permissions.Add("io");
    runtime.Permissions.Add("compiler");
    runtime.ModuleBaseDir = Path.GetDirectoryName(Path.GetFullPath(args[1])) ?? Directory.GetCurrentDirectory();
    runtime.Env["argv"] = AosValue.FromNode(BuildArgvNode(argv));
    runtime.ReadOnlyBindings.Add("argv");

    var envTypes = new Dictionary<string, AosValueKind>(StringComparer.Ordinal)
    {
        ["argv"] = AosValueKind.Node
    };

    var validator = new AosValidator();
    var validation = validator.Validate(parse.Root, envTypes, runtime.Permissions, runStructural: false);
    if (validation.Diagnostics.Count > 0)
    {
        var diagnostic = validation.Diagnostics[0];
        Console.WriteLine(FormatErr("err1", diagnostic.Code, diagnostic.Message, diagnostic.NodeId ?? "unknown"));
        Environment.ExitCode = 2;
        return;
    }

    var interpreter = new AosInterpreter();
    var result = interpreter.EvaluateProgram(parse.Root, runtime);
    Console.WriteLine(FormatOk("ok1", result));
    Environment.ExitCode = result.Kind == AosValueKind.Int ? result.AsInt() : 0;
}
catch (Exception ex)
{
    Console.WriteLine(FormatErr("err1", "RUN001", ex.Message, "unknown"));
    Environment.ExitCode = 3;
}

static AosParseResult Parse(string source)
{
    return AosExternalFrontend.Parse(source);
}

static string FormatOk(string id, AosValue value)
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

    var node = new AosNode(
        "Ok",
        id,
        attrs,
        new List<AosNode>(),
        new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)));
    return AosFormatter.Format(node);
}

static string FormatErr(string id, string code, string message, string nodeId)
{
    var node = new AosNode(
        "Err",
        id,
        new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
        {
            ["code"] = new AosAttrValue(AosAttrKind.Identifier, code),
            ["message"] = new AosAttrValue(AosAttrKind.String, message),
            ["nodeId"] = new AosAttrValue(AosAttrKind.Identifier, nodeId)
        },
        new List<AosNode>(),
        new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)));
    return AosFormatter.Format(node);
}

static void PrintUsage()
{
    Console.WriteLine("Usage: airun repl | airun run <path.aos>");
}

static AosNode BuildArgvNode(string[] values)
{
    var children = new List<AosNode>(values.Length);
    for (var i = 0; i < values.Length; i++)
    {
        children.Add(new AosNode(
            "Lit",
            $"argv{i}",
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
            {
                ["value"] = new AosAttrValue(AosAttrKind.String, values[i])
            },
            new List<AosNode>(),
            new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0))));
    }

    return new AosNode(
        "Block",
        "argv",
        new Dictionary<string, AosAttrValue>(StringComparer.Ordinal),
        children,
        new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)));
}
