<#
.SYNOPSIS
    Recrée la GPO "_OU_Computers_CHU_ALL_W11" du CHU d'Angers pour les postes Windows 11.

.DESCRIPTION
    Ce script PowerShell recrée intégralement la GPO "_OU_Computers_CHU_ALL_W11" qui s'applique
    aux ordinateurs Windows 11 du CHU d'Angers (domaine chu-angers.intra).
    
    La GPO couvre :
    - Sécurité et durcissement (UAC, comptes Microsoft, télémétrie, etc.)
    - Confidentialité des applications UWP
    - Gestion de l'alimentation (écran, veille, batterie, boutons)
    - Services système (WinRM, télémétrie, etc.)
    - Modèles d'administration (~150+ paramètres)
    - Préférences (registre, fichiers, groupes locaux, services)
    - Réseau (802.1X, IPv6, DNS, fichiers hors connexion)
    - Scripts de démarrage et d'arrêt
    - Windows Update / WSUS

.NOTES
    Auteur  : Script généré automatiquement depuis le rapport GPMC HTML
    Date    : 2026-02-18
    Domaine : chu-angers.intra
    OU cible: Computers W11
    
    PRÉREQUIS :
    - Exécuter sur un contrôleur de domaine ou un poste avec RSAT
    - Module GroupPolicy (Import-Module GroupPolicy)
    - Droits d'administration du domaine
    - Adapter les chemins UNC (\\aw20\, \\teledistrib-p\, etc.) à votre environnement

.PARAMETER GPOName
    Nom de la GPO à créer. Par défaut : "_OU_Computers_CHU_ALL_W11"

.PARAMETER DomainName
    Nom du domaine. Par défaut : "chu-angers.intra"

.PARAMETER TargetOU
    OU cible pour la liaison. Par défaut : "OU=Computers W11,DC=chu-angers,DC=intra"

.PARAMETER WhatIf
    Simule l'exécution sans appliquer les changements.

.EXAMPLE
    .\Deploy-GPO_OU_Computers_CHU_ALL_W11.ps1
    .\Deploy-GPO_OU_Computers_CHU_ALL_W11.ps1 -GPOName "TEST_GPO_W11" -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$GPOName = "_OU_Computers_CHU_ALL_W11",
    [string]$DomainName = "chu-angers.intra",
    [string]$TargetOU = "OU=Computers W11,DC=chu-angers,DC=intra"
)

#Requires -Modules GroupPolicy

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Déploiement GPO : $GPOName" -ForegroundColor Cyan
Write-Host " Domaine         : $DomainName" -ForegroundColor Cyan
Write-Host " OU cible        : $TargetOU" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# SECTION 1 : CRÉATION DE LA GPO ET LIAISON
# ============================================================
Write-Host "[1/12] Création de la GPO et liaison..." -ForegroundColor Yellow

$GPO = Get-GPO -Name $GPOName -Domain $DomainName -ErrorAction SilentlyContinue
if ($GPO) {
    Write-Warning "La GPO '$GPOName' existe déjà (ID: $($GPO.Id)). Supprimez-la d'abord ou changez le nom."
    $confirm = Read-Host "Voulez-vous continuer et écraser les paramètres ? (O/N)"
    if ($confirm -ne 'O') { exit }
} else {
    $GPO = New-GPO -Name $GPOName -Domain $DomainName -Comment "GPO pour postes Windows 11 - CHU Angers - Générée automatiquement"
    Write-Host "  GPO créée : $($GPO.DisplayName) (ID: $($GPO.Id))" -ForegroundColor Green
}

# Désactiver les paramètres utilisateur (seule la config ordinateur est active)
$GPO.GpoStatus = "UserSettingsDisabled"

# Liaison à l'OU
try {
    New-GPLink -Guid $GPO.Id -Target $TargetOU -Domain $DomainName -LinkEnabled Yes -ErrorAction Stop
    Write-Host "  GPO liée à : $TargetOU" -ForegroundColor Green
} catch {
    Write-Warning "  Impossible de lier la GPO (peut-être déjà liée) : $_"
}

# Filtrage de sécurité : Utilisateurs authentifiés (par défaut)
Set-GPPermission -Guid $GPO.Id -PermissionLevel GpoRead -TargetName "Authenticated Users" -TargetType Group -Domain $DomainName -ErrorAction SilentlyContinue
Set-GPPermission -Guid $GPO.Id -PermissionLevel GpoApply -TargetName "Authenticated Users" -TargetType Group -Domain $DomainName -ErrorAction SilentlyContinue

Write-Host ""

# ============================================================
# SECTION 2 : PARAMÈTRES DE SÉCURITÉ LOCAUX (Options de sécurité)
# ============================================================
Write-Host "[2/12] Paramètres de sécurité locaux..." -ForegroundColor Yellow

# Accès réseau : ne pas autoriser l'énumération anonyme des comptes et partages SAM
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName "RestrictAnonymousSAM" -Type DWord -Value 1 -Domain $DomainName

# Contrôle de compte d'utilisateur (UAC)
# Passer au Bureau sécurisé lors d'une demande d'élévation = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "PromptOnSecureDesktop" -Type DWord -Value 1 -Domain $DomainName

