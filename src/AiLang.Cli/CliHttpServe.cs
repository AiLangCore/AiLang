internal static class CliHttpServe
{
    public static bool TryParseServeOptions(string[] args, out int port, out string[] appArgs)
    {
        port = 8080;
        var collected = new List<string>();
        for (var i = 0; i < args.Length; i++)
        {
            if (string.Equals(args[i], "--port", StringComparison.Ordinal))
            {
                if (i + 1 >= args.Length || !int.TryParse(args[i + 1], out var parsedPort) || parsedPort < 0 || parsedPort > 65535)
                {
                    appArgs = Array.Empty<string>();
                    return false;
                }

                port = parsedPort;
                i++;
                continue;
            }

            collected.Add(args[i]);
        }

        appArgs = collected.ToArray();
        return true;
    }
}
