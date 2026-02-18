<#
.SYNOPSIS
    GPO Module 10 : Paramètres Système

.DESCRIPTION
    Configure les paramètres système divers
    - Explorateur de fichiers
    - Autorun/Autoplay
    - Synchronisation des paramètres
    - Système de fichiers
    - Profils utilisateur
    - Imprimantes

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.EXAMPLE
    .\GPO-10-SystemSettings.ps1 -GPOName "W11_System" -DomainName "chu-angers.intra"
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
Write-Host " Module 10 : Paramètres Système" -ForegroundColor Cyan
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

Write-Host "[1/6] Configuration de l'Explorateur de fichiers..." -ForegroundColor Yellow

# Ne pas afficher la notification "nouvelle application installée" = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ValueName "NoNewAppAlert" -Type DWord -Value 1 -Domain $DomainName

# Versions précédentes - Empêcher la restauration
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\PreviousVersions" -ValueName "DisableLocalRestore" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\PreviousVersions" -ValueName "DisableBackupRestore" -Type DWord -Value 1 -Domain $DomainName

# Astuces en ligne = Désactivées
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "AllowOnlineTips" -Type DWord -Value 0 -Domain $DomainName

# Interface utilisateur latérale (Astuces)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" -ValueName "DisableHelpSticker" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Explorateur de fichiers configuré." -ForegroundColor Green

Write-Host "[2/6] Désactivation de l'Autorun/Autoplay..." -ForegroundColor Yellow

# Comportement par défaut = N'exécuter aucune commande Autorun (1)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoAutorun" -Type DWord -Value 1 -Domain $DomainName

# Désactiver l'exécution automatique = Tous les lecteurs (255)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoDriveTypeAutoRun" -Type DWord -Value 255 -Domain $DomainName

# Empêcher l'exécution automatique de mémoriser les choix
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "DontSetAutoplayCheckbox" -Type DWord -Value 1 -Domain $DomainName

# Interdire l'exécution automatique pour les périphériques autres que ceux du volume
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ValueName "NoAutoplayfornonVolume" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Autorun/Autoplay désactivé." -ForegroundColor Green

Write-Host "[3/6] Désactivation de la synchronisation des paramètres..." -ForegroundColor Yellow

# Synchroniser vos paramètres = Tout désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableSettingSync" -Type DWord -Value 2 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableSettingSyncUserOverride" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableDesktopThemeSettingSync" -Type DWord -Value 2 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableDesktopThemeSettingSyncUserOverride" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableAppSyncSettingSync" -Type DWord -Value 2 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableAppSyncSettingSyncUserOverride" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableWindowsSettingSync" -Type DWord -Value 2 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableWindowsSettingSyncUserOverride" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableCredentialsSettingSync" -Type DWord -Value 2 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableCredentialsSettingSyncUserOverride" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisablePersonalizationSettingSync" -Type DWord -Value 2 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisablePersonalizationSettingSyncUserOverride" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableApplicationSettingSync" -Type DWord -Value 2 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableApplicationSettingSyncUserOverride" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableStartLayoutSettingSync" -Type DWord -Value 2 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableWebBrowserSettingSync" -Type DWord -Value 2 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableWebBrowserSettingSyncUserOverride" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -ValueName "DisableSyncOnPaidNetwork" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Synchronisation des paramètres désactivée." -ForegroundColor Green

Write-Host "[4/6] Configuration du système de fichiers..." -ForegroundColor Yellow

# Noms de chemin Win32 longs = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" -ValueName "LongPathsEnabled" -Type DWord -Value 1 -Domain $DomainName

# Désactiver les noms courts NTFS sur tous les volumes (3)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" -ValueName "NtfsDisable8dot3NameCreation" -Type DWord -Value 3 -Domain $DomainName

# Restauration du système - Ne pas désactiver
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" -ValueName "DisableSR" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" -ValueName "DisableConfig" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Système de fichiers configuré." -ForegroundColor Green

Write-Host "[5/6] Configuration des profils utilisateur..." -ForegroundColor Yellow

# Supprimer les profils plus anciens que 333 jours
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "CleanupProfiles" -Type DWord -Value 333 -Domain $DomainName

