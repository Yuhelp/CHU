<#
.SYNOPSIS
    GPO Module 4 : Composants Windows

.DESCRIPTION
    Désactive ou configure les composants Windows non nécessaires
    - OneDrive
    - Windows Store
    - Cortana et Recherche
    - Widgets et Nouvelles
    - Windows Ink
    - Jeux (GameDVR, Explorateur de jeux)
    - Messagerie

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.EXAMPLE
    .\GPO-04-WindowsComponents.ps1 -GPOName "W11_Components" -DomainName "chu-angers.intra"
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
Write-Host " Module 4 : Composants Windows" -ForegroundColor Cyan
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

Write-Host "[1/7] Désactivation de OneDrive..." -ForegroundColor Yellow

Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -ValueName "DisableFileSyncNGSC" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -ValueName "PreventNetworkTrafficPreUserSignIn" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  OneDrive désactivé." -ForegroundColor Green

Write-Host "[2/7] Désactivation du Windows Store..." -ForegroundColor Yellow

Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" -ValueName "RemoveWindowsStore" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" -ValueName "AutoDownload" -Type DWord -Value 4 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" -ValueName "AllowSharedUserAppData" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ValueName "NoUseStoreOpenWith" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Windows Store désactivé." -ForegroundColor Green

Write-Host "[3/7] Désactivation de Cortana et Recherche..." -ForegroundColor Yellow

Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "AllowCortana" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "AllowCortanaAboveLock" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "AllowCloudSearch" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "AllowSearchToUseLocation" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "DisableWebSearch" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "ConnectedSearchUseWeb" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Cortana et Recherche désactivés." -ForegroundColor Green

Write-Host "[4/7] Désactivation des Widgets et Nouvelles..." -ForegroundColor Yellow

Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Dsh" -ValueName "AllowNewsAndInterests" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -ValueName "EnableFeeds" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Widgets et Nouvelles désactivés." -ForegroundColor Green

Write-Host "[5/7] Désactivation de Windows Ink..." -ForegroundColor Yellow

Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" -ValueName "AllowWindowsInkWorkspace" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" -ValueName "AllowSuggestedAppsInWindowsInkWorkspace" -Type DWord -Value 0 -Domain $DomainName

# Désactiver le partage des données de personnalisation de l'écriture manuscrite
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" -ValueName "PreventHandwritingDataSharing" -Type DWord -Value 1 -Domain $DomainName

# Désactiver le signalement d'erreurs de la reconnaissance de l'écriture manuscrite
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" -ValueName "PreventHandwritingErrorReports" -Type DWord -Value 1 -Domain $DomainName

# Apprentissage automatique écriture manuscrite = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" -ValueName "RestrictImplicitInkCollection" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" -ValueName "RestrictImplicitTextCollection" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Windows Ink désactivé." -ForegroundColor Green

Write-Host "[6/7] Désactivation des fonctionnalités de jeux..." -ForegroundColor Yellow

# Enregistrement et diffusion de jeux
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -ValueName "AllowGameDVR" -Type DWord -Value 0 -Domain $DomainName

# Explorateur de jeux
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameUX" -ValueName "DownloadGameInfo" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameUX" -ValueName "GameUpdateOptions" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Fonctionnalités de jeux désactivées." -ForegroundColor Green

Write-Host "[7/7] Configuration des autres composants..." -ForegroundColor Yellow

# Messagerie
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Messaging" -ValueName "AllowMessageSync" -Type DWord -Value 0 -Domain $DomainName

# OOBE
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE" -ValueName "DisablePrivacyExperience" -Type DWord -Value 1 -Domain $DomainName

# Environnement distant Windows
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "EnableCdp" -Type DWord -Value 1 -Domain $DomainName

# Plateforme de protection de licence logicielle
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" -ValueName "NoGenTicket" -Type DWord -Value 1 -Domain $DomainName

# Processus d'ajout de fonctionnalités à Windows
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudExperienceHost" -ValueName "DisableCloudOptimizedContent" -Type DWord -Value 1 -Domain $DomainName

# Groupe résidentiel
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\HomeGroup" -ValueName "DisableHomeGroup" -Type DWord -Value 1 -Domain $DomainName

# Service Digital Locker
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Digital Locker" -ValueName "DoNotRunDigitalLocker" -Type DWord -Value 0 -Domain $DomainName

# Reconnaissance vocale en ligne = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" -ValueName "AllowInputPersonalization" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Autres composants configurés." -ForegroundColor Green
Write-Host ""
Write-Host "Module 4 terminé avec succès." -ForegroundColor Green
