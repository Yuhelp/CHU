<#
.SYNOPSIS
    GPO Module 3 : Confidentialité des Applications UWP

.DESCRIPTION
    Configure les autorisations d'accès pour les applications UWP
    - Caméra
    - Microphone
    - Localisation
    - Contacts, Calendrier, E-mails
    - Messagerie, Appels
    - Données de mouvement
    - Exécution en arrière-plan

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.EXAMPLE
    .\GPO-03-AppPrivacy-UWP.ps1 -GPOName "W11_AppPrivacy" -DomainName "chu-angers.intra"
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
Write-Host " Module 3 : Confidentialité des Applications UWP" -ForegroundColor Cyan
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

Write-Host "[1/3] Configuration des accès forcés en refus..." -ForegroundColor Yellow

# Forcer le refus pour la plupart des accès apps (valeur 2 = Forcer le refus)
$appPrivacyDeny = @{
    "LetAppsAccessBackgroundSpatialPerception" = 2  # Mouvements utilisateur en arrière-plan
    "LetAppsAccessCallHistory"                  = 2  # Historique des appels
    "LetAppsAccessLocation"                     = 2  # Localisation
    "LetAppsAccessMessaging"                    = 2  # Messagerie
    "LetAppsAccessCalendar"                     = 2  # Calendrier
    "LetAppsAccessTrustedDevices"               = 2  # Appareils approuvés
    "LetAppsAccessContacts"                     = 2  # Contacts
    "LetAppsAccessMotion"                       = 2  # Données de mouvement
    "LetAppsAccessAccountInfo"                  = 2  # Informations de compte
    "LetAppsGetDiagnosticInfo"                  = 2  # Diagnostic d'autres applications
    "LetAppsAccessTasks"                        = 2  # Tâches
    "LetAppsAccessPhone"                        = 2  # Appels téléphoniques
    "LetAppsAccessGazeInput"                    = 2  # Suivi oculaire
    "LetAppsAccessRadios"                       = 2  # Appareils découplés
    "LetAppsRunInBackground"                    = 2  # Exécution en arrière-plan
    "LetAppsActivateWithVoiceAboveLock"         = 2  # Activation vocale système verrouillé
    "LetAppsAccessEmail"                        = 2  # E-mails
}

foreach ($key in $appPrivacyDeny.Keys) {
    Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ValueName $key -Type DWord -Value $appPrivacyDeny[$key] -Domain $DomainName
}

Write-Host "  Accès forcés en refus configurés." -ForegroundColor Green

Write-Host "[2/3] Configuration de l'accès à la caméra..." -ForegroundColor Yellow

# Caméra = Forcer l'autorisation (1) par défaut
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ValueName "LetAppsAccessCamera" -Type DWord -Value 1 -Domain $DomainName

# Caméra - Forcer le refus pour certaines apps Microsoft
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ValueName "LetAppsAccessCamera_ForceDenyTheseApps" -Type MultiString -Value @(
    "Microsoft.Windows.Cortana_cw5n1h2txyewy",
    "Microsoft.MicrosoftEdge_8wekyb3d8bbwe",
    "Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe",
    "Microsoft.Win32WebViewHost_cw5n1h2txyewy",
    "Microsoft.Microsoft3DViewer_8wekyb3d8bbwe",
    "Microsoft.WindowsStore_8wekyb3d8bbwe",
    "Microsoft.XboxGamingOverlay_8wekyb3d8bbwe"
) -Domain $DomainName

# Caméra - Sous le contrôle de l'utilisateur pour Photos et Camera
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ValueName "LetAppsAccessCamera_UserInControlOfTheseApps" -Type MultiString -Value @(
    "Microsoft.Windows.Photos_8wekyb3d8bbwe",
    "Microsoft.WindowsCamera_8wekyb3d8bbwe"
) -Domain $DomainName

Write-Host "  Accès caméra configuré." -ForegroundColor Green

Write-Host "[3/3] Configuration de l'accès au microphone..." -ForegroundColor Yellow

# Microphone = Sous le contrôle de l'utilisateur (0) par défaut
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ValueName "LetAppsAccessMicrophone" -Type DWord -Value 0 -Domain $DomainName

# Microphone - Sous le contrôle de l'utilisateur pour Camera et SoundRecorder
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ValueName "LetAppsAccessMicrophone_UserInControlOfTheseApps" -Type MultiString -Value @(
    "Microsoft.WindowsCamera_8wekyb3d8bbwe",
    "Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe"
) -Domain $DomainName

# Microphone - Forcer le refus pour certaines apps
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ValueName "LetAppsAccessMicrophone_ForceDenyTheseApps" -Type MultiString -Value @(
    "Microsoft.Windows.Cortana_cw5n1h2txyewy",
    "Microsoft.MicrosoftEdge_8wekyb3d8bbwe",
    "Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe",
    "Microsoft.Win32WebViewHost_cw5n1h2txyewy",
    "Microsoft.Messaging_8wekyb3d8bbwe",
    "Microsoft.WindowsStore_8wekyb3d8bbwe",
    "Microsoft.Xbox.TCUI_8wekyb3d8bbwe",
    "Microsoft.XboxApp_8wekyb3d8bbwe",
    "Microsoft.XboxGamingOverlay_8wekyb3d8bbwe",
    "Microsoft.MixedReality.Portal_8wekyb3d8bbwe",
    "Microsoft.Microsoft3DViewer_8wekyb3d8bbwe"
) -Domain $DomainName

# Notifications = Sous le contrôle de l'utilisateur (0)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ValueName "LetAppsAccessNotifications" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Accès microphone configuré." -ForegroundColor Green
Write-Host ""
Write-Host "Module 3 terminé avec succès." -ForegroundColor Green
