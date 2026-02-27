<#
.SYNOPSIS
    Configure le pinning de la barre des tâches Windows 11 via GPO

.DESCRIPTION
    Ce script déploie un fichier LayoutModification.json pour configurer
    les applications épinglées sur la barre des tâches Windows 11.

    Le fichier JSON est copié dans SYSVOL et référencé via une clé de registre GPO.
    Cette configuration s'applique uniquement aux nouvelles sessions utilisateur
    (applyOnce: true).

.PARAMETER GPOName
    Nom de la GPO à créer/configurer

.PARAMETER DomainName
    Nom du domaine

.PARAMETER LayoutJsonPath
    Chemin vers le fichier LayoutModification.json source (optionnel)

.EXAMPLE
    .\GPO-11-TaskbarPinning.ps1 -GPOName "W11_TaskbarPinning" -DomainName "chu-angers.intra"

.EXAMPLE
    .\GPO-11-TaskbarPinning.ps1 -GPOName "W11_Complete" -DomainName "chu-angers.intra" -LayoutJsonPath "C:\Temp\LayoutModification.json"

.NOTES
    Auteur: CHU Angers
    Version: 1.0
    Date: 2026-02-27

    Références:
    - https://learn.microsoft.com/en-us/windows/configuration/taskbar/pinned-apps
    - https://learn.microsoft.com/en-us/windows/configuration/customize-and-export-start-layout
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$GPOName,

    [Parameter(Mandatory=$true)]
    [string]$DomainName,

    [Parameter(Mandatory=$false)]
    [string]$LayoutJsonPath
)

#Requires -Modules GroupPolicy

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " MODULE 11 : Pinning Barre des Tâches Windows 11" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# VÉRIFICATION DE LA GPO
# ============================================================
$GPO = Get-GPO -Name $GPOName -Domain $DomainName -ErrorAction SilentlyContinue
if (-not $GPO) {
    Write-Error "La GPO '$GPOName' n'existe pas dans le domaine '$DomainName'."
    exit 1
}

Write-Host "GPO trouvée : $($GPO.DisplayName)" -ForegroundColor Green
Write-Host ""

# ============================================================
# CONTENU DU FICHIER LAYOUTMODIFICATION.JSON
# ============================================================
$LayoutJsonContent = @'
{
  "pinnedList": [
    {
      "packagedAppId": "Microsoft.Windows.Photos_8wekyb3d8bbwe!App"
    },
    {
      "packagedAppId": "windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel"
    },
    {
      "packagedAppId": "Microsoft.WindowsCalculator_8wekyb3d8bbwe!App"
    },
    {
      "packagedAppId": "Microsoft.WindowsAlarms_8wekyb3d8bbwe!App"
    },
    {
      "packagedAppId": "Microsoft.WindowsNotepad_8wekyb3d8bbwe!App"
    },
    {
      "packagedAppId": "Microsoft.Paint_8wekyb3d8bbwe!App"
    },
    {
      "packagedAppId": "Microsoft.ScreenSketch_8wekyb3d8bbwe!App"
    },
    {
      "desktopAppLink": "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\File Explorer.lnk"
    },
    {
      "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Outlook (classic).lnk"
    },
    {
      "desktopAppLink": "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\chu.lnk"
    },
    {
      "desktopAppLink": "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Applications de Gestion.lnk"
    },
    {
      "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Adobe Acrobat.lnk"
    },
    {
      "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Excel.lnk"
    },
    {
      "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Google Chrome.lnk"
    },
    {
      "packagedAppId": "MSTeams_8wekyb3d8bbwe!MSTeams"
    },
    {
      "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\OneNote.lnk"
    },
    {
      "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\PowerPoint.lnk"
    },
    {
      "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Visio.lnk"
    },
    {
      "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Word.lnk"
    },
    {
      "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Applications de Gestion\\VPN Global Protect.lnk"
    }
  ],
  "applyOnce": true
}
'@

# ============================================================
# DÉTERMINATION DU CHEMIN SYSVOL
# ============================================================
Write-Host "[1/4] Préparation du fichier LayoutModification.json..." -ForegroundColor Yellow

# Récupérer l'ID de la GPO
$GPOGUID = $GPO.Id.ToString()

# Construire le chemin SYSVOL vers le dossier Machine de la GPO
$DomainFQDN = (Get-ADDomain -Current LocalComputer).DNSRoot
$SysvolPath = "\\$DomainFQDN\SYSVOL\$DomainFQDN\Policies\{$GPOGUID}\Machine"

Write-Host "  Chemin SYSVOL : $SysvolPath" -ForegroundColor White

# Vérifier l'accès SYSVOL
if (-not (Test-Path $SysvolPath)) {
    Write-Error "Le chemin SYSVOL n'existe pas : $SysvolPath"
    exit 1
}

# ============================================================
# COPIE DU FICHIER JSON DANS SYSVOL
# ============================================================
Write-Host "[2/4] Copie du fichier dans SYSVOL..." -ForegroundColor Yellow

