<#
.SYNOPSIS
    Script principal pour déployer tous les modules GPO

.DESCRIPTION
    Ce script orchestre l'exécution de tous les modules GPO pour créer
    une GPO complète pour Windows 11 au CHU d'Angers.
    
    Modules disponibles :
    1. Sécurité et UAC
    2. Confidentialité et Télémétrie
    3. Confidentialité des Applications UWP
    4. Composants Windows
    5. Gestion de l'Alimentation
    6. Réseau
    7. Windows Update
    8. Windows Defender et SmartScreen
    9. Gestion à Distance
    10. Paramètres Système

.PARAMETER GPOName
    Nom de la GPO à créer/configurer

.PARAMETER DomainName
    Nom du domaine

.PARAMETER TargetOU
    OU cible pour la liaison de la GPO

.PARAMETER Modules
    Liste des modules à exécuter (1-10). Par défaut : tous les modules

.EXAMPLE
    .\Deploy-All-GPO-Modules.ps1 -GPOName "W11_Complete" -DomainName "chu-angers.intra"
    
.EXAMPLE
    .\Deploy-All-GPO-Modules.ps1 -GPOName "W11_Complete" -DomainName "chu-angers.intra" -Modules 1,2,3
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$GPOName,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    
    [string]$TargetOU = "OU=Computers W11,DC=chu-angers,DC=intra",
    
    [int[]]$Modules = @(1,2,3,4,5,6,7,8,9,10)
)

#Requires -Modules GroupPolicy

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DÉPLOIEMENT COMPLET GPO WINDOWS 11" -ForegroundColor Cyan
Write-Host " GPO : $GPOName" -ForegroundColor Cyan
Write-Host " Domaine : $DomainName" -ForegroundColor Cyan
Write-Host " OU cible : $TargetOU" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# ÉTAPE 1 : CRÉATION DE LA GPO
# ============================================================
Write-Host "[ÉTAPE 1] Création de la GPO..." -ForegroundColor Yellow

$GPO = Get-GPO -Name $GPOName -Domain $DomainName -ErrorAction SilentlyContinue
if ($GPO) {
    Write-Warning "La GPO '$GPOName' existe déjà (ID: $($GPO.Id))."
    $confirm = Read-Host "Voulez-vous continuer et appliquer les modules ? (O/N)"
    if ($confirm -ne 'O') { 
        Write-Host "Opération annulée." -ForegroundColor Red
        exit 
    }
} else {
    $GPO = New-GPO -Name $GPOName -Domain $DomainName -Comment "GPO Windows 11 - CHU Angers - Déploiement modulaire"
    Write-Host "  GPO créée : $($GPO.DisplayName) (ID: $($GPO.Id))" -ForegroundColor Green
    
    # Désactiver les paramètres utilisateur
    $GPO.GpoStatus = "UserSettingsDisabled"
    
    # Liaison à l'OU
    try {
        New-GPLink -Guid $GPO.Id -Target $TargetOU -Domain $DomainName -LinkEnabled Yes -ErrorAction Stop
        Write-Host "  GPO liée à : $TargetOU" -ForegroundColor Green
    } catch {
        Write-Warning "  Impossible de lier la GPO : $_"
    }
    
    # Filtrage de sécurité
    Set-GPPermission -Guid $GPO.Id -PermissionLevel GpoRead -TargetName "Authenticated Users" -TargetType Group -Domain $DomainName -ErrorAction SilentlyContinue
    Set-GPPermission -Guid $GPO.Id -PermissionLevel GpoApply -TargetName "Authenticated Users" -TargetType Group -Domain $DomainName -ErrorAction SilentlyContinue
}

Write-Host ""

# ============================================================
# ÉTAPE 2 : EXÉCUTION DES MODULES
# ============================================================
Write-Host "[ÉTAPE 2] Exécution des modules sélectionnés..." -ForegroundColor Yellow
Write-Host ""

$ModuleScripts = @{
    1  = "GPO-01-Security-UAC.ps1"
    2  = "GPO-02-Privacy-Telemetry.ps1"
    3  = "GPO-03-AppPrivacy-UWP.ps1"
    4  = "GPO-04-WindowsComponents.ps1"
    5  = "GPO-05-PowerManagement.ps1"
    6  = "GPO-06-Network.ps1"
    7  = "GPO-07-WindowsUpdate.ps1"
    8  = "GPO-08-Defender-SmartScreen.ps1"
    9  = "GPO-09-RemoteManagement.ps1"
    10 = "GPO-10-SystemSettings.ps1"
}

$SuccessCount = 0
$FailureCount = 0

foreach ($ModuleNum in $Modules | Sort-Object) {
    if ($ModuleScripts.ContainsKey($ModuleNum)) {
        $ScriptName = $ModuleScripts[$ModuleNum]
        $ScriptFullPath = Join-Path $ScriptPath $ScriptName
        
        if (Test-Path $ScriptFullPath) {
            Write-Host "Exécution du module $ModuleNum : $ScriptName" -ForegroundColor Cyan
            try {
                & $ScriptFullPath -GPOName $GPOName -DomainName $DomainName
                $SuccessCount++
                Write-Host ""
            } catch {
                Write-Error "Erreur lors de l'exécution du module $ModuleNum : $_"
                $FailureCount++
                Write-Host ""
            }
        } else {
            Write-Warning "Script introuvable : $ScriptFullPath"
            $FailureCount++
        }
    } else {
        Write-Warning "Module $ModuleNum non reconnu (valeurs valides : 1-10)"
    }
}

# ============================================================
# RÉSUMÉ FINAL
# ============================================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DÉPLOIEMENT TERMINÉ" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "GPO : $GPOName" -ForegroundColor White
Write-Host "Modules exécutés avec succès : $SuccessCount" -ForegroundColor Green
Write-Host "Modules en erreur : $FailureCount" -ForegroundColor $(if ($FailureCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($FailureCount -eq 0) {
    Write-Host "✓ Tous les modules ont été appliqués avec succès !" -ForegroundColor Green
} else {
    Write-Warning "⚠ Certains modules ont échoué. Vérifiez les erreurs ci-dessus."
}

Write-Host ""
Write-Host "ÉLÉMENTS À CONFIGURER MANUELLEMENT :" -ForegroundColor Yellow
Write-Host "  1. Scripts de démarrage/arrêt (Startup/Shutdown)" -ForegroundColor White
Write-Host "  2. Services système (via GPP ou manuellement)" -ForegroundColor White
Write-Host "  3. Groupes locaux (GPP)" -ForegroundColor White
Write-Host "  4. Fichiers déployés (GPP)" -ForegroundColor White
Write-Host "  5. Permissions système de fichiers" -ForegroundColor White
Write-Host "  6. Stratégie de réseau câblé 802.1X" -ForegroundColor White
Write-Host "  7. Certificats intermédiaires" -ForegroundColor White
Write-Host ""
Write-Host "Utilisez 'gpupdate /force' sur les postes cibles pour appliquer." -ForegroundColor Cyan
Write-Host ""
