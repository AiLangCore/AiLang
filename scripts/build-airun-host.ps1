#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ref = if ($env:AIVM_LEGACY_HOST_REF) { $env:AIVM_LEGACY_HOST_REF } else { 'origin/develop' }
$tmpDir = Join-Path $root '.tmp/legacy-host-src'
$outDir = Join-Path $root '.tmp/legacy-host-build'
$hostPath = Join-Path $root 'tools/airun-host.exe'

if (Test-Path $hostPath) {
  Write-Host "using existing backend host: $hostPath"
  exit 0
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
  throw 'dotnet SDK is required to build legacy backend host'
}

New-Item -ItemType Directory -Force -Path (Join-Path $root '.tmp') | Out-Null
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir }
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$null = & git rev-parse --verify --quiet "$ref^`{commit`}" 2>$null
if ($LASTEXITCODE -ne 0) {
  & git fetch origin develop --depth=1 | Out-Null
  $null = & git rev-parse --verify --quiet "$ref^`{commit`}" 2>$null
  if ($LASTEXITCODE -ne 0) {
    throw "unable to resolve legacy host ref: $ref"
  }
}

Push-Location $root
try {
  & git archive $ref src/AiCLI src/AiLang.Core src/AiVM.Core src/compiler | tar -x -C $tmpDir
} finally {
  Pop-Location
}

$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
& dotnet publish (Join-Path $tmpDir 'src/AiCLI/AiCLI.csproj') -c Release -o $outDir | Out-Null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$candidateExe = Join-Path $outDir 'airun.exe'
$candidateNoExt = Join-Path $outDir 'airun'
if (Test-Path $candidateExe) {
  Copy-Item $candidateExe $hostPath -Force
} elseif (Test-Path $candidateNoExt) {
  Copy-Item $candidateNoExt $hostPath -Force
} else {
  throw 'legacy host build succeeded but airun executable missing'
}

Write-Host "built backend host: $hostPath"