# Assistant de stockage - Nettoyage fichiers temporaires = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" -ValueName "AllowStorageSenseGlobal" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" -ValueName "AllowStorageSenseTemporaryFilesCleanup" -Type DWord -Value 1 -Domain $DomainName

# Corbeille - Supprimer après 60 jours
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" -ValueName "ConfigStorageSenseRecycleBinCleanupThreshold" -Type DWord -Value 60 -Domain $DomainName

# Flux d'activité = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "EnableActivityFeed" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "PublishUserActivities" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "UploadUserActivities" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "AllowCrossDeviceClipboard" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Profils utilisateur configurés." -ForegroundColor Green

Write-Host "[6/6] Configuration des imprimantes et périphériques..." -ForegroundColor Yellow

# Imprimantes - Autoriser le spouleur à accepter les connexions
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" -ValueName "RegisterSpoolerRemoteRpcEndPoint" -Type DWord -Value 1 -Domain $DomainName

# Désactiver l'impression via HTTP
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" -ValueName "DisableHTTPPrinting" -Type DWord -Value 1 -Domain $DomainName

# Désactiver le téléchargement des pilotes d'imprimantes via HTTP
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" -ValueName "DisableWebPnPDownload" -Type DWord -Value 1 -Domain $DomainName

# Installation de périphériques
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings" -ValueName "AllowRemoteRPC" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings" -ValueName "DisableSendRequestAdditionalSoftwareToWER" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings" -ValueName "DisableSendGenericDriverNotFoundToWER" -Type DWord -Value 1 -Domain $DomainName

# Désactiver la recherche de pilotes de périphériques sur Windows Update
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -ValueName "DontSearchWindowsUpdate" -Type DWord -Value 1 -Domain $DomainName

# DisableCoInstallers (USB)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" -ValueName "DisableCoInstallers" -Type DWord -Value 1 -Domain $DomainName

# Désactiver le Fast Startup (HiberbootEnabled)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -ValueName "HiberbootEnabled" -Type DWord -Value 0 -Domain $DomainName

# Dépannage - Désactiver les Assistants Dépannage (Faille Follina)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\ScriptedDiagnostics" -ValueName "EnableDiagnostics" -Type DWord -Value 0 -Domain $DomainName

# Interface utilisateur d'informations d'identification
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredUI" -ValueName "DisablePasswordReveal" -Type DWord -Value 1 -Domain $DomainName

# Windows PowerShell - Activer l'exécution des scripts = RemoteSigned
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" -ValueName "EnableScripts" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" -ValueName "ExecutionPolicy" -Type String -Value "RemoteSigned" -Domain $DomainName

# Internet Explorer
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\Main" -ValueName "DisableFirstRunCustomize" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\Main" -ValueName "DisablePerformanceCheck" -Type DWord -Value 1 -Domain $DomainName

# IE - TLS 1.0, 1.1, 1.2 (2688)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "SecureProtocols" -Type DWord -Value 2688 -Domain $DomainName

# Lecteur Windows Media
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" -ValueName "PreventLibrarySharing" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" -ValueName "DisableAutoUpdate" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" -ValueName "GroupPrivacyAcceptance" -Type DWord -Value 1 -Domain $DomainName

# Système d'exploitation portable (Windows To Go)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\PortableOperatingSystem" -ValueName "Launcher" -Type DWord -Value 0 -Domain $DomainName

# Service d'association de fichier Internet
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoInternetOpenWith" -Type DWord -Value 1 -Domain $DomainName

# Stratégie de groupe - Traitement Utilisateurs et groupes locaux
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{17D89FEC-5C44-4972-B12D-241CAEF74509}" -ValueName "NoSlowLink" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{17D89FEC-5C44-4972-B12D-241CAEF74509}" -ValueName "NoBackgroundPolicy" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{17D89FEC-5C44-4972-B12D-241CAEF74509}" -ValueName "NoGPOListChanges" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Imprimantes et périphériques configurés." -ForegroundColor Green
Write-Host ""
Write-Host "Module 10 terminé avec succès." -ForegroundColor Green