# Comportement de l'invite d'élévation pour les administrateurs = Demande de consentement pour les binaires non Windows (5)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "ConsentPromptBehaviorAdmin" -Type DWord -Value 5 -Domain $DomainName

# Comportement de l'invite d'élévation pour les utilisateurs standard = Demande d'informations d'identification (1)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "ConsentPromptBehaviorUser" -Type DWord -Value 1 -Domain $DomainName

# Détecter les installations d'applications et demander l'élévation = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "EnableInstallerDetection" -Type DWord -Value 1 -Domain $DomainName

# Élever uniquement les applications UIAccess installées à des emplacements sécurisés = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "EnableSecureUIAPaths" -Type DWord -Value 1 -Domain $DomainName

# Exécuter les comptes d'administrateurs en mode d'approbation d'administrateur = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "EnableLUA" -Type DWord -Value 1 -Domain $DomainName

# Ouverture de session interactive : ne pas afficher le nom du dernier utilisateur connecté = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "DontDisplayLastUserName" -Type DWord -Value 1 -Domain $DomainName

# Comptes : bloquer les comptes Microsoft = Les utilisateurs ne peuvent pas ajouter ni se connecter (3)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "NoConnectedUser" -Type DWord -Value 3 -Domain $DomainName

Write-Host "  Paramètres de sécurité locaux configurés." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 3 : MODÈLES D'ADMINISTRATION - WINDOWS DEFENDER
# ============================================================
Write-Host "[3/12] Modèles d'administration - Microsoft Defender..." -ForegroundColor Yellow

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

Write-Host "  Microsoft Defender configuré." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 4 : MODÈLES D'ADMINISTRATION - CONFIDENTIALITÉ & TÉLÉMÉTRIE
# ============================================================
Write-Host "[4/12] Confidentialité, télémétrie et collecte de données..." -ForegroundColor Yellow

# --- Collecte des données et télémétrie ---
# Autoriser les données de diagnostic = Désactivé (0)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "AllowTelemetry" -Type DWord -Value 0 -Domain $DomainName

# Autoriser le pipeline de données commerciales = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "AllowCommercialDataPipeline" -Type DWord -Value 0 -Domain $DomainName

# Autoriser l'envoi du nom de l'appareil = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "AllowDeviceNameInTelemetry" -Type DWord -Value 0 -Domain $DomainName

# Basculer le contrôle utilisateur sur les builds Insider = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -ValueName "AllowBuildPreview" -Type DWord -Value 0 -Domain $DomainName

# Configurer Expériences des utilisateurs connectés et télémétrie - proxy 127.0.0.1:8085
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "TelemetryProxyServer" -Type String -Value "127.0.0.1:8085" -Domain $DomainName

# Configurer l'ID commercial = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "CommercialId" -Type String -Value "" -Domain $DomainName

# Configurer l'utilisation du proxy authentifié = Activé (désactiver proxy auth)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "DisableEnterpriseAuthProxy" -Type DWord -Value 1 -Domain $DomainName

# Configurer la collecte des données de navigation pour Analyses du bureau = Ne pas autoriser
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "MicrosoftEdgeDataOptIn" -Type DWord -Value 0 -Domain $DomainName

# Désactiver la visionneuse de données de diagnostic = Désactivé (0)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "DisableDiagnosticDataViewer" -Type DWord -Value 0 -Domain $DomainName

# Désactiver les téléchargements OneSettings = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "DisableOneSettingsDownloads" -Type DWord -Value 1 -Domain $DomainName

# Ne pas afficher les notifications de commentaire = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ValueName "DoNotShowFeedbackNotifications" -Type DWord -Value 1 -Domain $DomainName

# --- Biométrie ---
# Autoriser l'utilisation de la biométrie = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Biometrics" -ValueName "Enabled" -Type DWord -Value 0 -Domain $DomainName

# --- Cartes ---
# Désactiver le téléchargement automatique des données cartographiques = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps" -ValueName "AutoDownloadAndUpdateMapData" -Type DWord -Value 0 -Domain $DomainName

# Désactiver le trafic réseau non sollicité sur la page Paramètres des cartes hors connexion = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps" -ValueName "AllowUntriggeredNetworkTrafficOnSettingsPage" -Type DWord -Value 0 -Domain $DomainName

# --- Centre de sécurité ---
# Activer le Centre de sécurité (domaine) = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Security Center" -ValueName "FirstRunDisabled" -Type DWord -Value 1 -Domain $DomainName

# --- Compatibilité des applications ---
# Désactiver l'Inventory Collector = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -ValueName "DisableInventory" -Type DWord -Value 1 -Domain $DomainName

# Désactiver la télémétrie applicative = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -ValueName "AITEnable" -Type DWord -Value 0 -Domain $DomainName

# --- Compte Microsoft ---
# Bloquer toute authentification utilisateur au compte Microsoft client = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftAccount" -ValueName "DisableUserAuth" -Type DWord -Value 1 -Domain $DomainName

# --- Contenu cloud ---
# Désactiver le contenu optimisé pour le cloud = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -ValueName "DisableCloudOptimizedContent" -Type DWord -Value 1 -Domain $DomainName

