<#
.SYNOPSIS
    GPO Module 8 : Windows Defender et SmartScreen

.DESCRIPTION
    Configure Windows Defender et SmartScreen
    - Désactivation de Windows Defender
    - Configuration MAPS
    - Quarantaine
    - SmartScreen

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.EXAMPLE
    .\GPO-08-Defender-SmartScreen.ps1 -GPOName "W11_Defender" -DomainName "chu-angers.intra"
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
Write-Host " Module 8 : Windows Defender et SmartScreen" -ForegroundColor Cyan
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

Write-Host "[1/3] Configuration de Windows Defender..." -ForegroundColor Yellow

# Désactiver l'antivirus Microsoft Defender = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" -ValueName "DisableAntiSpyware" -Type DWord -Value 1 -Domain $DomainName

# MAPS - Envoyer des exemples de fichier = Toujours demander (1)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -ValueName "SubmitSamplesConsent" -Type DWord -Value 1 -Domain $DomainName

# MAPS - Rejoindre Microsoft MAPS = Désactivé (0)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -ValueName "SpynetReporting" -Type DWord -Value 0 -Domain $DomainName

# Quarantaine - Suppression des éléments après 30 jours
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Quarantine" -ValueName "PurgeItemsAfterDelay" -Type DWord -Value 30 -Domain $DomainName

# NIS - Activer la reconnaissance de protocole = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\NIS" -ValueName "DisableProtocolRecognition" -Type DWord -Value 0 -Domain $DomainName

# NIS - Activer le retrait de définition = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\NIS\Consumers\IPS" -ValueName "EnableSignatureRetirement" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Windows Defender configuré." -ForegroundColor Green

Write-Host "[2/3] Configuration de SmartScreen..." -ForegroundColor Yellow

# Windows Defender SmartScreen = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "EnableSmartScreen" -Type DWord -Value 0 -Domain $DomainName

# SmartScreen Explorer - Contrôle d'installation des applications = Désactiver les recommandations
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" -ValueName "ConfigureAppInstallControlEnabled" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" -ValueName "ConfigureAppInstallControl" -Type String -Value "Anywhere" -Domain $DomainName

Write-Host "  SmartScreen configuré." -ForegroundColor Green

Write-Host "[3/3] Configuration du Centre de sécurité..." -ForegroundColor Yellow

# Activer le Centre de sécurité (domaine) = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Security Center" -ValueName "FirstRunDisabled" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Centre de sécurité configuré." -ForegroundColor Green
Write-Host ""
Write-Host "Module 8 terminé avec succès." -ForegroundColor Green
