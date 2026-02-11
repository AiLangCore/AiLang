using AiLang.Core;

namespace AiLang.Tests;

public class AosTests
{
    [Test]
    public void TokenizerParser_ParsesBasicProgram()
    {
        var source = "Program#p1 { // root\n Let#l1(name=answer) { Lit#v1(value=1) } }";
        var parse = Parse(source);
        Assert.That(parse.Root, Is.Not.Null);
        Assert.That(parse.Diagnostics, Is.Empty);

        var program = parse.Root!;
        Assert.That(program.Kind, Is.EqualTo("Program"));
        Assert.That(program.Children.Count, Is.EqualTo(1));

        var letNode = program.Children[0];
        Assert.That(letNode.Kind, Is.EqualTo("Let"));
        Assert.That(letNode.Attrs["name"].AsString(), Is.EqualTo("answer"));
        Assert.That(letNode.Children.Count, Is.EqualTo(1));
        Assert.That(letNode.Children[0].Kind, Is.EqualTo("Lit"));
    }

    [Test]
    public void Formatter_RoundTrips()
    {
        var source = "Call#c1(target=console.print) { Lit#s1(value=\"hi\\nthere\") }";
        var parse1 = Parse(source);
        Assert.That(parse1.Diagnostics, Is.Empty);
        var formatted = AosFormatter.Format(parse1.Root!);
        var parse2 = Parse(formatted);
        Assert.That(parse2.Diagnostics, Is.Empty);
        var formatted2 = AosFormatter.Format(parse2.Root!);
        Assert.That(formatted2, Is.EqualTo(formatted));
    }

    [Test]
    public void Formatter_ProducesCanonicalOutput()
    {
        var source = "Call#c1(target=console.print) { Lit#s1(value=\"hi\") }";
        var parse = Parse(source);
        Assert.That(parse.Diagnostics, Is.Empty);
        var formatted = AosFormatter.Format(parse.Root!);
        Assert.That(formatted, Is.EqualTo("Call#c1(target=console.print) { Lit#s1(value=\"hi\") }"));
    }

    [Test]
    public void Formatter_SortsAttributesByKey()
    {
        var source = "Program#p1(z=1 a=2) { }";
        var parse = Parse(source);
        Assert.That(parse.Diagnostics, Is.Empty);
        var formatted = AosFormatter.Format(parse.Root!);
        Assert.That(formatted, Is.EqualTo("Program#p1(a=2 z=1)"));
    }

    [Test]
    public void Validator_DeniesConsolePermission()
    {
        var source = "Call#c1(target=console.print) { Lit#s1(value=\"hi\") }";
        var parse = Parse(source);
        var validator = new AosValidator();
        var permissions = new HashSet<string>(StringComparer.Ordinal) { "math" };
        var result = validator.Validate(parse.Root!, null, permissions);
        Assert.That(result.Diagnostics.Any(d => d.Code == "VAL040"), Is.True);
    }

    [Test]
    public void Validator_ReportsMissingAttribute()
    {
        var source = "Let#l1 { Lit#v1(value=1) }";
        var parse = Parse(source);
        var validator = new AosValidator();
        var permissions = new HashSet<string>(StringComparer.Ordinal) { "math" };
        var result = validator.Validate(parse.Root!, null, permissions);
        var diagnostic = result.Diagnostics.FirstOrDefault(d => d.Code == "VAL002");
        Assert.That(diagnostic, Is.Not.Null);
        Assert.That(diagnostic!.Message, Is.EqualTo("Missing attribute 'name'."));
        Assert.That(diagnostic.NodeId, Is.EqualTo("l1"));
    }

    [Test]
    public void Validator_ReportsDuplicateIds()
    {
        var source = "Program#p1 { Lit#dup(value=1) Lit#dup(value=2) }";
        var parse = Parse(source);
        var validator = new AosValidator();
        var permissions = new HashSet<string>(StringComparer.Ordinal) { "math" };
        var result = validator.Validate(parse.Root!, null, permissions);
        var diagnostic = result.Diagnostics.FirstOrDefault(d => d.Code == "VAL001");
        Assert.That(diagnostic, Is.Not.Null);
        Assert.That(diagnostic!.Message, Is.EqualTo("Duplicate node id 'dup'."));
        Assert.That(diagnostic.NodeId, Is.EqualTo("dup"));
    }

    [Test]
    public void PatchOps_ReplaceAndInsert()
    {
        var program = Parse("Program#p1 { Let#l1(name=x) { Lit#v1(value=1) } }").Root!;
        var replaceOp = Parse("Op#o1(kind=replaceNode id=v1) { Lit#v2(value=2) }").Root!;
        var insertOp = Parse("Op#o2(kind=insertChild parentId=p1 slot=declarations index=1) { Let#l2(name=y) { Lit#v3(value=3) } }").Root!;

        var applier = new AosPatchApplier();
        var result = applier.Apply(program, new[] { replaceOp, insertOp });

        Assert.That(result.Diagnostics, Is.Empty);
        Assert.That(result.Root!.Children.Count, Is.EqualTo(2));
        var updatedLit = result.Root.Children[0].Children[0];
        Assert.That(updatedLit.Attrs["value"].AsInt(), Is.EqualTo(2));
    }