# Désactiver les expériences consommateur de Microsoft = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -ValueName "DisableWindowsConsumerFeatures" -Type DWord -Value 1 -Domain $DomainName

# Ne pas afficher les conseils de Windows = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -ValueName "DisableSoftLanding" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Confidentialité et télémétrie configurées." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 5 : MODÈLES D'ADMINISTRATION - CONFIDENTIALITÉ DES APPS UWP
# ============================================================
Write-Host "[5/12] Confidentialité des applications UWP..." -ForegroundColor Yellow

# Forcer le refus pour la plupart des accès apps (valeur 2 = Forcer le refus)
$appPrivacyKeys = @{
    # Mouvements utilisateur en arrière-plan
    "LetAppsAccessBackgroundSpatialPerception"    = 2
    # Historique des appels
    "LetAppsAccessCallHistory"                     = 2
    # Localisation
    "LetAppsAccessLocation"                        = 2
    # Messagerie
    "LetAppsAccessMessaging"                        = 2
    # Calendrier
    "LetAppsAccessCalendar"                         = 2
    # Appareils approuvés
    "LetAppsAccessTrustedDevices"                   = 2
    # Contacts
    "LetAppsAccessContacts"                         = 2
    # Données de mouvement
    "LetAppsAccessMotion"                           = 2
    # Informations de compte
    "LetAppsAccessAccountInfo"                      = 2
    # Diagnostic d'autres applications
    "LetAppsGetDiagnosticInfo"                      = 2
    # Tâches
    "LetAppsAccessTasks"                            = 2
    # Appels téléphoniques
    "LetAppsAccessPhone"                            = 2
    # Suivi oculaire
    "LetAppsAccessGazeInput"                        = 2
    # Appareils découplés
    "LetAppsAccessRadios"                           = 2
    # Exécution en arrière-plan
    "LetAppsRunInBackground"                        = 2
    # Activation vocale système verrouillé
    "LetAppsActivateWithVoiceAboveLock"             = 2
    # E-mails
    "LetAppsAccessEmail"                            = 2
    # Options de contrôle
    "LetAppsAccessNotifications_UserInControl"      = 2  # Placeholder
}

foreach ($key in $appPrivacyKeys.Keys) {
    Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ValueName $key -Type DWord -Value $appPrivacyKeys[$key] -Domain $DomainName
}

# Notifications = Sous le contrôle de l'utilisateur (0)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -ValueName "LetAppsAccessNotifications" -Type DWord -Value 0 -Domain $DomainName

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

Write-Host "  Confidentialité des applications UWP configurée." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 6 : MODÈLES D'ADMINISTRATION - COMPOSANTS WINDOWS
# ============================================================
Write-Host "[6/12] Composants Windows (OneDrive, Store, Cortana, etc.)..." -ForegroundColor Yellow

# --- OneDrive ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -ValueName "DisableFileSyncNGSC" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -ValueName "PreventNetworkTrafficPreUserSignIn" -Type DWord -Value 1 -Domain $DomainName

# --- Windows Store ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" -ValueName "RemoveWindowsStore" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" -ValueName "AutoDownload" -Type DWord -Value 4 -Domain $DomainName

# --- Cortana / Recherche ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "AllowCortana" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "AllowCortanaAboveLock" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "AllowCloudSearch" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "AllowSearchToUseLocation" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "DisableWebSearch" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "ConnectedSearchUseWeb" -Type DWord -Value 0 -Domain $DomainName

# --- Widgets ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Dsh" -ValueName "AllowNewsAndInterests" -Type DWord -Value 0 -Domain $DomainName

# --- Nouvelles et intérêts (barre des tâches) ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -ValueName "EnableFeeds" -Type DWord -Value 0 -Domain $DomainName

# --- OOBE ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE" -ValueName "DisablePrivacyExperience" -Type DWord -Value 1 -Domain $DomainName

# --- Emplacement et capteurs ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -ValueName "DisableLocation" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -ValueName "DisableLocationScripting" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -ValueName "DisableSensors" -Type DWord -Value 1 -Domain $DomainName

# --- Localiser mon appareil ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" -ValueName "AllowFindMyDevice" -Type DWord -Value 0 -Domain $DomainName

# --- Enregistrement et diffusion de jeux ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -ValueName "AllowGameDVR" -Type DWord -Value 0 -Domain $DomainName

# --- Explorateur de jeux ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameUX" -ValueName "DownloadGameInfo" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameUX" -ValueName "GameUpdateOptions" -Type DWord -Value 0 -Domain $DomainName

# --- Messagerie ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Messaging" -ValueName "AllowMessageSync" -Type DWord -Value 0 -Domain $DomainName

# --- Environnement distant Windows ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "EnableCdp" -Type DWord -Value 1 -Domain $DomainName

# --- Espace de travail Windows Ink = Désactivé (0)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" -ValueName "AllowWindowsInkWorkspace" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" -ValueName "AllowSuggestedAppsInWindowsInkWorkspace" -Type DWord -Value 0 -Domain $DomainName

# --- Plateforme de protection de licence logicielle ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" -ValueName "NoGenTicket" -Type DWord -Value 1 -Domain $DomainName

