#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

& ./scripts/test-aivm-c.ps1
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$hasEmcc = [bool](Get-Command emcc -ErrorAction SilentlyContinue)
$hasWasmtime = [bool](Get-Command wasmtime -ErrorAction SilentlyContinue)
if ($hasEmcc -and $hasWasmtime) {
  $bashForWasm = Get-Command bash -ErrorAction SilentlyContinue
  if (-not $bashForWasm) {
    throw 'bash is required to run scripts/test-wasm-golden.sh when emcc+wasmtime are available'
  }
  & bash ./scripts/test-wasm-golden.sh
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} else {
  Write-Host 'skipping wasm golden tests: emcc and/or wasmtime not found'
}

$report = Join-Path $root '.tmp/aivm-parity-dashboard-ci.md'
$bash = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bash) {
  throw 'bash is required to run scripts/aivm-parity-dashboard.sh'
}

$env:AIVM_DOD_RUN_TESTS = '0'
$env:AIVM_DOD_RUN_BENCH = '0'
& bash ./scripts/aivm-parity-dashboard.sh $report
exit $LASTEXITCODE
