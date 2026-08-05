$ErrorActionPreference = 'Stop'

function Show-Usage {
  @'
Usage: ./build.ps1 [selfhost|legacy|shared|wasm|all]

Builds AiLang tooling through the selected installed SDK.

Targets:
  selfhost
          Build the AiLang compiler and CLI (default).
          Module generation uses AiVM's capacity-derived worker scheduler.
          Override its profile ceiling with AILANG_SELFHOST_MAX_JOBS.
  legacy  Build the deprecated native C AiLang bootstrap launcher.
  shared  Delegated to AiVM; kept temporarily for migration compatibility.
  wasm    Delegated to AiVM; kept temporarily for migration compatibility.
  all     Build self-hosted tools, then delegated compatibility targets.
'@
}

function Get-ProjectToolchain {
  $dir = $PSScriptRoot
  while ($true) {
    $toml = Join-Path $dir 'ailang-toolchain.toml'
    if (Test-Path $toml) {
      $match = Select-String -Path $toml -Pattern '^\s*version\s*=\s*"([^"]+)"' | Select-Object -First 1
      if ($match) { return $match.Matches[0].Groups[1].Value }
    }
    $legacy = Join-Path $dir '.ailang-toolchain'
    if (Test-Path $legacy) {
      return ((Get-Content $legacy -TotalCount 1) -as [string]).Trim()
    }
    $parent = Split-Path $dir -Parent
    if ($parent -eq $dir) { return '' }
    $dir = $parent
  }
}

function Invoke-StageInstalledToolchain {
  $installRoot = if ($env:AILANG_INSTALL_ROOT) { $env:AILANG_INSTALL_ROOT } else { Join-Path $HOME '.ailang' }
  $selected = if ($env:AILANG_TOOLCHAIN) { $env:AILANG_TOOLCHAIN } else { Get-ProjectToolchain }
  if ($selected) {
    if ($selected -eq 'local') {
      $sdkRoot = Join-Path $installRoot 'local'
    } else {
      $sdkRoot = Join-Path (Join-Path $installRoot 'toolchains') $selected
    }
  } else {
    $sdkRoot = Join-Path $installRoot 'current'
  }
  $sdkBin = Join-Path $sdkRoot 'bin'
  $toolsDir = Join-Path $PSScriptRoot 'tools'
  $allowLegacyBootstrap = $env:AILANG_ALLOW_LEGACY_BOOTSTRAP_SDK -eq '1'
  $ailang = Join-Path $sdkBin 'ailang.exe'
  if (-not (Test-Path $ailang)) {
    $ailang = Join-Path $sdkBin 'ailang'
  }
  if ((-not (Test-Path $ailang)) -and $allowLegacyBootstrap) {
    $ailang = Join-Path $sdkRoot 'ailang.exe'
    if (-not (Test-Path $ailang)) {
      $ailang = Join-Path $sdkRoot 'ailang'
    }
  }
  if (-not (Test-Path $ailang)) {
    if ($allowLegacyBootstrap) {
      throw "selected AiLang SDK is missing bin/ailang or legacy bootstrap ailang: $sdkRoot"
    }
    throw "selected AiLang SDK is missing bin/ailang: $sdkRoot. Set AILANG_ALLOW_LEGACY_BOOTSTRAP_SDK=1 only when bootstrapping from a pre-bin-layout alpha SDK."
  }
  New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
  Copy-Item $ailang (Join-Path $toolsDir 'ailang.exe') -Force
  Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $toolsDir 'airun.exe'), (Join-Path $toolsDir 'airun')
  $runtime = Join-Path $sdkBin 'aivm-runtime.exe'
  if (-not (Test-Path $runtime)) { $runtime = Join-Path $sdkBin 'aivm-runtime' }
  if ((-not (Test-Path $runtime)) -and $allowLegacyBootstrap) {
    $runtime = Join-Path $sdkRoot 'aivm-runtime.exe'
    if (-not (Test-Path $runtime)) { $runtime = Join-Path $sdkRoot 'aivm-runtime' }
  }
  if (Test-Path $runtime) {
    Copy-Item $runtime (Join-Path $toolsDir 'aivm-runtime.exe') -Force
  }
  $sdkArtifacts = Join-Path $sdkRoot '.artifacts'
  if (Test-Path $sdkArtifacts) {
    $repoArtifacts = Join-Path $PSScriptRoot '.artifacts'
    New-Item -ItemType Directory -Force -Path $repoArtifacts | Out-Null
    Copy-Item -Path (Join-Path $sdkArtifacts '*') -Destination $repoArtifacts -Recurse -Force
  }
  Write-Host "Staged AiLang tools from installed SDK: $sdkRoot"
}

function Invoke-BuildTarget([string]$Target) {
  switch ($Target) {
    'legacy' {
      & "$PSScriptRoot/scripts/build-ailang-native.ps1"
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
      bash "$PSScriptRoot/scripts/build-ailang-builtins.sh"
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    'selfhost' {
      $bootstrap = Join-Path $PSScriptRoot 'tools/ailang.exe'
      $runtime = Join-Path $PSScriptRoot 'tools/aivm-runtime.exe'
      if (-not (Test-Path $bootstrap) -or -not (Test-Path $runtime)) {
        try {
          Invoke-StageInstalledToolchain
          Write-Host 'selfhost-bootstrap=installed-sdk'
        } catch {
          Write-Host 'selfhost-bootstrap=legacy reason=installed-sdk-unavailable'
          Invoke-BuildTarget 'legacy'
        }
      }
      $aivmSource = Join-Path (Split-Path $PSScriptRoot -Parent) 'AiVM/src'
      if ((Test-Path $runtime) -and (Test-Path $aivmSource)) {
        $runtimeTime = (Get-Item $runtime).LastWriteTimeUtc
        $staleSource = Get-ChildItem $aivmSource -Recurse -File |
          Where-Object {
            ($_.Extension -eq '.c' -or $_.Extension -eq '.h') -and
            $_.LastWriteTimeUtc -gt $runtimeTime
          } |
          Select-Object -First 1
        if ($staleSource) {
          Write-Host 'selfhost-bootstrap=legacy reason=stale-bootstrap-runtime'
          Invoke-BuildTarget 'legacy'
        }
      }
      bash "$PSScriptRoot/scripts/build-ailang-selfhost.sh"
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
      Invoke-BuildTarget 'selfhost'
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

$target = if ($args.Length -gt 0) { $args[0] } else { 'selfhost' }
Invoke-BuildTarget $target