# --- Processus d'ajout de fonctionnalités à Windows 10 ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudExperienceHost" -ValueName "DisableCloudOptimizedContent" -Type DWord -Value 1 -Domain $DomainName

# --- Programme d'amélioration de l'expérience utilisateur ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -ValueName "CEIPEnable" -Type DWord -Value 0 -Domain $DomainName

# --- Rapport d'erreurs Windows ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -ValueName "Disabled" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -ValueName "DontSendAdditionalData" -Type DWord -Value 1 -Domain $DomainName

# --- Déploiement de package Appx ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" -ValueName "AllowSharedUserAppData" -Type DWord -Value 0 -Domain $DomainName

# --- Lecteur Windows Media ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" -ValueName "PreventLibrarySharing" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" -ValueName "DisableAutoUpdate" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" -ValueName "GroupPrivacyAcceptance" -Type DWord -Value 1 -Domain $DomainName

# --- Internet Explorer ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\Main" -ValueName "DisableFirstRunCustomize" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\Main" -ValueName "DisablePerformanceCheck" -Type DWord -Value 1 -Domain $DomainName

# IE - TLS 1.0, 1.1, 1.2
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName "SecureProtocols" -Type DWord -Value 2688 -Domain $DomainName

# --- Interface utilisateur d'informations d'identification ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredUI" -ValueName "DisablePasswordReveal" -Type DWord -Value 1 -Domain $DomainName

# --- Interface utilisateur latérale (Astuces) ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" -ValueName "DisableHelpSticker" -Type DWord -Value 1 -Domain $DomainName

# --- Groupe résidentiel ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\HomeGroup" -ValueName "DisableHomeGroup" -Type DWord -Value 1 -Domain $DomainName

# --- Service Digital Locker ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Digital Locker" -ValueName "DoNotRunDigitalLocker" -Type DWord -Value 0 -Domain $DomainName

# --- Windows Defender SmartScreen ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "EnableSmartScreen" -Type DWord -Value 0 -Domain $DomainName

# SmartScreen Explorer - Contrôle d'installation des applications = Désactiver les recommandations
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" -ValueName "ConfigureAppInstallControlEnabled" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" -ValueName "ConfigureAppInstallControl" -Type String -Value "Anywhere" -Domain $DomainName

# --- Windows PowerShell - Activer l'exécution des scripts = RemoteSigned ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" -ValueName "EnableScripts" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell" -ValueName "ExecutionPolicy" -Type String -Value "RemoteSigned" -Domain $DomainName

Write-Host "  Composants Windows configurés." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 7 : MODÈLES D'ADMINISTRATION - EXPLORATEUR DE FICHIERS
# ============================================================
Write-Host "[7/12] Explorateur de fichiers et associations..." -ForegroundColor Yellow

# Afficher mettre en veille = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -ValueName "ShowSleepOption" -Type DWord -Value 0 -Domain $DomainName

# Afficher mettre en veille prolongée = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -ValueName "ShowHibernateOption" -Type DWord -Value 0 -Domain $DomainName

# Ne pas afficher la notification "nouvelle application installée" = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ValueName "NoNewAppAlert" -Type DWord -Value 1 -Domain $DomainName

# Définir un fichier de configuration des associations par défaut
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "DefaultAssociationsConfiguration" -Type String -Value "\\chu-angers.intra\sysvol\chu-angers.intra\Policies\{283B83AB-C134-4AA1-BB9B-65E02953B0B5}\Machine\Scripts\Startup\AssociationsFichierParDefaut\AppAssociationDefaut.xlm" -Domain $DomainName

# Versions précédentes - Empêcher la restauration
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\PreviousVersions" -ValueName "DisableLocalRestore" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\PreviousVersions" -ValueName "DisableBackupRestore" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Explorateur de fichiers configuré." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 8 : MODÈLES D'ADMINISTRATION - RÉSEAU
# ============================================================
Write-Host "[8/12] Réseau (IPv6, DNS, connexions, fichiers hors connexion)..." -ForegroundColor Yellow

# IPv6 - Désactiver tous les composants IPv6
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -ValueName "DisabledComponents" -Type DWord -Value 255 -Domain $DomainName

# DNS Client - Désactiver la résolution de noms multidiffusion (LLMNR)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ValueName "EnableMulticast" -Type DWord -Value 0 -Domain $DomainName

# DNS Client - Désactiver la résolution intelligente des noms multirésidents
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ValueName "DisableSmartNameResolution" -Type DWord -Value 1 -Domain $DomainName

# Connexions réseau - Exiger élévation pour emplacement réseau
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" -ValueName "NC_StdDomainUserSetLocation" -Type DWord -Value 1 -Domain $DomainName

# Connexions réseau - Interdire pont réseau
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" -ValueName "NC_AllowNetBridge_NLA" -Type DWord -Value 0 -Domain $DomainName

# Connexions réseau - Interdire partage de connexion Internet
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" -ValueName "NC_ShowSharedAccessUI" -Type DWord -Value 0 -Domain $DomainName

# Fichiers hors connexion - Désactiver
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" -ValueName "Enabled" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" -ValueName "NoReminders" -Type DWord -Value 1 -Domain $DomainName

