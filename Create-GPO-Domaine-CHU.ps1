<#
.SYNOPSIS
    Crée la GPO "GPO Domaine-CHU" sur le domaine chu-angers.intra
    Basé sur le rapport GPMC exporté le 11/02/2026

.DESCRIPTION
    Ce script recrée la GPO "GPO Domaine-CHU" avec tous les paramètres
    de Configuration Ordinateur et Configuration Utilisateur (Modèles d'administration).

.NOTES
    Prérequis :
      - Module GroupPolicy (RSAT installé)
      - Droits d'administration du domaine
      - Exécuter sur un contrôleur de domaine ou un poste avec RSAT

    Domaine cible : chu-angers.intra
#>

#Requires -Modules GroupPolicy

param(
    [string]$DomainName = "chu-angers.intra",
    [string]$GpoName = "GPO Domaine-CHU"
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Import du module GroupPolicy
# ============================================================================
Import-Module GroupPolicy -ErrorAction Stop
Write-Host "=== Création de la GPO '$GpoName' sur le domaine '$DomainName' ===" -ForegroundColor Cyan

# ============================================================================
# 1. Création de la GPO
# ============================================================================
$existingGpo = Get-GPO -Name $GpoName -Domain $DomainName -ErrorAction SilentlyContinue
if ($existingGpo) {
    Write-Host "[AVERTISSEMENT] La GPO '$GpoName' existe déjà (GUID: $($existingGpo.Id)). Suppression..." -ForegroundColor Yellow
    Remove-GPO -Name $GpoName -Domain $DomainName -Confirm:$false
}

$gpo = New-GPO -Name $GpoName -Domain $DomainName -Comment "GPO Domaine-CHU - Créée par script PowerShell"
Write-Host "[OK] GPO créée avec le GUID: $($gpo.Id)" -ForegroundColor Green

# Activer les deux sections (Computer + User)
$gpo.GpoStatus = "AllSettingsEnabled"

# ============================================================================
# 2. Filtrage de sécurité
#    Par défaut, "Utilisateurs authentifiés" est déjà ajouté au filtrage
#    de sécurité lors de la création d'une GPO.
# ============================================================================
Write-Host "`n--- Filtrage de sécurité ---" -ForegroundColor Cyan
Write-Host "[INFO] Le filtrage de sécurité par défaut (Utilisateurs authentifiés) est conservé." -ForegroundColor Gray

# ============================================================================
# 3. Délégation
#    Les permissions par défaut incluent déjà :
#    - ENTERPRISE DOMAIN CONTROLLERS : Lecture
#    - Système : Modifier les paramètres, supprimer, modifier la sécurité
#    - Utilisateurs authentifiés : Lecture (filtrage de sécurité)
#    - Administrateurs de l'entreprise : Modifier les paramètres, supprimer, modifier la sécurité
#    - Domain Admins : Modifier les paramètres, supprimer, modifier la sécurité
# ============================================================================
Write-Host "`n--- Délégation ---" -ForegroundColor Cyan
Write-Host "[INFO] Les permissions de délégation par défaut sont conservées." -ForegroundColor Gray

# ============================================================================
# CONFIGURATION ORDINATEUR - Modèles d'administration
# ============================================================================
Write-Host "`n=== CONFIGURATION ORDINATEUR ===" -ForegroundColor Cyan

# --------------------------------------------------------------------------
# 3.1 Composants Windows > Rapport d'erreurs Windows > Paramètres avancés
#     "Faire un rapport sur les événements d'arrêt non planifiés" = Activé
# --------------------------------------------------------------------------
Write-Host "`n--- Composants Windows/Rapport d'erreurs Windows/Paramètres avancés ---" -ForegroundColor Yellow

# PCHealth\ErrorReporting - Report unplanned shutdown events
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting" `
    -ValueName "IncludeShutdownErrs" `
    -Type DWord -Value 1
Write-Host "[OK] Faire un rapport sur les événements d'arrêt non planifiés = Activé" -ForegroundColor Green

# --------------------------------------------------------------------------
# 3.2 Réseau > Fichiers hors connexion
# --------------------------------------------------------------------------
Write-Host "`n--- Réseau/Fichiers hors connexion (Ordinateur) ---" -ForegroundColor Yellow

# "Action à la déconnexion du serveur" = Activé
# Action : Ne jamais travailler hors connexion (GoOfflineAction = 0 = Work offline, 1 = Never go offline)
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "GoOfflineAction" `
    -Type DWord -Value 1
Write-Host "[OK] Action à la déconnexion du serveur = Activé (Ne jamais travailler hors connexion)" -ForegroundColor Green

# "Autoriser ou interdire l'utilisation de la fonctionnalité de fichiers hors connexion" = Désactivé
# Enabled = 0 means the feature is disabled
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "Enabled" `
    -Type DWord -Value 0
Write-Host "[OK] Autoriser ou interdire l'utilisation de fichiers hors connexion = Désactivé" -ForegroundColor Green

# "Empêcher l'utilisation de dossiers de fichiers hors connexion" = Activé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "DisableCacheViewer" `
    -Type DWord -Value 1
Write-Host "[OK] Empêcher l'utilisation de dossiers de fichiers hors connexion = Activé" -ForegroundColor Green

# "Empêcher la configuration utilisateur des fichiers hors connexion" = Activé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "NoConfigCache" `
    -Type DWord -Value 1
Write-Host "[OK] Empêcher la configuration utilisateur des fichiers hors connexion = Activé" -ForegroundColor Green

# "Synchroniser les fichiers hors connexion avant qu'ils ne soient suspendus" = Désactivé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "SyncAtSuspend" `
    -Type DWord -Value 0
Write-Host "[OK] Synchroniser les fichiers hors connexion avant suspension = Désactivé" -ForegroundColor Green

# "Synchroniser tous les fichiers hors connexion avant de terminer la session" = Désactivé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "SyncAtLogoff" `
    -Type DWord -Value 0
Write-Host "[OK] Synchroniser tous les fichiers hors connexion avant fermeture de session = Désactivé" -ForegroundColor Green

# "Synchroniser tous les fichiers hors connexion lors de l'ouverture de session" = Désactivé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "SyncAtLogon" `
    -Type DWord -Value 0
Write-Host "[OK] Synchroniser tous les fichiers hors connexion à l'ouverture de session = Désactivé" -ForegroundColor Green

# --------------------------------------------------------------------------
# 3.3 Système > Profils utilisateur
# --------------------------------------------------------------------------
Write-Host "`n--- Système/Profils utilisateur ---" -ForegroundColor Yellow

# "Ajouter le groupe de sécurité Administrateurs aux profils utilisateur itinérants" = Activé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" `
    -ValueName "AddAdminGroupToRUP" `
    -Type DWord -Value 1
Write-Host "[OK] Ajouter le groupe Administrateurs aux profils itinérants = Activé" -ForegroundColor Green

# "Désactiver la détection des connexion réseau lentes" = Activé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" `
    -ValueName "SlowLinkDetectEnabled" `
    -Type DWord -Value 0
Write-Host "[OK] Désactiver la détection des connexions réseau lentes = Activé" -ForegroundColor Green

# --------------------------------------------------------------------------
# 3.4 Système > Scripts
# --------------------------------------------------------------------------
Write-Host "`n--- Système/Scripts ---" -ForegroundColor Yellow

# "Exécuter les scripts d'ouverture de session simultanément" = Activé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "RunLogonScriptSync" `
    -Type DWord -Value 1
Write-Host "[OK] Exécuter les scripts d'ouverture de session simultanément = Activé" -ForegroundColor Green

# --------------------------------------------------------------------------
# 3.5 Système > Service de temps Windows > Fournisseurs de temps
# --------------------------------------------------------------------------
Write-Host "`n--- Système/Service de temps Windows/Fournisseurs de temps ---" -ForegroundColor Yellow

# "Activer le client NTP Windows" = Activé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\W32Time\TimeProviders\NtpClient" `
    -ValueName "Enabled" `
    -Type DWord -Value 1
Write-Host "[OK] Activer le client NTP Windows = Activé" -ForegroundColor Green

# "Configurer le client NTP Windows" = Activé
# NtpServer
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\W32Time\Parameters" `
    -ValueName "NtpServer" `
    -Type String -Value "time.windows.com,0x1"
Write-Host "[OK] NtpServer = time.windows.com,0x1" -ForegroundColor Green

# Type
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\W32Time\Parameters" `
    -ValueName "Type" `
    -Type String -Value "NT5DS"
Write-Host "[OK] Type = NT5DS" -ForegroundColor Green

# CrossSiteSyncFlags
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\W32Time\TimeProviders\NtpClient" `
    -ValueName "CrossSiteSyncFlags" `
    -Type DWord -Value 2
Write-Host "[OK] CrossSiteSyncFlags = 2" -ForegroundColor Green

# ResolvePeerBackoffMinutes
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\W32Time\TimeProviders\NtpClient" `
    -ValueName "ResolvePeerBackoffMinutes" `
    -Type DWord -Value 15
Write-Host "[OK] ResolvePeerBackoffMinutes = 15" -ForegroundColor Green

# ResolvePeerBackoffMaxTimes
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\W32Time\TimeProviders\NtpClient" `
    -ValueName "ResolvePeerBackoffMaxTimes" `
    -Type DWord -Value 7
Write-Host "[OK] ResolvePeerBackoffMaxTimes = 7" -ForegroundColor Green

# SpecialPollInterval
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\W32Time\TimeProviders\NtpClient" `
    -ValueName "SpecialPollInterval" `
    -Type DWord -Value 3600
Write-Host "[OK] SpecialPollInterval = 3600" -ForegroundColor Green

# EventLogFlags
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\W32Time\TimeProviders\NtpClient" `
    -ValueName "EventLogFlags" `
    -Type DWord -Value 0
Write-Host "[OK] EventLogFlags = 0" -ForegroundColor Green

# --------------------------------------------------------------------------
# 3.6 Système > Stratégie de groupe
# --------------------------------------------------------------------------
Write-Host "`n--- Système/Stratégie de groupe ---" -ForegroundColor Yellow

# "Configurer la détection d'une liaison lente de stratégie de groupe" = Activé
# Vitesse de connexion = 0 Kbps (désactive la détection des liaisons lentes)
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" `
    -ValueName "GroupPolicyMinTransferRate" `
    -Type DWord -Value 0
Write-Host "[OK] Détection liaison lente de stratégie de groupe = 0 Kbps (désactivée)" -ForegroundColor Green

# "Configurer le traitement de la stratégie de scripts" = Activé
# NoGPOListChanges = 0 (Traiter même si les objets GPO n'ont pas changé = Activé)
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{42B5FAAE-6536-11D2-AE5A-0000F87571E3}" `
    -ValueName "NoGPOListChanges" `
    -Type DWord -Value 0
Write-Host "[OK] Traiter même si les objets GPO n'ont pas changé = Activé" -ForegroundColor Green

# NoSlowLink = 0 (Autoriser le traitement sur une connexion réseau lente = Activé)
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{42B5FAAE-6536-11D2-AE5A-0000F87571E3}" `
    -ValueName "NoSlowLink" `
    -Type DWord -Value 0
Write-Host "[OK] Autoriser le traitement sur une connexion réseau lente = Activé" -ForegroundColor Green

# NoBackgroundPolicy = 0 (Ne pas appliquer lors d'un traitement en arrière-plan = Désactivé)
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Group Policy\{42B5FAAE-6536-11D2-AE5A-0000F87571E3}" `
    -ValueName "NoBackgroundPolicy" `
    -Type DWord -Value 0
Write-Host "[OK] Ne pas appliquer lors d'un traitement en arrière-plan = Désactivé" -ForegroundColor Green

# ============================================================================
# CONFIGURATION UTILISATEUR - Modèles d'administration
# ============================================================================
Write-Host "`n=== CONFIGURATION UTILISATEUR ===" -ForegroundColor Cyan

# --------------------------------------------------------------------------
# 4.1 Réseau > Fichiers hors connexion
# --------------------------------------------------------------------------
Write-Host "`n--- Réseau/Fichiers hors connexion (Utilisateur) ---" -ForegroundColor Yellow

# "Action à la déconnexion du serveur" = Activé (Ne jamais travailler hors connexion)
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKCU\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "GoOfflineAction" `
    -Type DWord -Value 1
Write-Host "[OK] Action à la déconnexion du serveur (User) = Activé (Ne jamais travailler hors connexion)" -ForegroundColor Green

# "Synchroniser tous les fichiers hors connexion avant de terminer la session" = Désactivé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKCU\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "SyncAtLogoff" `
    -Type DWord -Value 0
Write-Host "[OK] Synchroniser tous les fichiers hors connexion avant fermeture de session (User) = Désactivé" -ForegroundColor Green

# "Synchroniser tous les fichiers hors connexion lors de l'ouverture de session" = Désactivé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKCU\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "SyncAtLogon" `
    -Type DWord -Value 0
Write-Host "[OK] Synchroniser tous les fichiers hors connexion à l'ouverture de session (User) = Désactivé" -ForegroundColor Green

# --------------------------------------------------------------------------
# 4.2 Système > Redirection de dossiers
# --------------------------------------------------------------------------
Write-Host "`n--- Système/Redirection de dossiers ---" -ForegroundColor Yellow

# "Ne pas automatiquement rendre disponibles hors connexion tous les dossiers redirigés" = Activé
Set-GPRegistryValue -Name $GpoName -Domain $DomainName `
    -Key "HKCU\SOFTWARE\Policies\Microsoft\Windows\NetCache" `
    -ValueName "DisableFRAdminPinByFolder" `
    -Type DWord -Value 1
Write-Host "[OK] Ne pas automatiquement rendre disponibles hors connexion les dossiers redirigés = Activé" -ForegroundColor Green

# ============================================================================
# Résumé
# ============================================================================
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "=== GPO '$GpoName' créée avec succès ! ===" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Domaine        : $DomainName" -ForegroundColor White
Write-Host "Nom GPO        : $GpoName" -ForegroundColor White
Write-Host "GUID           : $($gpo.Id)" -ForegroundColor White
Write-Host "État           : Activé (Ordinateur + Utilisateur)" -ForegroundColor White
Write-Host ""
Write-Host "Paramètres configurés :" -ForegroundColor White
Write-Host "  Configuration Ordinateur :" -ForegroundColor Gray
Write-Host "    - Rapport d'erreurs Windows (événements d'arrêt)" -ForegroundColor Gray
Write-Host "    - Fichiers hors connexion (7 paramètres)" -ForegroundColor Gray
Write-Host "    - Profils utilisateur (2 paramètres)" -ForegroundColor Gray
Write-Host "    - Scripts (1 paramètre)" -ForegroundColor Gray
Write-Host "    - Service de temps Windows NTP (2 stratégies, 7 valeurs)" -ForegroundColor Gray
Write-Host "    - Stratégie de groupe (2 stratégies, 4 valeurs)" -ForegroundColor Gray
Write-Host "  Configuration Utilisateur :" -ForegroundColor Gray
Write-Host "    - Fichiers hors connexion (3 paramètres)" -ForegroundColor Gray
Write-Host "    - Redirection de dossiers (1 paramètre)" -ForegroundColor Gray
Write-Host ""
Write-Host "[RAPPEL] La GPO n'est liée à aucune OU. Utilisez la commande suivante pour la lier :" -ForegroundColor Yellow
Write-Host "  New-GPLink -Name '$GpoName' -Target 'OU=MonOU,DC=chu-angers,DC=intra' -Domain '$DomainName'" -ForegroundColor Yellow
Write-Host ""