    [Test]
    public void Repl_PersistsStateAcrossCommands()
    {
        var session = new AosReplSession();
        var load = "Cmd#c1(name=load) { Program#p1 { Let#l1(name=foo) { Lit#v1(value=5) } } }";
        var eval = "Cmd#c2(name=eval) { Var#v2(name=foo) }";

        var loadResult = session.ExecuteLine(load);
        Assert.That(loadResult.Contains("Ok#"), Is.True);

        var evalResult = session.ExecuteLine(eval);
        Assert.That(evalResult.Contains("type=int"), Is.True);
        Assert.That(evalResult.Contains("value=5"), Is.True);
    }

    [Test]
    public void Repl_HelpReturnsStructuredCommands()
    {
        var session = new AosReplSession();
        var help = "Cmd#c1(name=help)";
        var result = session.ExecuteLine(help);

        var parse = Parse(result);
        Assert.That(parse.Diagnostics, Is.Empty);
        Assert.That(parse.Root, Is.Not.Null);

        var ok = parse.Root!;
        Assert.That(ok.Kind, Is.EqualTo("Ok"));
        Assert.That(ok.Attrs["type"].AsString(), Is.EqualTo("void"));
        Assert.That(ok.Children.Count, Is.EqualTo(5));
        Assert.That(ok.Children.All(child => child.Kind == "Cmd"), Is.True);
        var names = ok.Children.Select(child => child.Attrs["name"].AsString()).ToList();
        var expected = new[] { "help", "setPerms", "load", "eval", "applyPatch" };
        Assert.That(names.Count, Is.EqualTo(expected.Length));
        Assert.That(expected.All(name => names.Contains(name)), Is.True);
    }

    [Test]
    public void CompilerBuiltins_ParseAndValidateWork()
    {
        var source = "Program#p1 { Call#c1(target=compiler.validate) { Call#c2(target=compiler.parse) { Lit#s1(value=\"Program#p2 { Lit#l1(value=1) }\") } } }";
        var parse = Parse(source);
        Assert.That(parse.Diagnostics, Is.Empty);

        var runtime = new AosRuntime();
        runtime.Permissions.Add("compiler");
        var validator = new AosValidator();
        var validation = validator.Validate(parse.Root!, null, runtime.Permissions, runStructural: false);
        Assert.That(validation.Diagnostics, Is.Empty);

        var interpreter = new AosInterpreter();
        var value = interpreter.EvaluateProgram(parse.Root!, runtime);
        Assert.That(value.Kind, Is.EqualTo(AosValueKind.Node));
        var diags = value.AsNode();
        Assert.That(diags.Kind, Is.EqualTo("Block"));
        Assert.That(diags.Children.Count, Is.EqualTo(0));
    }

    [Test]
    public void Aic_Smoke_FmtCheckRun()
    {
        var aicPath = FindRepoFile("compiler/aic.aos");
        var fmtInput = File.ReadAllText(FindRepoFile("examples/aic_fmt_input.aos"));
        var checkInput = File.ReadAllText(FindRepoFile("examples/aic_check_bad.aos"));
        var runInput = File.ReadAllText(FindRepoFile("examples/aic_run_input.aos"));

        var fmtOutput = ExecuteAic(aicPath, "fmt", fmtInput);
        Assert.That(fmtOutput, Is.EqualTo("Program#p1 { Let#l1(name=x) { Lit#v1(value=1) } }"));

        var checkOutput = ExecuteAic(aicPath, "check", checkInput);
        Assert.That(checkOutput.Contains("Err#diag0(code=VAL002"), Is.True);

        var runOutput = ExecuteAic(aicPath, "run", runInput);
        Assert.That(runOutput, Is.EqualTo("Ok#ok0(type=string value=\"hello from main\")"));
    }

    private static AosParseResult Parse(string source)
    {
        var tokenizer = new AosTokenizer(source);
        var tokens = tokenizer.Tokenize();
        var parser = new AosParser(tokens);
        var result = parser.ParseSingle();
        result.Diagnostics.AddRange(tokenizer.Diagnostics);
        return result;
    }

    private static string ExecuteAic(string aicPath, string mode, string stdin)
    {
        var aicProgram = Parse(File.ReadAllText(aicPath)).Root!;
        var runtime = new AosRuntime();
        runtime.Permissions.Add("io");
        runtime.Permissions.Add("compiler");
        runtime.Env["argv"] = AosValue.FromNode(BuildArgvNode(new[] { mode }));
        runtime.ReadOnlyBindings.Add("argv");

        var validator = new AosValidator();
        var envTypes = new Dictionary<string, AosValueKind>(StringComparer.Ordinal)
        {
            ["argv"] = AosValueKind.Node
        };
        var validation = validator.Validate(aicProgram, envTypes, runtime.Permissions, runStructural: false);
        Assert.That(validation.Diagnostics, Is.Empty);

        var oldIn = Console.In;
        var oldOut = Console.Out;
        var writer = new StringWriter();
        try
        {
            Console.SetIn(new StringReader(stdin));
            Console.SetOut(writer);
            var interpreter = new AosInterpreter();
            interpreter.EvaluateProgram(aicProgram, runtime);
        }
        finally
        {
            Console.SetIn(oldIn);
            Console.SetOut(oldOut);
        }

        return writer.ToString();
    }

    private static AosNode BuildArgvNode(string[] values)
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

    private static string FindRepoFile(string relativePath)
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir is not null)
        {
            var candidate = Path.Combine(dir.FullName, relativePath);
            if (File.Exists(candidate))
            {
                return candidate;
            }

            dir = dir.Parent;
        }

        throw new FileNotFoundException($"Could not find {relativePath} from {AppContext.BaseDirectory}");
    }
}