# Supprimer la commande "Rendre disponible hors connexion"
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\NetCache" -ValueName "NoMakeAvailableOffline" -Type DWord -Value 1 -Domain $DomainName

# Windows Connect Now - Interdire l'accès aux Assistants
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WCN\UI" -ValueName "DisableWcnUi" -Type DWord -Value 1 -Domain $DomainName

# Affichage sans fil - Désactiver couplage PIN
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WirelessDisplay" -ValueName "RequirePinForPairing" -Type DWord -Value 0 -Domain $DomainName

# Authentification zone d'accès sans fil - Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\HotspotAuthentication" -ValueName "Enabled" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Réseau configuré." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 9 : MODÈLES D'ADMINISTRATION - GESTION DE L'ALIMENTATION
# ============================================================
Write-Host "[9/12] Gestion de l'alimentation..." -ForegroundColor Yellow

$powerPolicyKey = "HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings"

# Affichage et vidéo
# Diaporama arrière-plan Bureau = Désactivé (batterie et secteur)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\309dce9b-bef4-4119-9921-a851fb12f0f4" -ValueName "DCSettingIndex" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\309dce9b-bef4-4119-9921-a851fb12f0f4" -ValueName "ACSettingIndex" -Type DWord -Value 0 -Domain $DomainName

# Désactiver l'affichage après 600 secondes (batterie et secteur)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\3C0BC021-C8A8-4E07-A973-6B14CBCB2B7E" -ValueName "DCSettingIndex" -Type DWord -Value 600 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\3C0BC021-C8A8-4E07-A973-6B14CBCB2B7E" -ValueName "ACSettingIndex" -Type DWord -Value 600 -Domain $DomainName

# Réduire la luminosité après 500 secondes (batterie)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\17aaa29b-8b43-4b94-aafe-35f64daaf1ee" -ValueName "DCSettingIndex" -Type DWord -Value 500 -Domain $DomainName

# Luminosité estompée = 75% (batterie)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\f1fbfde2-a960-4680-9b5c-d2e71b11eda6" -ValueName "DCSettingIndex" -Type DWord -Value 75 -Domain $DomainName

# Veille
# Applications peuvent empêcher le passage en veille = Activé (batterie et secteur)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\A4B195F5-8225-47D8-8012-9D41369786E2" -ValueName "DCSettingIndex" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\A4B195F5-8225-47D8-8012-9D41369786E2" -ValueName "ACSettingIndex" -Type DWord -Value 1 -Domain $DomainName

# Veille automatique avec fichiers réseau ouverts = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\d4c1d4c8-d5cc-43d3-b83e-fc51215cb04d" -ValueName "DCSettingIndex" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\d4c1d4c8-d5cc-43d3-b83e-fc51215cb04d" -ValueName "ACSettingIndex" -Type DWord -Value 0 -Domain $DomainName

# Mot de passe au réveil = Activé (batterie et secteur)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\0e796bdb-100d-47d6-a2d5-f7d2daa51f51" -ValueName "DCSettingIndex" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\0e796bdb-100d-47d6-a2d5-f7d2daa51f51" -ValueName "ACSettingIndex" -Type DWord -Value 1 -Domain $DomainName

# Délai de veille système = 0 (jamais) sur secteur
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\29F6C1DB-86DA-48C5-9FDB-F2B67B1F44DA" -ValueName "ACSettingIndex" -Type DWord -Value 0 -Domain $DomainName

# Délai de veille prolongée = 0 (jamais) sur batterie
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\9D7815A6-7EE4-497E-8888-515A05F02364" -ValueName "DCSettingIndex" -Type DWord -Value 0 -Domain $DomainName

# Notification batterie critique = Arrêter, niveau 6%
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\637EA02F-BBCB-4015-8E2C-A1C7B9C0B546" -ValueName "DCSettingIndex" -Type DWord -Value 3 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\9A66D8D7-4FF7-4EF9-B5A2-5A326CA2A469" -ValueName "DCSettingIndex" -Type DWord -Value 6 -Domain $DomainName

# Notification batterie faible = Ne rien faire, niveau 15%
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\D8742DCB-3E6A-4B3C-B3FE-374623CDCF06" -ValueName "DCSettingIndex" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\8183BA9A-E910-48DA-8769-14AE6DC1170A" -ValueName "DCSettingIndex" -Type DWord -Value 15 -Domain $DomainName

# Boutons d'alimentation
# Capot fermé = Arrêter (3) sur batterie et secteur
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\5CA83367-6E45-459F-A27B-476B1D01C936" -ValueName "DCSettingIndex" -Type DWord -Value 3 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\5CA83367-6E45-459F-A27B-476B1D01C936" -ValueName "ACSettingIndex" -Type DWord -Value 3 -Domain $DomainName

# Bouton d'alimentation = Arrêter (3) sur batterie et secteur
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\7648EFA3-DD9C-4E3E-B566-50F929386280" -ValueName "DCSettingIndex" -Type DWord -Value 3 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\7648EFA3-DD9C-4E3E-B566-50F929386280" -ValueName "ACSettingIndex" -Type DWord -Value 3 -Domain $DomainName

