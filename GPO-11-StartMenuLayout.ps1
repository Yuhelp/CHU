<#
.SYNOPSIS
    GPO Module 11 : Disposition du Menu Démarrer Windows 11

.DESCRIPTION
    Configure la disposition du menu Démarrer (Start Menu) pour Windows 11
    - Déploie le fichier LayoutModification.json dans SYSVOL
    - Configure la stratégie "Configurer la disposition de l'écran de démarrage"
    - Épingle les applications définies (UWP et Desktop)

    Applications épinglées :
    - Photos, Paramètres, Calculatrice, Alarmes, Bloc-notes, Paint
    - Capture d'écran, Explorateur de fichiers, Outlook (classic)
    - CHU, Applications de Gestion, Adobe Acrobat
    - Excel, Google Chrome, Microsoft Teams, OneNote
    - PowerPoint, Visio, Word, VPN Global Protect

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.PARAMETER ApplyOnce
    Si $true, la disposition est appliquée une seule fois (l'utilisateur peut la modifier ensuite).
    Si $false, la disposition est verrouillée et imposée en permanence.
    Par défaut : $true

.EXAMPLE
    .\GPO-11-StartMenuLayout.ps1 -GPOName "W11_Complete" -DomainName "chu-angers.intra"

.EXAMPLE
    .\GPO-11-StartMenuLayout.ps1 -GPOName "W11_Complete" -DomainName "chu-angers.intra" -ApplyOnce $false
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$GPOName,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainName,

    [bool]$ApplyOnce = $true
)

#Requires -Modules GroupPolicy

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Module 11 : Disposition du Menu Démarrer Windows 11" -ForegroundColor Cyan
Write-Host " GPO : $GPOName" -ForegroundColor Cyan
Write-Host " Mode : $(if ($ApplyOnce) { 'Appliquer une fois (modifiable)' } else { 'Verrouillé (imposé)' })" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

try {
    $GPO = Get-GPO -Name $GPOName -Domain $DomainName -ErrorAction Stop
    Write-Host "GPO trouvée : $($GPO.DisplayName)" -ForegroundColor Green
} catch {
    Write-Error "GPO '$GPOName' introuvable. Créez-la d'abord."
    exit 1
}

# ============================================================
# ÉTAPE 1 : Création du fichier LayoutModification.json
# ============================================================
Write-Host "[1/3] Création du fichier LayoutModification.json dans SYSVOL..." -ForegroundColor Yellow

# Contenu du LayoutModification.json pour Windows 11
$LayoutModificationJson = @'
{
  "pinnedList": [
    { "packagedAppId": "Microsoft.Windows.Photos_8wekyb3d8bbwe!App" },
    { "packagedAppId": "windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel" },
    { "packagedAppId": "Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" },
    { "packagedAppId": "Microsoft.WindowsAlarms_8wekyb3d8bbwe!App" },
    { "packagedAppId": "Microsoft.WindowsNotepad_8wekyb3d8bbwe!App" },
    { "packagedAppId": "Microsoft.Paint_8wekyb3d8bbwe!App" },
    { "packagedAppId": "Microsoft.ScreenSketch_8wekyb3d8bbwe!App" },
    { "desktopAppLink": "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\File Explorer.lnk" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Outlook (classic).lnk" },
    { "desktopAppLink": "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\chu.lnk" },
    { "desktopAppLink": "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\Applications de Gestion.lnk" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Adobe Acrobat.lnk" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Excel.lnk" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Google Chrome.lnk" },
    { "packagedAppId": "MSTeams_8wekyb3d8bbwe!MSTeams" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\OneNote.lnk" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\PowerPoint.lnk" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Visio.lnk" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Word.lnk" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Applications de Gestion\\VPN Global Protect.lnk" }
  ]
}
'@

# Chemin SYSVOL de la GPO
$SysvolPolicyPath = "\\$DomainName\SYSVOL\$DomainName\Policies\{$($GPO.Id)}\Machine"
$LayoutFilePath = Join-Path $SysvolPolicyPath "LayoutModification.json"

# Vérifier que le dossier Machine existe dans SYSVOL
if (-not (Test-Path $SysvolPolicyPath)) {
    Write-Host "  Création du dossier : $SysvolPolicyPath" -ForegroundColor DarkYellow
    New-Item -Path $SysvolPolicyPath -ItemType Directory -Force | Out-Null
}

# Écrire le fichier JSON (encodage UTF-8 sans BOM)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($LayoutFilePath, $LayoutModificationJson, $Utf8NoBom)

Write-Host "  Fichier déployé : $LayoutFilePath" -ForegroundColor Green

# ============================================================
# ÉTAPE 2 : Configuration de la stratégie ConfigureStartPins
# ============================================================
Write-Host "[2/3] Configuration de la stratégie de disposition du menu Démarrer..." -ForegroundColor Yellow

# ConfigureStartPins - Chemin vers le fichier JSON de disposition
# Stratégie : Configuration ordinateur > Modèles d'administration > Menu Démarrer et barre des tâches
# "Configurer la disposition de l'écran de démarrage épinglé"
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ValueName "StartLayoutFile" -Type ExpandString -Value $LayoutFilePath -Domain $DomainName

Write-Host "  StartLayoutFile = $LayoutFilePath" -ForegroundColor Green

# ============================================================
# ÉTAPE 3 : Configuration du verrouillage de la disposition
# ============================================================
Write-Host "[3/3] Configuration du mode de verrouillage..." -ForegroundColor Yellow

if ($ApplyOnce) {
    # Mode "Appliquer une fois" : la disposition est appliquée au premier logon
    # puis l'utilisateur peut la personnaliser
    Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ValueName "LockedStartLayout" -Type DWord -Value 0 -Domain $DomainName
    Write-Host "  LockedStartLayout = 0 (disposition modifiable par l'utilisateur)" -ForegroundColor Green
} else {
    # Mode "Verrouillé" : la disposition est imposée en permanence
    # l'utilisateur ne peut pas modifier les épingles
    Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" -ValueName "LockedStartLayout" -Type DWord -Value 1 -Domain $DomainName
    Write-Host "  LockedStartLayout = 1 (disposition verrouillée)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Module 11 terminé avec succès." -ForegroundColor Green
Write-Host ""
Write-Host "NOTE : Les raccourcis Desktop (.lnk) suivants doivent exister sur les postes cibles :" -ForegroundColor DarkYellow
Write-Host "  - %APPDATA%\Microsoft\Windows\Start Menu\Programs\chu.lnk" -ForegroundColor Gray
Write-Host "  - %APPDATA%\Microsoft\Windows\Start Menu\Programs\Applications de Gestion.lnk" -ForegroundColor Gray
Write-Host "  - %ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Applications de Gestion\VPN Global Protect.lnk" -ForegroundColor Gray
Write-Host "  Déployez-les via GPP (Préférences > Fichiers) si nécessaire." -ForegroundColor DarkYellow
