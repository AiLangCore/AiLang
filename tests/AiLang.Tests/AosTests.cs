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

    private static AosParseResult Parse(string source)
    {
        var tokenizer = new AosTokenizer(source);
        var tokens = tokenizer.Tokenize();
        var parser = new AosParser(tokens);
        var result = parser.ParseSingle();
        result.Diagnostics.AddRange(tokenizer.Diagnostics);
        return result;
    }
}