# Bouton alimentation menu Démarrer = Arrêter (3) sur batterie et secteur
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\A7066653-8D6C-40A8-910E-A1F54B84C7E5" -ValueName "DCSettingIndex" -Type DWord -Value 3 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\A7066653-8D6C-40A8-910E-A1F54B84C7E5" -ValueName "ACSettingIndex" -Type DWord -Value 3 -Domain $DomainName

# Disque dur
# Arrêter le disque dur après 5400 secondes (batterie)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\6738E2C4-E8A5-4A42-B16A-E040E769756E" -ValueName "DCSettingIndex" -Type DWord -Value 5400 -Domain $DomainName

Write-Host "  Gestion de l'alimentation configurée." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 10 : MODÈLES D'ADMINISTRATION - SYSTÈME
# ============================================================
Write-Host "[10/12] Système (ouverture de session, profils, stratégie de groupe, etc.)..." -ForegroundColor Yellow

# Afficher des messages d'état très détaillés = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "VerboseStatus" -Type DWord -Value 1 -Domain $DomainName

# Ouverture de session - Domaine par défaut
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "DefaultLogonDomain" -Type String -Value "chu_angers" -Domain $DomainName

# Afficher l'animation à la première connexion = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "EnableFirstLogonAnimation" -Type DWord -Value 0 -Domain $DomainName

# Désactiver le son de démarrage de Windows = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" -ValueName "DisableStartupSound" -Type DWord -Value 1 -Domain $DomainName

# Désactiver les notifications des applications sur l'écran de verrouillage = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "DisableLockScreenAppNotifications" -Type DWord -Value 1 -Domain $DomainName

# Toujours attendre le réseau lors du démarrage = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon" -ValueName "SyncForegroundPolicy" -Type DWord -Value 1 -Domain $DomainName

# Profils utilisateur - Désactiver l'ID de publicité = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -ValueName "DisabledByGroupPolicy" -Type DWord -Value 1 -Domain $DomainName

# Profils utilisateur - Supprimer les profils plus anciens que 333 jours
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "CleanupProfiles" -Type DWord -Value 333 -Domain $DomainName

# Assistance à distance sollicitée = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fAllowToGetHelp" -Type DWord -Value 0 -Domain $DomainName

# Assistant de stockage - Nettoyage fichiers temporaires = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" -ValueName "AllowStorageSenseGlobal" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" -ValueName "AllowStorageSenseTemporaryFilesCleanup" -Type DWord -Value 1 -Domain $DomainName

# Corbeille - Supprimer après 60 jours
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" -ValueName "ConfigStorageSenseRecycleBinCleanupThreshold" -Type DWord -Value 60 -Domain $DomainName

# Dépannage - Désactiver les Assistants Dépannage (Faille Follina)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\ScriptedDiagnostics" -ValueName "EnableDiagnostics" -Type DWord -Value 0 -Domain $DomainName

# Stratégies de système d'exploitation
# Flux d'activité = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "EnableActivityFeed" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "PublishUserActivities" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "UploadUserActivities" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "AllowCrossDeviceClipboard" -Type DWord -Value 0 -Domain $DomainName

# Système de fichiers - Noms de chemin Win32 longs = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" -ValueName "LongPathsEnabled" -Type DWord -Value 1 -Domain $DomainName

# NTFS - Désactiver les noms courts sur tous les volumes (3)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" -ValueName "NtfsDisable8dot3NameCreation" -Type DWord -Value 3 -Domain $DomainName

# Restauration du système - Ne pas désactiver
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" -ValueName "DisableSR" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" -ValueName "DisableConfig" -Type DWord -Value 0 -Domain $DomainName

# Stratégie de groupe - Traitement Utilisateurs et groupes locaux
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{17D89FEC-5C44-4972-B12D-241CAEF74509}" -ValueName "NoSlowLink" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{17D89FEC-5C44-4972-B12D-241CAEF74509}" -ValueName "NoBackgroundPolicy" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{17D89FEC-5C44-4972-B12D-241CAEF74509}" -ValueName "NoGPOListChanges" -Type DWord -Value 0 -Domain $DomainName

# Reconnaissance vocale en ligne = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" -ValueName "AllowInputPersonalization" -Type DWord -Value 0 -Domain $DomainName

# Apprentissage automatique écriture manuscrite = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" -ValueName "RestrictImplicitInkCollection" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" -ValueName "RestrictImplicitTextCollection" -Type DWord -Value 1 -Domain $DomainName

# Panneau de configuration - Astuces en ligne = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "AllowOnlineTips" -Type DWord -Value 0 -Domain $DomainName

# Personnalisation - Empêcher caméra écran de verrouillage
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" -ValueName "NoLockScreenCamera" -Type DWord -Value 1 -Domain $DomainName

# Personnalisation - Empêcher modification image écran de verrouillage
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" -ValueName "NoChangingLockScreen" -Type DWord -Value 1 -Domain $DomainName

# Imprimantes - Autoriser le spouleur à accepter les connexions
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" -ValueName "RegisterSpoolerRemoteRpcEndPoint" -Type DWord -Value 1 -Domain $DomainName

