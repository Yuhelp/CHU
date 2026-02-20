<#
.SYNOPSIS
    GPO Module 7 : Windows Update

.DESCRIPTION
    Configure Windows Update pour utiliser WSUS
    - Désactivation des mises à jour automatiques
    - Report des mises à jour (qualité: 30j, fonctionnalités: 365j)
    - Notifications de redémarrage
    - Blocage de l'accès Windows Update Internet

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.EXAMPLE
    .\GPO-07-WindowsUpdate.ps1 -GPOName "W11_WindowsUpdate" -DomainName "chu-angers.intra"
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
Write-Host " Module 7 : Windows Update" -ForegroundColor Cyan
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

Write-Host "[1/4] Désactivation des mises à jour automatiques..." -ForegroundColor Yellow

# Configuration du service Mises à jour automatiques = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "NoAutoUpdate" -Type DWord -Value 1 -Domain $DomainName

# Supprimer l'accès à toutes les fonctionnalités de Windows Update = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "SetDisableUXWUAccess" -Type DWord -Value 1 -Domain $DomainName

# Désactiver l'accès à toutes les fonctionnalités Windows Update
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DisableWindowsUpdateAccess" -Type DWord -Value 1 -Domain $DomainName

# Ne pas se connecter à des emplacements Internet Windows Update = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DoNotConnectToWindowsUpdateInternetLocations" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Mises à jour automatiques désactivées." -ForegroundColor Green

Write-Host "[2/4] Configuration des notifications..." -ForegroundColor Yellow

# Options d'affichage des notifications de mise à jour = 1 (désactiver toutes sauf avertissements redémarrage)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "SetUpdateNotificationLevel" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "UpdateNotificationLevel" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Notifications configurées." -ForegroundColor Green

Write-Host "[3/4] Configuration du report des mises à jour..." -ForegroundColor Yellow

# Mises à jour qualité - Différer de 30 jours
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DeferQualityUpdates" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DeferQualityUpdatesPeriodInDays" -Type DWord -Value 30 -Domain $DomainName

# Mises à jour de fonctionnalités - Différer de 365 jours
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DeferFeatureUpdates" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365 -Domain $DomainName

# BranchReadinessLevel
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "BranchReadinessLevel" -Type DWord -Value 16 -Domain $DomainName

# ManagePreviewBuilds
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ManagePreviewBuilds" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ManagePreviewBuildsPolicyValue" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Report des mises à jour configuré." -ForegroundColor Green

Write-Host "[4/4] Configuration des redémarrages..." -ForegroundColor Yellow

# Redemander un redémarrage toutes les 45 minutes
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "RebootRelaunchTimeoutEnabled" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "RebootRelaunchTimeout" -Type DWord -Value 45 -Domain $DomainName

# Date d'échéance redémarrage = 7 jours pour mises à jour qualité
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ConfigureDeadlineForQualityUpdates" -Type DWord -Value 7 -Domain $DomainName

# Toujours redémarrer automatiquement à l'heure planifiée = 30 minutes
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AlwaysAutoRebootAtScheduledTime" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AlwaysAutoRebootAtScheduledTimeMinutes" -Type DWord -Value 30 -Domain $DomainName

Write-Host "  Redémarrages configurés." -ForegroundColor Green
Write-Host ""
Write-Host "Module 7 terminé avec succès." -ForegroundColor Green
