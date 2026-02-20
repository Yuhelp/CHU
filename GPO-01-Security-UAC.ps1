<#
.SYNOPSIS
    GPO Module 1 : Sécurité et UAC (User Account Control)

.DESCRIPTION
    Configure les paramètres de sécurité locaux et UAC pour Windows 11
    - Contrôle de compte d'utilisateur (UAC)
    - Énumération anonyme SAM
    - Comptes Microsoft
    - Écran de connexion

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.EXAMPLE
    .\GPO-01-Security-UAC.ps1 -GPOName "W11_Security" -DomainName "chu-angers.intra"
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
Write-Host " Module 1 : Sécurité et UAC" -ForegroundColor Cyan
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

Write-Host "[1/3] Configuration des options de sécurité locales..." -ForegroundColor Yellow

# Accès réseau : ne pas autoriser l'énumération anonyme des comptes et partages SAM
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName "RestrictAnonymousSAM" -Type DWord -Value 1 -Domain $DomainName

# Ouverture de session interactive : ne pas afficher le nom du dernier utilisateur connecté
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "DontDisplayLastUserName" -Type DWord -Value 1 -Domain $DomainName

# Comptes : bloquer les comptes Microsoft (3 = Les utilisateurs ne peuvent pas ajouter ni se connecter)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "NoConnectedUser" -Type DWord -Value 3 -Domain $DomainName

Write-Host "  Options de sécurité locales configurées." -ForegroundColor Green

Write-Host "[2/3] Configuration du Contrôle de compte d'utilisateur (UAC)..." -ForegroundColor Yellow

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

Write-Host "  UAC configuré." -ForegroundColor Green

Write-Host "[3/3] Configuration de l'écran de connexion..." -ForegroundColor Yellow

# Afficher des messages d'état très détaillés = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "VerboseStatus" -Type DWord -Value 1 -Domain $DomainName

# Domaine par défaut
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "DefaultLogonDomain" -Type String -Value "chu_angers" -Domain $DomainName

# Afficher l'animation à la première connexion = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "EnableFirstLogonAnimation" -Type DWord -Value 0 -Domain $DomainName

# Désactiver le son de démarrage de Windows = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" -ValueName "DisableStartupSound" -Type DWord -Value 1 -Domain $DomainName

# Désactiver les notifications des applications sur l'écran de verrouillage = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" -ValueName "DisableLockScreenAppNotifications" -Type DWord -Value 1 -Domain $DomainName

# Toujours attendre le réseau lors du démarrage = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon" -ValueName "SyncForegroundPolicy" -Type DWord -Value 1 -Domain $DomainName

# Caméra écran de verrouillage = Désactivée
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" -ValueName "NoLockScreenCamera" -Type DWord -Value 1 -Domain $DomainName

# Empêcher modification image écran de verrouillage
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" -ValueName "NoChangingLockScreen" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Écran de connexion configuré." -ForegroundColor Green
Write-Host ""
Write-Host "Module 1 terminé avec succès." -ForegroundColor Green