# Installation de périphériques
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings" -ValueName "AllowRemoteRPC" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings" -ValueName "DisableSendRequestAdditionalSoftwareToWER" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings" -ValueName "DisableSendGenericDriverNotFoundToWER" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Système configuré." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 11 : MODÈLES D'ADMINISTRATION - WINDOWS UPDATE
# ============================================================
Write-Host "[11/12] Windows Update..." -ForegroundColor Yellow

# Configuration du service Mises à jour automatiques = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "NoAutoUpdate" -Type DWord -Value 1 -Domain $DomainName

# Options d'affichage des notifications de mise à jour = 1 (désactiver toutes sauf avertissements redémarrage)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "SetUpdateNotificationLevel" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "UpdateNotificationLevel" -Type DWord -Value 1 -Domain $DomainName

# Supprimer l'accès à toutes les fonctionnalités de Windows Update = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "SetDisableUXWUAccess" -Type DWord -Value 1 -Domain $DomainName

# Ne pas se connecter à des emplacements Internet Windows Update = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DoNotConnectToWindowsUpdateInternetLocations" -Type DWord -Value 1 -Domain $DomainName

# Mises à jour qualité - Différer de 30 jours
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DeferQualityUpdates" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DeferQualityUpdatesPeriodInDays" -Type DWord -Value 30 -Domain $DomainName

# Mises à jour de fonctionnalités - Différer de 365 jours
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DeferFeatureUpdates" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365 -Domain $DomainName

# Redemander un redémarrage toutes les 45 minutes
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "RebootRelaunchTimeoutEnabled" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "RebootRelaunchTimeout" -Type DWord -Value 45 -Domain $DomainName

# Date d'échéance redémarrage = 7 jours pour mises à jour qualité
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ConfigureDeadlineForQualityUpdates" -Type DWord -Value 7 -Domain $DomainName

# Toujours redémarrer automatiquement à l'heure planifiée = 30 minutes
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AlwaysAutoRebootAtScheduledTime" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AlwaysAutoRebootAtScheduledTimeMinutes" -Type DWord -Value 30 -Domain $DomainName

# Autres paramètres registre (BranchReadinessLevel, ManagePreviewBuilds)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "BranchReadinessLevel" -Type DWord -Value 16 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ManagePreviewBuilds" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "ManagePreviewBuildsPolicyValue" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Windows Update configuré." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION 12 : MODÈLES D'ADMINISTRATION - SYNCHRONISATION & DIVERS
# ============================================================
Write-Host "[12/12] Synchronisation, WinRM, Bureau à distance, Autorun, etc..." -ForegroundColor Yellow

# --- Synchroniser vos paramètres = Tout désactivé ---
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

# --- WinRM ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" -ValueName "AllowBasic" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" -ValueName "AllowAutoConfig" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" -ValueName "IPv4Filter" -Type String -Value "*" -Domain $DomainName

# --- Bureau à distance ---
# Autoriser les connexions à distance
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fDenyTSConnections" -Type DWord -Value 0 -Domain $DomainName

# Forcer la suppression du papier peint du Bureau à distance
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "fNoWallpaper" -Type DWord -Value 1 -Domain $DomainName

# Limiter le nombre maximal de couleurs = Compatible avec le client
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ValueName "ColorDepth" -Type DWord -Value 4 -Domain $DomainName

# --- Stratégies d'exécution automatique (Autorun) ---
# Comportement par défaut = N'exécuter aucune commande Autorun (1)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoAutorun" -Type DWord -Value 1 -Domain $DomainName

# Désactiver l'exécution automatique = Tous les lecteurs (255)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoDriveTypeAutoRun" -Type DWord -Value 255 -Domain $DomainName

# Empêcher l'exécution automatique de mémoriser les choix
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "DontSetAutoplayCheckbox" -Type DWord -Value 1 -Domain $DomainName

# Interdire l'exécution automatique pour les périphériques autres que ceux du volume
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ValueName "NoAutoplayfornonVolume" -Type DWord -Value 1 -Domain $DomainName

# --- Système d'exploitation portable (Windows To Go) ---
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\PortableOperatingSystem" -ValueName "Launcher" -Type DWord -Value 0 -Domain $DomainName

# --- Gestion de la communication Internet ---
# Désactiver l'accès à toutes les fonctionnalités Windows Update
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "DisableWindowsUpdateAccess" -Type DWord -Value 1 -Domain $DomainName

# Désactiver l'accès au Store
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ValueName "NoUseStoreOpenWith" -Type DWord -Value 1 -Domain $DomainName

# Désactiver l'impression via HTTP
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" -ValueName "DisableHTTPPrinting" -Type DWord -Value 1 -Domain $DomainName

# Désactiver le téléchargement des pilotes d'imprimantes via HTTP
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" -ValueName "DisableWebPnPDownload" -Type DWord -Value 1 -Domain $DomainName

# Désactiver la recherche de pilotes de périphériques sur Windows Update
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -ValueName "DontSearchWindowsUpdate" -Type DWord -Value 1 -Domain $DomainName

# Désactiver les tests actifs de l'Indicateur de statut de connectivité réseau Windows (NCSI)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator" -ValueName "NoActiveProbe" -Type DWord -Value 1 -Domain $DomainName