# Créer le dossier Scripts s'il n'existe pas
$ScriptsFolder = Join-Path $SysvolPath "Scripts"
if (-not (Test-Path $ScriptsFolder)) {
    New-Item -Path $ScriptsFolder -ItemType Directory -Force | Out-Null
    Write-Host "  Dossier créé : $ScriptsFolder" -ForegroundColor Green
}

# Chemin de destination du fichier JSON
$LayoutJsonDestPath = Join-Path $ScriptsFolder "LayoutModification.json"

# Si un fichier source est fourni, l'utiliser
if ($LayoutJsonPath -and (Test-Path $LayoutJsonPath)) {
    Copy-Item -Path $LayoutJsonPath -Destination $LayoutJsonDestPath -Force
    Write-Host "  Fichier copié depuis : $LayoutJsonPath" -ForegroundColor Green
} else {
    # Sinon, utiliser le contenu embarqué
    $LayoutJsonContent | Out-File -FilePath $LayoutJsonDestPath -Encoding UTF8 -Force
    Write-Host "  Fichier créé avec contenu embarqué" -ForegroundColor Green
}

Write-Host "  Destination : $LayoutJsonDestPath" -ForegroundColor White
Write-Host ""

# ============================================================
# CONFIGURATION DE LA CLÉ DE REGISTRE VIA GPO
# ============================================================
Write-Host "[3/4] Configuration de la clé de registre dans la GPO..." -ForegroundColor Yellow

# Clé de registre pour Windows 11 taskbar pinning
$RegKey = "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer"
$RegValueName = "StartLayoutFile"
$RegValue = $LayoutJsonDestPath
$RegType = "String"

try {
    Set-GPRegistryValue -Name $GPOName `
                        -Domain $DomainName `
                        -Key $RegKey `
                        -ValueName $RegValueName `
                        -Type $RegType `
                        -Value $RegValue `
                        -ErrorAction Stop

    Write-Host "  Clé de registre configurée :" -ForegroundColor Green
    Write-Host "    Chemin : $RegKey" -ForegroundColor White
    Write-Host "    Valeur : $RegValueName = $RegValue" -ForegroundColor White
} catch {
    Write-Error "Erreur lors de la configuration du registre : $_"
    exit 1
}

Write-Host ""

# Configuration additionnelle : Désactiver le pinning manuel par l'utilisateur (optionnel)
Write-Host "[4/4] Configuration des restrictions de pinning..." -ForegroundColor Yellow

try {
    # Empêcher la modification du layout par l'utilisateur
    Set-GPRegistryValue -Name $GPOName `
                        -Domain $DomainName `
                        -Key $RegKey `
                        -ValueName "LockedStartLayout" `
                        -Type DWord `
                        -Value 1 `
                        -ErrorAction Stop

    Write-Host "  Layout verrouillé : Les utilisateurs ne peuvent pas modifier le pinning" -ForegroundColor Green
} catch {
    Write-Warning "Erreur lors de la configuration du verrouillage : $_"
}

Write-Host ""

# ============================================================
# RÉSUMÉ
# ============================================================
Write-Host "============================================================" -ForegroundColor Green
Write-Host " MODULE 11 : TERMINÉ AVEC SUCCÈS" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Applications épinglées sur la barre des tâches :" -ForegroundColor White
Write-Host "  - Photos, Paramètres, Calculatrice, Alarmes" -ForegroundColor Gray
Write-Host "  - Bloc-notes, Paint, Capture d'écran" -ForegroundColor Gray
Write-Host "  - Explorateur de fichiers" -ForegroundColor Gray
Write-Host "  - Outlook (classic)" -ForegroundColor Gray
Write-Host "  - Applications CHU et de Gestion" -ForegroundColor Gray
Write-Host "  - Adobe Acrobat" -ForegroundColor Gray
Write-Host "  - Microsoft Office (Excel, Word, PowerPoint, OneNote, Visio)" -ForegroundColor Gray
Write-Host "  - Google Chrome" -ForegroundColor Gray
Write-Host "  - Microsoft Teams" -ForegroundColor Gray
Write-Host "  - VPN Global Protect" -ForegroundColor Gray
Write-Host ""
Write-Host "Configuration :" -ForegroundColor White
Write-Host "  - Application unique (applyOnce: true)" -ForegroundColor Gray
Write-Host "  - Layout verrouillé pour les utilisateurs" -ForegroundColor Gray
Write-Host ""
Write-Host "Fichier JSON : $LayoutJsonDestPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT :" -ForegroundColor Yellow
Write-Host "  1. Cette configuration s'applique aux NOUVEAUX profils uniquement" -ForegroundColor White
Write-Host "  2. Les utilisateurs existants conservent leur layout actuel" -ForegroundColor White
Write-Host "  3. Les raccourcis (.lnk) doivent exister aux emplacements spécifiés" -ForegroundColor White
Write-Host "  4. Utilisez 'gpupdate /force' sur les postes pour appliquer" -ForegroundColor White
Write-Host ""
