<#
.SYNOPSIS
    GPO Module 9 : Gestion à Distance

.DESCRIPTION
    Configure les outils de gestion à distance
    - WinRM (Windows Remote Management)
    - Bureau à distance (RDP)
    - Assistance à distance

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.EXAMPLE
    .\GPO-09-RemoteManagement.ps1 -GPOName "W11_RemoteMgmt" -DomainName "chu-angers.intra"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$GPOName,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainName
)

#Requires -Modules GroupPolicy

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Module 9 : Gestion à Distance" -ForegroundColor Cyan
Write-Host " GPO : $GPOName" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

try {
    $GPO = Get-GPO -Name $GPOName -Domain $DomainName -ErrorAction Stop
    Write-Host "GPO trouvée : $($GPO.DisplayName)" -ForegroundColor Green
} catch {
    Write-Error "GPO '$GPOName' introuvable. Créez-la d'abord."
    exit 1
}

Write-Host "[1/3] Configuration de WinRM..." -ForegroundColor Yellow

# WinRM - Autoriser l'authentification de base
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" -ValueName "AllowBasic" -Type DWord -Value 1 -Domain $DomainName

# WinRM - Autoriser la configuration automatique
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" -ValueName "AllowAutoConfig" -Type DWord -Value 1 -Domain $DomainName

# WinRM - Filtre IPv4
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" -ValueName "IPv4Filter" -Type String -Value "*" -Domain $DomainName

Write-Host "  WinRM configuré." -ForegroundColor Green

Write-Host "[2/3] Configuration du Bureau à distance..." -ForegroundColor Yellow

# Autoriser les connexions à distance (0 = autoriser, 1 = refuser)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fDenyTSConnections" -Type DWord -Value 0 -Domain $DomainName

# Forcer la suppression du papier peint du Bureau à distance
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fNoWallpaper" -Type DWord -Value 1 -Domain $DomainName

# Limiter le nombre maximal de couleurs = Compatible avec le client (4)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "ColorDepth" -Type DWord -Value 4 -Domain $DomainName

Write-Host "  Bureau à distance configuré." -ForegroundColor Green

Write-Host "[3/3] Désactivation de l'Assistance à distance..." -ForegroundColor Yellow

# Assistance à distance sollicitée = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fAllowToGetHelp" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Assistance à distance désactivée." -ForegroundColor Green
Write-Host ""
Write-Host "Module 9 terminé avec succès." -ForegroundColor Green