# Désactiver le Programme d'amélioration de l'expérience utilisateur Windows
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -ValueName "CEIPEnable" -Type DWord -Value 0 -Domain $DomainName

# Désactiver le service d'association de fichier Internet
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoInternetOpenWith" -Type DWord -Value 1 -Domain $DomainName

# Désactiver le partage des données de personnalisation de l'écriture manuscrite
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" -ValueName "PreventHandwritingDataSharing" -Type DWord -Value 1 -Domain $DomainName

# Désactiver le signalement d'erreurs de la reconnaissance de l'écriture manuscrite
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" -ValueName "PreventHandwritingErrorReports" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Synchronisation, WinRM, Bureau à distance, Autorun configurés." -ForegroundColor Green
Write-Host ""

# ============================================================
# SECTION BONUS : PRÉFÉRENCES GPP (Registre)
# ============================================================
Write-Host "[BONUS] Préférences GPP - Clés de registre supplémentaires..." -ForegroundColor Yellow
Write-Host "  NOTE: Les préférences GPP (fichiers, services, groupes locaux) nécessitent" -ForegroundColor DarkYellow
Write-Host "  des fichiers XML dans SYSVOL. Voici les clés de registre GPP :" -ForegroundColor DarkYellow

# DisableCoInstallers (USB)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" -ValueName "DisableCoInstallers" -Type DWord -Value 1 -Domain $DomainName

# Désactiver mDNS
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -ValueName "EnableMDNS" -Type DWord -Value 0 -Domain $DomainName

# Désactiver le Fast Startup (HiberbootEnabled)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -ValueName "HiberbootEnabled" -Type DWord -Value 0 -Domain $DomainName

# Bandizip - Désactiver AutoReport
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Bandizip" -ValueName "AutoReport" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Préférences GPP (registre) configurées." -ForegroundColor Green
Write-Host ""

# ============================================================
# RÉSUMÉ FINAL
# ============================================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DÉPLOIEMENT TERMINÉ" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "GPO '$GPOName' créée et configurée avec succès." -ForegroundColor Green
Write-Host ""
Write-Host "ÉLÉMENTS À CONFIGURER MANUELLEMENT :" -ForegroundColor Yellow
Write-Host "  1. Scripts de démarrage (Startup) :" -ForegroundColor White
Write-Host "     - Disable_Onedrive_Task.ps1" -ForegroundColor Gray
Write-Host "     - DisableNetBiosTCPIP.ps1" -ForegroundColor Gray
Write-Host "     - StopTacheMicrosoft_W11.cmd" -ForegroundColor Gray
Write-Host "  2. Scripts d'arrêt (Shutdown) :" -ForegroundColor White
Write-Host "     - MenageDisque.ps1" -ForegroundColor Gray
Write-Host "     - StartStopAdmin.ps1 (paramètre: Stop)" -ForegroundColor Gray
Write-Host "  3. Services système (via GPP ou manuellement) :" -ForegroundColor White
Write-Host "     - Propagation du certificat = Désactivé" -ForegroundColor Gray
Write-Host "     - Expériences des utilisateurs connectés et télémétrie = Désactivé" -ForegroundColor Gray
Write-Host "     - gupdate / gupdatem = Manuel" -ForegroundColor Gray
Write-Host "     - Registre à distance = Automatique" -ForegroundColor Gray
Write-Host "     - WinRM (Gestion à distance de Windows) = Automatique" -ForegroundColor Gray
Write-Host "     - Contrôle parental = Désactivé" -ForegroundColor Gray
Write-Host "  4. Groupes locaux (GPP) :" -ForegroundColor White
Write-Host "     - Ajouter aux Administrateurs : AD_SIT-CDSS, AD_SIT-GIS, AD_SIT-ADMINPCS" -ForegroundColor Gray
Write-Host "     - Retirer des Administrateurs : TELEMAINTENANCES" -ForegroundColor Gray
Write-Host "  5. Fichiers (GPP) :" -ForegroundColor White
Write-Host "     - ifmember.exe, tnsnames.ora (Oracle), exception.sites (Java)" -ForegroundColor Gray
Write-Host "     - img100.jpg (lockscreen), config.ini (Bandizip)" -ForegroundColor Gray
Write-Host "  6. Permissions système de fichiers :" -ForegroundColor White
Write-Host "     - %ProgramFiles% (x86)\KLS" -ForegroundColor Gray
Write-Host "     - %SystemDrive%\bat" -ForegroundColor Gray
Write-Host "     - %SystemRoot%\rustine" -ForegroundColor Gray
Write-Host "  7. Stratégie de réseau câblé 802.1X (PEAP/EAP-MSCHAPv2)" -ForegroundColor White
Write-Host "  8. Certificats intermédiaires (DigiCert Trusted G4 Code Signing)" -ForegroundColor White
Write-Host "  9. Pare-feu Windows avec sécurité avancée (paramètres globaux)" -ForegroundColor White
Write-Host ""
Write-Host "Utilisez 'gpupdate /force' sur les postes cibles pour appliquer." -ForegroundColor Cyan
