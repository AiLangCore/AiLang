#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$runtime = Join-Path $root 'tools\aivm-runtime.exe'
$parseCheckCandidates = @(
  (Join-Path $root '.artifacts\ailang-selfhost\bin\commands\parse-check.aibc1'),
  (Join-Path $root '.artifacts\ailang-builtins\parse-check.aibc1'),
  (Join-Path $root '.artifacts\ailang-bootstrap\commands\parse-check.aibc1')
)

if (-not (Test-Path $runtime -PathType Leaf)) {
  throw 'self-hosted parser corpus failed: missing tools\aivm-runtime.exe'
}
$parseCheck = $parseCheckCandidates |
  Where-Object { Test-Path $_ -PathType Leaf } |
  Select-Object -First 1
if (-not $parseCheck) {
  throw 'self-hosted parser corpus failed: missing compiled parse-check command'
}

$sourceRoots = @('examples', 'samples', 'src\std', 'src\compiler', 'src\cli', 'templates') |
  ForEach-Object { Join-Path $root $_ } |
  Where-Object { Test-Path $_ -PathType Container }
$sourceFiles = $sourceRoots |
  ForEach-Object { Get-ChildItem $_ -Recurse -Force -File -Filter '*.aos' } |
  Where-Object { $_.Name -notlike '*.out.aos' -and $_.FullName -notmatch '[\\/]\.tmp[\\/]' } |
  Sort-Object FullName

function Invoke-ParseCheckPath([string] $sourcePath) {
  $parseOutput = & $runtime run $parseCheck -- parse-check $sourcePath 2>&1
  if ($LASTEXITCODE -ne 0) {
    $artifactHash = (Get-FileHash -Algorithm SHA256 $parseCheck).Hash.ToLowerInvariant()
    $sourceHash = (Get-FileHash -Algorithm SHA256 $sourcePath).Hash.ToLowerInvariant()
    throw "self-hosted parser corpus failed: $sourcePath status=$LASTEXITCODE artifactSha256=$artifactHash sourceSha256=$sourceHash output=$($parseOutput | Out-String)"
  }
}

$probeDir = Join-Path $root '.tmp\canonical-formatting-windows'
$probePath = Join-Path $probeDir 'probe.aos'
New-Item -ItemType Directory -Force $probeDir | Out-Null
[IO.File]::WriteAllText($probePath, 'Program { Lit(value=1) }', [Text.UTF8Encoding]::new($false))
Invoke-ParseCheckPath $probePath

foreach ($sourceFile in $sourceFiles) {
  Invoke-ParseCheckPath $sourceFile.FullName
}

$invalidPath = Join-Path $probeDir 'invalid.aos'
Set-Content -NoNewline -Encoding utf8 $invalidPath 'not-an-aos-document'
$invalidOutput = & $runtime run $parseCheck -- parse-check $invalidPath 2>&1
if ($LASTEXITCODE -eq 0) {
  throw 'self-hosted parser corpus failed: parse-check accepted invalid AOS'
}
if (($invalidOutput | Out-String) -notmatch 'code=AILANG022') {
  throw 'self-hosted parser corpus failed: missing AILANG022 diagnostic'
}

Write-Host "self-hosted parser corpus: PASS ($($sourceFiles.Count) files)"
exit 0
