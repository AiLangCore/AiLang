using AiLang.Core;

if (args.Length == 0 || args[0] != "repl")
{
    Console.WriteLine("Usage: airun repl");
    return;
}

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
