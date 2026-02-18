<#
.SYNOPSIS
    GPO Module 5 : Gestion de l'Alimentation

.DESCRIPTION
    Configure les paramètres d'alimentation pour Windows 11
    - Affichage et vidéo
    - Veille et veille prolongée
    - Batterie (critique, faible)
    - Boutons d'alimentation
    - Disque dur

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.EXAMPLE
    .\GPO-05-PowerManagement.ps1 -GPOName "W11_Power" -DomainName "chu-angers.intra"
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
Write-Host " Module 5 : Gestion de l'Alimentation" -ForegroundColor Cyan
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

$powerPolicyKey = "HKLM\SOFTWARE\Policies\Microsoft\Power\PowerSettings"

Write-Host "[1/5] Configuration de l'affichage et vidéo..." -ForegroundColor Yellow

# Diaporama arrière-plan Bureau = Désactivé (batterie et secteur)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\309dce9b-bef4-4119-9921-a851fb12f0f4" -ValueName "DCSettingIndex" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\309dce9b-bef4-4119-9921-a851fb12f0f4" -ValueName "ACSettingIndex" -Type DWord -Value 0 -Domain $DomainName

# Désactiver l'affichage après 600 secondes (10 minutes)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\3C0BC021-C8A8-4E07-A973-6B14CBCB2B7E" -ValueName "DCSettingIndex" -Type DWord -Value 600 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\3C0BC021-C8A8-4E07-A973-6B14CBCB2B7E" -ValueName "ACSettingIndex" -Type DWord -Value 600 -Domain $DomainName

# Réduire la luminosité après 500 secondes (batterie)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\17aaa29b-8b43-4b94-aafe-35f64daaf1ee" -ValueName "DCSettingIndex" -Type DWord -Value 500 -Domain $DomainName

# Luminosité estompée = 75% (batterie)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\f1fbfde2-a960-4680-9b5c-d2e71b11eda6" -ValueName "DCSettingIndex" -Type DWord -Value 75 -Domain $DomainName

# Afficher mettre en veille = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -ValueName "ShowSleepOption" -Type DWord -Value 0 -Domain $DomainName

# Afficher mettre en veille prolongée = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -ValueName "ShowHibernateOption" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Affichage et vidéo configurés." -ForegroundColor Green

Write-Host "[2/5] Configuration de la veille..." -ForegroundColor Yellow

# Applications peuvent empêcher le passage en veille = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\A4B195F5-8225-47D8-8012-9D41369786E2" -ValueName "DCSettingIndex" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\A4B195F5-8225-47D8-8012-9D41369786E2" -ValueName "ACSettingIndex" -Type DWord -Value 1 -Domain $DomainName

# Veille automatique avec fichiers réseau ouverts = Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\d4c1d4c8-d5cc-43d3-b83e-fc51215cb04d" -ValueName "DCSettingIndex" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\d4c1d4c8-d5cc-43d3-b83e-fc51215cb04d" -ValueName "ACSettingIndex" -Type DWord -Value 0 -Domain $DomainName

# Mot de passe au réveil = Activé
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\0e796bdb-100d-47d6-a2d5-f7d2daa51f51" -ValueName "DCSettingIndex" -Type DWord -Value 1 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\0e796bdb-100d-47d6-a2d5-f7d2daa51f51" -ValueName "ACSettingIndex" -Type DWord -Value 1 -Domain $DomainName

# Délai de veille système = 0 (jamais) sur secteur
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\29F6C1DB-86DA-48C5-9FDB-F2B67B1F44DA" -ValueName "ACSettingIndex" -Type DWord -Value 0 -Domain $DomainName

# Délai de veille prolongée = 0 (jamais) sur batterie
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\9D7815A6-7EE4-497E-8888-515A05F02364" -ValueName "DCSettingIndex" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Veille configurée." -ForegroundColor Green

Write-Host "[3/5] Configuration de la batterie..." -ForegroundColor Yellow

# Notification batterie critique = Arrêter (3), niveau 6%
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\637EA02F-BBCB-4015-8E2C-A1C7B9C0B546" -ValueName "DCSettingIndex" -Type DWord -Value 3 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\9A66D8D7-4FF7-4EF9-B5A2-5A326CA2A469" -ValueName "DCSettingIndex" -Type DWord -Value 6 -Domain $DomainName

# Notification batterie faible = Ne rien faire (0), niveau 15%
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\D8742DCB-3E6A-4B3C-B3FE-374623CDCF06" -ValueName "DCSettingIndex" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\8183BA9A-E910-48DA-8769-14AE6DC1170A" -ValueName "DCSettingIndex" -Type DWord -Value 15 -Domain $DomainName

Write-Host "  Batterie configurée." -ForegroundColor Green

Write-Host "[4/5] Configuration des boutons d'alimentation..." -ForegroundColor Yellow

# Capot fermé = Arrêter (3)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\5CA83367-6E45-459F-A27B-476B1D01C936" -ValueName "DCSettingIndex" -Type DWord -Value 3 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\5CA83367-6E45-459F-A27B-476B1D01C936" -ValueName "ACSettingIndex" -Type DWord -Value 3 -Domain $DomainName

# Bouton d'alimentation = Arrêter (3)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\7648EFA3-DD9C-4E3E-B566-50F929386280" -ValueName "DCSettingIndex" -Type DWord -Value 3 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\7648EFA3-DD9C-4E3E-B566-50F929386280" -ValueName "ACSettingIndex" -Type DWord -Value 3 -Domain $DomainName

# Bouton alimentation menu Démarrer = Arrêter (3)
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\A7066653-8D6C-40A8-910E-A1F54B84C7E5" -ValueName "DCSettingIndex" -Type DWord -Value 3 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\A7066653-8D6C-40A8-910E-A1F54B84C7E5" -ValueName "ACSettingIndex" -Type DWord -Value 3 -Domain $DomainName

Write-Host "  Boutons d'alimentation configurés." -ForegroundColor Green

Write-Host "[5/5] Configuration du disque dur..." -ForegroundColor Yellow

# Arrêter le disque dur après 5400 secondes (90 minutes) sur batterie
Set-GPRegistryValue -Guid $GPO.Id -Key "$powerPolicyKey\6738E2C4-E8A5-4A42-B16A-E040E769756E" -ValueName "DCSettingIndex" -Type DWord -Value 5400 -Domain $DomainName

Write-Host "  Disque dur configuré." -ForegroundColor Green
Write-Host ""
Write-Host "Module 5 terminé avec succès." -ForegroundColor Green
