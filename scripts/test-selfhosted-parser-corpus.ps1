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
  ForEach-Object { Get-ChildItem $_ -Recurse -File -Filter '*.aos' } |
  Where-Object { $_.Name -notlike '*.out.aos' -and $_.FullName -notmatch '[\\/]\.tmp[\\/]' } |
  Sort-Object FullName

foreach ($sourceFile in $sourceFiles) {
  & $runtime run $parseCheck -- parse-check $sourceFile.FullName | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "self-hosted parser corpus failed: $($sourceFile.FullName) status=$LASTEXITCODE"
  }
}

$invalidDir = Join-Path $root '.tmp\canonical-formatting-windows'
$invalidPath = Join-Path $invalidDir 'invalid.aos'
New-Item -ItemType Directory -Force $invalidDir | Out-Null
Set-Content -NoNewline -Encoding utf8 $invalidPath 'not-an-aos-document'
$invalidOutput = & $runtime run $parseCheck -- parse-check $invalidPath 2>&1
if ($LASTEXITCODE -eq 0) {
  throw 'self-hosted parser corpus failed: parse-check accepted invalid AOS'
}
if (($invalidOutput | Out-String) -notmatch 'code=AILANG022') {
  throw 'self-hosted parser corpus failed: missing AILANG022 diagnostic'
}

Write-Host "self-hosted parser corpus: PASS ($($sourceFiles.Count) files)"
