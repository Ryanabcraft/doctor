param(
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$marketplaceName = "ryan-plugins"
$preferredPluginName = 'project-dotcor@ryan-plugins'
$pluginSlug = "project-dotcor"
$repoUrl = "https://github.com/Ryanabcraft/project-dotcor-marketplace.git"
$codexDir = Join-Path $env:USERPROFILE ".codex"
$configPath = Join-Path $codexDir "config.toml"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = "$configPath.bak-$timestamp"

function Add-BlockIfMissing {
  param(
    [string]$Content,
    [string]$Header,
    [string]$Block
  )

  if ($Content -match [regex]::Escape($Header)) {
    return $Content
  }

  if ([string]::IsNullOrWhiteSpace($Content)) {
    return $Block.Trim() + [Environment]::NewLine
  }

  return $Content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $Block.Trim() + [Environment]::NewLine
}

function Get-EnabledProjectDotcorPlugin {
  param([string]$Content)

  $matches = [regex]::Matches($Content, '(?ms)^\[plugins\."(project-dotcor@[^"]+)"\]\s*enabled\s*=\s*true\s*$')
  if ($matches.Count -gt 0) {
    return $matches[0].Groups[1].Value
  }

  return $null
}

Write-Host ""
Write-Host "Project Dotcor installer" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Cyan

if (!(Test-Path -Path $codexDir)) {
  Write-Host "Criando pasta: $codexDir"
  if (!$DryRun) {
    New-Item -ItemType Directory -Force -Path $codexDir | Out-Null
  }
}

$current = ""
if (Test-Path -Path $configPath) {
  $current = Get-Content -Raw -Path $configPath
  Write-Host "Config encontrado: $configPath"
} else {
  Write-Host "Config ainda nao existe, vou criar: $configPath"
}

$alreadyEnabledPlugin = Get-EnabledProjectDotcorPlugin -Content $current

if ($alreadyEnabledPlugin) {
  Write-Host "Project Dotcor ja esta instalado e ativado como: $alreadyEnabledPlugin" -ForegroundColor Green
  Write-Host "Nao vou duplicar a entrada do plugin."
  $updated = $current
} else {
  $marketplaceBlock = @"
[marketplaces.$marketplaceName]
source_type = "git"
source = "$repoUrl"
"@

  $pluginBlock = @"
[plugins."$preferredPluginName"]
enabled = true
"@

  $updated = Add-BlockIfMissing -Content $current -Header "[marketplaces.$marketplaceName]" -Block $marketplaceBlock
  $updated = Add-BlockIfMissing -Content $updated -Header "[plugins.`"$preferredPluginName`"]" -Block $pluginBlock
}

if ($updated -eq $current -and (Test-Path -Path $configPath)) {
  Write-Host "Nenhuma alteracao necessaria." -ForegroundColor Green
} else {
  if (Test-Path -Path $configPath) {
    Write-Host "Backup: $backupPath"
    if (!$DryRun) {
      Copy-Item -Force -Path $configPath -Destination $backupPath
    }
  }

  Write-Host "Atualizando config.toml..."
  if (!$DryRun) {
    Set-Content -Path $configPath -Value $updated -Encoding UTF8
  }
}

Write-Host ""
Write-Host "Instalacao concluida." -ForegroundColor Green
Write-Host "Agora feche e abra o Codex, depois procure por Project Dotcor em Plugins."
Write-Host ""
