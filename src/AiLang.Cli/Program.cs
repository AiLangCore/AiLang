using AiLang.Core;
using System.Text;

var traceEnabled = args.Contains("--trace", StringComparer.Ordinal);
var filteredArgs = args.Where(a => !string.Equals(a, "--trace", StringComparison.Ordinal)).ToArray();

if (TryLoadEmbeddedBundle(out var embeddedBundleText))
{
    Environment.ExitCode = RunEmbeddedBundle(embeddedBundleText!, filteredArgs, traceEnabled);
    return;
}

if (filteredArgs.Length == 0)
{
    PrintUsage();
    Environment.ExitCode = 1;
    return;
}

if (filteredArgs[0] == "repl")
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

if (filteredArgs[0] != "run")
{
    PrintUsage();
    Environment.ExitCode = 1;
    return;
}

if (filteredArgs.Length < 2)
{
    PrintUsage();
    Environment.ExitCode = 1;
    return;
}

try
{
    var source = File.ReadAllText(filteredArgs[1]);
    var argv = filteredArgs.Skip(2).ToArray();
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
    runtime.ModuleBaseDir = Path.GetDirectoryName(Path.GetFullPath(filteredArgs[1])) ?? Directory.GetCurrentDirectory();
    runtime.TraceEnabled = traceEnabled;
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
    if (traceEnabled)
    {
        Console.WriteLine(FormatTrace("trace1", runtime.TraceSteps));
    }
    else
    {
        Console.WriteLine(FormatOk("ok1", result));
    }
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

static int RunEmbeddedBundle(string bundleText, string[] cliArgs, bool traceEnabled)
{
    try
    {
        var parse = Parse(bundleText);
        if (parse.Root is null || parse.Diagnostics.Count > 0)
        {
            var diagnostic = parse.Diagnostics.FirstOrDefault() ?? new AosDiagnostic("BND001", "Embedded bundle parse failed.", "bundle", null);
            Console.WriteLine(FormatErr("err1", diagnostic.Code, diagnostic.Message, diagnostic.NodeId ?? "bundle"));
            return 3;
        }

        if (parse.Root.Kind != "Bundle")
        {
            Console.WriteLine(FormatErr("err1", "BND002", "Embedded payload is not a Bundle node.", parse.Root.Id));
            return 3;
        }

        if (!TryGetBundleAttr(parse.Root, "entryFile", out var entryFile) ||
            !TryGetBundleAttr(parse.Root, "entryExport", out var entryExport))
        {
            Console.WriteLine(FormatErr("err1", "BND003", "Bundle is missing required attributes.", parse.Root.Id));
            return 3;
        }

        var runtime = new AosRuntime();
        runtime.Permissions.Add("console");
        runtime.Permissions.Add("io");
        runtime.Permissions.Add("compiler");
        runtime.TraceEnabled = traceEnabled;
        runtime.ModuleBaseDir = Path.GetDirectoryName(Environment.ProcessPath ?? AppContext.BaseDirectory) ?? Directory.GetCurrentDirectory();
        runtime.Env["argv"] = AosValue.FromNode(BuildArgvNode(cliArgs));
        runtime.ReadOnlyBindings.Add("argv");
        runtime.Env["__entryArgs"] = AosValue.FromNode(BuildArgvNode(cliArgs));
        runtime.ReadOnlyBindings.Add("__entryArgs");

        var driverProgram = new AosNode(
            "Program",
            "embedded_program",
            new Dictionary<string, AosAttrValue>(StringComparer.Ordinal),
            new List<AosNode>
            {
                new(
                    "Import",
                    "embedded_import",
                    new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
                    {
                        ["path"] = new AosAttrValue(AosAttrKind.String, entryFile)
                    },
                    new List<AosNode>(),
                    new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0))),
                new(
                    "Var",
                    "embedded_export",
                    new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
                    {
                        ["name"] = new AosAttrValue(AosAttrKind.Identifier, entryExport)
                    },
                    new List<AosNode>(),
                    new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)))
            },
            new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)));

        var interpreter = new AosInterpreter();
        var exportValue = interpreter.EvaluateProgram(driverProgram, runtime);
        if (IsErrNode(exportValue, out var exportErr))
        {
            Console.WriteLine(AosFormatter.Format(exportErr!));
            return 3;
        }

        AosValue result;
        if (exportValue.Kind == AosValueKind.Function)
        {
            var call = new AosNode(
                "Call",
                "embedded_call",
                new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
                {
                    ["target"] = new AosAttrValue(AosAttrKind.Identifier, entryExport)
                },
                new List<AosNode>
                {
                    new(
                        "Var",
                        "embedded_args",
                        new Dictionary<string, AosAttrValue>(StringComparer.Ordinal)
                        {
                            ["name"] = new AosAttrValue(AosAttrKind.Identifier, "__entryArgs")
                        },
                        new List<AosNode>(),
                        new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)))
                },
                new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)));
            result = interpreter.EvaluateExpression(call, runtime);
        }
        else
        {
            result = exportValue;
        }

        if (IsErrNode(result, out var errNode))
        {
            Console.WriteLine(AosFormatter.Format(errNode!));
            return 3;
        }

        if (traceEnabled)
        {
            Console.WriteLine(FormatTrace("trace1", runtime.TraceSteps));
        }

        return result.Kind == AosValueKind.Int ? result.AsInt() : 0;
    }
    catch (Exception ex)
    {
        Console.WriteLine(FormatErr("err1", "BND004", ex.Message, "bundle"));
        return 3;
    }
}

static bool TryLoadEmbeddedBundle(out string? bundleText)
{
    bundleText = null;
    var processPath = Environment.ProcessPath;
    if (string.IsNullOrWhiteSpace(processPath) || !File.Exists(processPath))
    {
        return false;
    }

    var marker = Encoding.UTF8.GetBytes("\n--AIBUNDLE1--\n");
    var bytes = File.ReadAllBytes(processPath);
    var markerIndex = LastIndexOf(bytes, marker);
    if (markerIndex < 0)
    {
        return false;
    }

    var start = markerIndex + marker.Length;
    if (start >= bytes.Length)
    {
        return false;
    }

    bundleText = Encoding.UTF8.GetString(bytes, start, bytes.Length - start);
    return true;
}

static int LastIndexOf(byte[] haystack, byte[] needle)
{
    for (var i = haystack.Length - needle.Length; i >= 0; i--)
    {
        var match = true;
        for (var j = 0; j < needle.Length; j++)
        {
            if (haystack[i + j] != needle[j])
            {
                match = false;
                break;
            }
        }

        if (match)
        {
            return i;
        }
    }

    return -1;
}

static bool TryGetBundleAttr(AosNode bundle, string key, out string value)
{
    value = string.Empty;
    if (!bundle.Attrs.TryGetValue(key, out var attr) || attr.Kind != AosAttrKind.String)
    {
        return false;
    }
    value = attr.AsString();
    return !string.IsNullOrEmpty(value);
}

static bool IsErrNode(AosValue value, out AosNode? errNode)
{
    errNode = null;
    if (value.Kind != AosValueKind.Node)
    {
        return false;
    }
    var node = value.AsNode();
    if (node.Kind != "Err")
    {
        return false;
    }
    errNode = node;
    return true;
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

static string FormatTrace(string id, List<AosNode> steps)
{
    var trace = new AosNode(
        "Trace",
        id,
        new Dictionary<string, AosAttrValue>(StringComparer.Ordinal),
        new List<AosNode>(steps),
        new AosSpan(new AosPosition(0, 0, 0), new AosPosition(0, 0, 0)));
    return AosFormatter.Format(trace);
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
