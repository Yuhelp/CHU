<#
.SYNOPSIS
    GPO Module 2 : Confidentialité et Télémétrie

.DESCRIPTION
    Désactive la collecte de données et la télémétrie Microsoft
    - Données de diagnostic
    - Télémétrie Windows
    - Biométrie
    - Cartes
    - Compatibilité des applications
    - Contenu cloud

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.EXAMPLE
    .\GPO-02-Privacy-Telemetry.ps1 -GPOName "W11_Privacy" -DomainName "chu-angers.intra"
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
Write-Host " Module 2 : Confidentialité et Télémétrie" -ForegroundColor Cyan
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

Write-Host "[1/5] Désactivation de la collecte de données et télémétrie..." -ForegroundColor Yellow

# Autoriser les données de diagnostic = Désactivé (0)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "AllowTelemetry" -Type DWord -Value 0 -Domain $DomainName

# Autoriser le pipeline de données commerciales = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "AllowCommercialDataPipeline" -Type DWord -Value 0 -Domain $DomainName

# Autoriser l'envoi du nom de l'appareil = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "AllowDeviceNameInTelemetry" -Type DWord -Value 0 -Domain $DomainName

# Basculer le contrôle utilisateur sur les builds Insider = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -ValueName "AllowBuildPreview" -Type DWord -Value 0 -Domain $DomainName

# Configurer proxy télémétrie (trou noir local)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "TelemetryProxyServer" -Type String -Value "127.0.0.1:8085" -Domain $DomainName

# Configurer l'ID commercial = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "CommercialId" -Type String -Value "" -Domain $DomainName

# Configurer l'utilisation du proxy authentifié = Désactiver proxy auth
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "DisableEnterpriseAuthProxy" -Type DWord -Value 1 -Domain $DomainName

# Configurer la collecte des données de navigation pour Analyses du bureau = Ne pas autoriser
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "MicrosoftEdgeDataOptIn" -Type DWord -Value 0 -Domain $DomainName

# Désactiver la visionneuse de données de diagnostic
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "DisableDiagnosticDataViewer" -Type DWord -Value 0 -Domain $DomainName

# Désactiver les téléchargements OneSettings = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "DisableOneSettingsDownloads" -Type DWord -Value 1 -Domain $DomainName

# Ne pas afficher les notifications de commentaire = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "DoNotShowFeedbackNotifications" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Télémétrie désactivée." -ForegroundColor Green

Write-Host "[2/5] Désactivation de la biométrie..." -ForegroundColor Yellow

# Autoriser l'utilisation de la biométrie = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Biometrics" -ValueName "Enabled" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Biométrie désactivée." -ForegroundColor Green

Write-Host "[3/5] Désactivation des cartes et localisation..." -ForegroundColor Yellow

# Désactiver le téléchargement automatique des données cartographiques = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps" -ValueName "AutoDownloadAndUpdateMapData" -Type DWord -Value 0 -Domain $DomainName

# Désactiver le trafic réseau non sollicité sur la page Paramètres des cartes hors connexion = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps" -ValueName "AllowUntriggeredNetworkTrafficOnSettingsPage" -Type DWord -Value 0 -Domain $DomainName

# Désactiver la localisation
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -ValueName "DisableLocation" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -ValueName "DisableLocationScripting" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -ValueName "DisableSensors" -Type DWord -Value 1 -Domain $DomainName

# Localiser mon appareil = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" -ValueName "AllowFindMyDevice" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Cartes et localisation désactivées." -ForegroundColor Green

Write-Host "[4/5] Désactivation de la compatibilité des applications..." -ForegroundColor Yellow

# Désactiver l'Inventory Collector = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -ValueName "DisableInventory" -Type DWord -Value 1 -Domain $DomainName

# Désactiver la télémétrie applicative = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -ValueName "AITEnable" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Compatibilité des applications configurée." -ForegroundColor Green

Write-Host "[5/5] Désactivation du contenu cloud et compte Microsoft..." -ForegroundColor Yellow

# Bloquer toute authentification utilisateur au compte Microsoft client = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftAccount" -ValueName "DisableUserAuth" -Type DWord -Value 1 -Domain $DomainName

# Désactiver le contenu optimisé pour le cloud = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -ValueName "DisableCloudOptimizedContent" -Type DWord -Value 1 -Domain $DomainName

# Désactiver les expériences consommateur de Microsoft = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -ValueName "DisableWindowsConsumerFeatures" -Type DWord -Value 1 -Domain $DomainName

# Ne pas afficher les conseils de Windows = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -ValueName "DisableSoftLanding" -Type DWord -Value 1 -Domain $DomainName

# Désactiver l'ID de publicité
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -ValueName "DisabledByGroupPolicy" -Type DWord -Value 1 -Domain $DomainName

# Programme d'amélioration de l'expérience utilisateur
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -ValueName "CEIPEnable" -Type DWord -Value 0 -Domain $DomainName

# Rapport d'erreurs Windows
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -ValueName "Disabled" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -ValueName "DontSendAdditionalData" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Contenu cloud et compte Microsoft désactivés." -ForegroundColor Green
Write-Host ""
Write-Host "Module 2 terminé avec succès." -ForegroundColor Green
