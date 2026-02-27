<#
.SYNOPSIS
    Déploie un LayoutModification.json pour le menu Démarrer via GPO.

.DESCRIPTION
    Copie un fichier LayoutModification.json vers le partage SYSVOL de la GPO
    et configure la stratégie "Start Layout" pour Windows 11.

.NOTES
    - Nécessite RSAT + module GroupPolicy.
    - Utilise le GPOName fourni (par défaut _OU_Computers_CHU_ALL_W11).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$GPOName = "_OU_Computers_CHU_ALL_W11",
    [string]$DomainName = "chu-angers.intra",
    [string]$LayoutJsonPath = "./LayoutModification.json"
)

#Requires -Modules GroupPolicy

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $LayoutJsonPath)) {
    throw "LayoutModification.json introuvable: $LayoutJsonPath"
}

$gpo = Get-GPO -Name $GPOName -Domain $DomainName -ErrorAction Stop

$gpoId = $gpo.Id.ToString("B")
$sysvolRoot = "\\$DomainName\\SYSVOL\\$DomainName\\Policies"
$gpoSysvolPath = Join-Path $sysvolRoot $gpoId
$destinationDir = Join-Path $gpoSysvolPath "Machine\\Scripts"
$destinationPath = Join-Path $destinationDir "LayoutModification.json"

if (-not (Test-Path -LiteralPath $destinationDir)) {
    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
}

Copy-Item -LiteralPath $LayoutJsonPath -Destination $destinationPath -Force

# Configure "Start Layout" policy (Computer Configuration)
Set-GPRegistryValue -Guid $gpo.Id -Key "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer" -ValueName "StartLayoutFile" -Type String -Value $destinationPath -Domain $DomainName
Set-GPRegistryValue -Guid $gpo.Id -Key "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer" -ValueName "LockedStartLayout" -Type DWord -Value 1 -Domain $DomainName

Write-Host "Layout appliqué dans la GPO $GPOName" -ForegroundColor Green
Write-Host "JSON copié vers: $destinationPath" -ForegroundColor Green
