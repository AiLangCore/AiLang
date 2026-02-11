using System.Text;

namespace AiLang.Core;

public enum AosTokenKind
{
    Identifier,
    Hash,
    LParen,
    RParen,
    LBrace,
    RBrace,
    Equals,
    String,
    Int,
    Bool,
    Dot,
    Comma,
    End
}

public sealed record AosToken(AosTokenKind Kind, string Text, AosSpan Span);

public sealed class AosTokenizer
{
    private readonly string _source;
    private int _index;
    private int _line;
    private int _col;
    private readonly List<AosDiagnostic> _diagnostics = new();

    public AosTokenizer(string source)
    {
        _source = source;
        _index = 0;
        _line = 1;
        _col = 1;
    }

    public IReadOnlyList<AosDiagnostic> Diagnostics => _diagnostics;

    public List<AosToken> Tokenize()
    {
        var tokens = new List<AosToken>();
        while (true)
        {
            SkipWhitespaceAndComments();
            if (IsAtEnd())
            {
                tokens.Add(MakeToken(AosTokenKind.End, string.Empty, CurrentPosition(), CurrentPosition()));
                break;
            }

            var ch = Peek();
            if (IsIdentifierStart(ch))
            {
                tokens.Add(ReadIdentifierOrBool());
                continue;
            }

            if (ch == '-' || char.IsDigit(ch))
            {
                var token = ReadNumberOrIdentifier();
                if (token is not null)
                {
                    tokens.Add(token);
                    continue;
                }
            }

            switch (ch)
            {
                case '#':
                    tokens.Add(ConsumeSingle(AosTokenKind.Hash, "#"));
                    break;
                case '(':
                    tokens.Add(ConsumeSingle(AosTokenKind.LParen, "("));
                    break;
                case ')':
                    tokens.Add(ConsumeSingle(AosTokenKind.RParen, ")"));
                    break;
                case '{':
                    tokens.Add(ConsumeSingle(AosTokenKind.LBrace, "{"));
                    break;
                case '}':
                    tokens.Add(ConsumeSingle(AosTokenKind.RBrace, "}"));
                    break;
                case '=':
                    tokens.Add(ConsumeSingle(AosTokenKind.Equals, "="));
                    break;
                case '.':
                    tokens.Add(ConsumeSingle(AosTokenKind.Dot, "."));
                    break;
                case ',':
                    tokens.Add(ConsumeSingle(AosTokenKind.Comma, ","));
                    break;
                case '"':
                    tokens.Add(ReadString());
                    break;
                default:
                    var start = CurrentPosition();
                    Advance();
                    var end = CurrentPosition();
                    _diagnostics.Add(new AosDiagnostic("TOK001", $"Unexpected character '{ch}'.", null, new AosSpan(start, end)));
                    break;
            }
        }

        return tokens;
    }

    private AosToken ReadIdentifierOrBool()
    {
        var start = CurrentPosition();
        var sb = new StringBuilder();
        sb.Append(Advance());
        while (!IsAtEnd() && IsIdentifierPart(Peek()))
        {
            sb.Append(Advance());
        }

        var text = sb.ToString();
        var end = CurrentPosition();
        if (text == "true" || text == "false")
        {
            return new AosToken(AosTokenKind.Bool, text, new AosSpan(start, end));
        }

        return new AosToken(AosTokenKind.Identifier, text, new AosSpan(start, end));
    }

    private AosToken? ReadNumberOrIdentifier()
    {
        var start = CurrentPosition();
        var sb = new StringBuilder();

        if (IsAtEnd())
        {
            return null;
        }

        if (Peek() == '-' || char.IsDigit(Peek()))
        {
            sb.Append(Advance());
        }
        else
        {
            return null;
        }

        while (!IsAtEnd() && IsIdentifierPart(Peek()))
        {
            sb.Append(Advance());
        }

        var text = sb.ToString();
        var endPos = CurrentPosition();

        if (IsIntLiteral(text))
        {
            return new AosToken(AosTokenKind.Int, text, new AosSpan(start, endPos));
        }

        return new AosToken(AosTokenKind.Identifier, text, new AosSpan(start, endPos));
    }

    private AosToken ReadString()
    {
        var start = CurrentPosition();
        Advance();
        var sb = new StringBuilder();
        while (!IsAtEnd())
        {
            var ch = Advance();
            if (ch == '"')
            {
                var end = CurrentPosition();
                return new AosToken(AosTokenKind.String, sb.ToString(), new AosSpan(start, end));
            }

            if (ch == '\\')
            {
                if (IsAtEnd())
                {
                    break;
                }

                var esc = Advance();
                switch (esc)
                {
                    case '"': sb.Append('"'); break;
                    case '\\': sb.Append('\\'); break;
                    case 'n': sb.Append('\n'); break;
                    case 'r': sb.Append('\r'); break;
                    case 't': sb.Append('\t'); break;
                    default:
                        _diagnostics.Add(new AosDiagnostic("TOK003", $"Invalid escape \\{esc}.", null, new AosSpan(start, CurrentPosition())));
                        sb.Append(esc);
                        break;
                }
                continue;
            }

            sb.Append(ch);
        }

        var endPos = CurrentPosition();
        _diagnostics.Add(new AosDiagnostic("TOK004", "Unterminated string literal.", null, new AosSpan(start, endPos)));
        return new AosToken(AosTokenKind.String, sb.ToString(), new AosSpan(start, endPos));
    }

    private void SkipWhitespaceAndComments()
    {
        while (!IsAtEnd())
        {
            var ch = Peek();
            if (char.IsWhiteSpace(ch))
            {
                Advance();
                continue;
            }

            if (ch == '/' && PeekNext() == '/')
            {
                Advance();
                Advance();
                while (!IsAtEnd() && Peek() != '\n')
                {
                    Advance();
                }
                continue;
            }

            break;
        }
    }

    private AosToken ConsumeSingle(AosTokenKind kind, string text)
    {
        var start = CurrentPosition();
        Advance();
        var end = CurrentPosition();
        return new AosToken(kind, text, new AosSpan(start, end));
    }

    private AosToken MakeToken(AosTokenKind kind, string text, AosPosition start, AosPosition end)
        => new(kind, text, new AosSpan(start, end));

    private char Peek() => _source[_index];

    private char PeekNext() => _index + 1 < _source.Length ? _source[_index + 1] : '\0';

    private char Advance()
    {
        var ch = _source[_index++];
        if (ch == '\n')
        {
            _line++;
            _col = 1;
        }
        else
        {
            _col++;
        }
        return ch;
    }

    private bool IsAtEnd() => _index >= _source.Length;

    private AosPosition CurrentPosition() => new(_index, _line, _col);

    private static bool IsIdentifierStart(char ch) => char.IsLetter(ch) || ch == '_';

    private static bool IsIdentifierPart(char ch) => char.IsLetterOrDigit(ch) || ch == '_' || ch == '-';

    private static bool IsIntLiteral(string text)
    {
        if (text.Length == 0)
        {
            return false;
        }

        var start = 0;
        if (text[0] == '-')
        {
            if (text.Length == 1)
            {
                return false;
            }
            start = 1;
        }

        for (var i = start; i < text.Length; i++)
        {
            if (!char.IsDigit(text[i]))
            {
                return false;
            }
        }

        return true;
    }
}
