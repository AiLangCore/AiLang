$ErrorActionPreference = 'Stop'

function Show-Usage {
  @'
Usage: ./build.ps1 [host|shared|wasm|all]

Builds AiLang tooling through one canonical bootstrap entrypoint.

Targets:
  host    Build host-native tools (default).
  shared  Build the shared AiVM native library.
  wasm    Build wasm runtime artifacts.
  all     Build host tools, shared library, and wasm artifacts.
'@
}

function Invoke-BuildTarget([string]$Target) {
  switch ($Target) {
    'host' {
      & "$PSScriptRoot/scripts/build-airun.ps1"
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    'shared' {
      bash "$PSScriptRoot/scripts/build-aivm-c-shared.sh"
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    'wasm' {
      bash "$PSScriptRoot/scripts/build-aivm-wasm.sh"
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    'all' {
      Invoke-BuildTarget 'host'
      Invoke-BuildTarget 'shared'
      Invoke-BuildTarget 'wasm'
    }
    'help' { Show-Usage }
    '--help' { Show-Usage }
    '-h' { Show-Usage }
    default {
      Write-Error "unknown build target: $Target"
      Show-Usage | Write-Host
      exit 1
    }
  }
}

$target = if ($args.Length -gt 0) { $args[0] } else { 'host' }
Invoke-BuildTarget $target
