# AiLang

AiLang is a small experimental language with an AI-optimized syntax (AOS) and a REPL protocol based on explicit AST nodes. The core library provides a tokenizer, parser, validator, interpreter, patch ops, and a canonical formatter.

## Quick Start

Build and run the REPL:

```bash
dotnet build AiLang.slnx
./src/AiLang.Cli/bin/Debug/net10.0/airun repl
```

Load a program and evaluate expressions:

```text
Cmd#c1(name=load) { Program#p1 { Let#l1(name=x) { Lit#v1(value=1) } } }
Cmd#c2(name=eval) { Call#c3(target=math.add) { Var#v2(name=x) Lit#v3(value=2) } }
```

## Permissions

Capabilities are gated by permissions:

- `math.add` is pure and allowed by default.
- `console.print` is effectful and denied by default.

Enable console output in the REPL:

```text
Cmd#c9(name=setPerms allow=console,math)
```

## REPL Transcript (Example)

```text
Cmd#c1(name=help)
Ok#ok1(type=string value="Cmd(name=help|setPerms|load|eval|applyPatch)")
Cmd#c2(name=setPerms allow=console,math)
Ok#ok2(type=void)
Cmd#c3(name=load) { Program#p1 { Let#l1(name=message) { Lit#s1(value="hi") } Call#c1(target=console.print) { Var#v1(name=message) } } }
Ok#ok3(type=void)
Cmd#c4(name=eval) { Call#c2(target=math.add) { Lit#a1(value=2) Lit#a2(value=3) } }
Ok#ok4(type=int value=5)
```

## Examples

See `examples/hello.aos` for a full program using `console.print`.
