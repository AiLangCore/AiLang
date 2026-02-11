using System.Text;

namespace AiLang.Core;

public static class AosFormatter
{
    public static string Format(AosNode node)
    {
        var sb = new StringBuilder();
        WriteNode(sb, node);
        return sb.ToString();
    }

    private static void WriteNode(StringBuilder sb, AosNode node)
    {
        sb.Append(node.Kind);
        sb.Append('#');
        sb.Append(node.Id);

        if (node.Attrs.Count > 0)
        {
            sb.Append('(');
            var first = true;
            foreach (var entry in node.Attrs.OrderBy(k => k.Key, StringComparer.Ordinal))
            {
                if (!first)
                {
                    sb.Append(' ');
                }
                first = false;
                sb.Append(entry.Key);
                sb.Append('=');
                WriteAttrValue(sb, entry.Value);
            }
            sb.Append(')');
        }

        if (node.Children.Count > 0)
        {
            sb.Append(" { ");
            for (var i = 0; i < node.Children.Count; i++)
            {
                if (i > 0)
                {
                    sb.Append(' ');
                }
                WriteNode(sb, node.Children[i]);
            }
            sb.Append(" }");
        }
    }

    private static void WriteAttrValue(StringBuilder sb, AosAttrValue value)
    {
        switch (value.Kind)
        {
            case AosAttrKind.String:
                sb.Append('"');
                sb.Append(Escape((string)value.Value));
                sb.Append('"');
                break;
            case AosAttrKind.Int:
                sb.Append((int)value.Value);
                break;
            case AosAttrKind.Bool:
                sb.Append(((bool)value.Value) ? "true" : "false");
                break;
            case AosAttrKind.Identifier:
                sb.Append((string)value.Value);
                break;
        }
    }

    private static string Escape(string value)
    {
        var sb = new StringBuilder();
        foreach (var ch in value)
        {
            switch (ch)
            {
                case '"': sb.Append("\\\""); break;
                case '\\': sb.Append("\\\\"); break;
                case '\n': sb.Append("\\n"); break;
                case '\r': sb.Append("\\r"); break;
                case '\t': sb.Append("\\t"); break;
                default: sb.Append(ch); break;
            }
        }
        return sb.ToString();
    }
}
