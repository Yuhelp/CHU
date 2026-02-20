<#
.SYNOPSIS
    GPO Module 6 : Réseau

.DESCRIPTION
    Configure les paramètres réseau pour Windows 11
    - IPv6 (désactivation)
    - DNS Client (LLMNR, mDNS)
    - Connexions réseau
    - Fichiers hors connexion
    - Windows Connect Now
    - Affichage sans fil

.PARAMETER GPOName
    Nom de la GPO à configurer

.PARAMETER DomainName
    Nom du domaine

.EXAMPLE
    .\GPO-06-Network.ps1 -GPOName "W11_Network" -DomainName "chu-angers.intra"
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
Write-Host " Module 6 : Réseau" -ForegroundColor Cyan
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

Write-Host "[1/5] Désactivation d'IPv6..." -ForegroundColor Yellow

# IPv6 - Désactiver tous les composants IPv6 (255)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -ValueName "DisabledComponents" -Type DWord -Value 255 -Domain $DomainName

Write-Host "  IPv6 désactivé." -ForegroundColor Green

Write-Host "[2/5] Configuration du DNS Client..." -ForegroundColor Yellow

# Désactiver la résolution de noms multidiffusion (LLMNR)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ValueName "EnableMulticast" -Type DWord -Value 0 -Domain $DomainName

# Désactiver la résolution intelligente des noms multirésidents
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ValueName "DisableSmartNameResolution" -Type DWord -Value 1 -Domain $DomainName

# Désactiver mDNS
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -ValueName "EnableMDNS" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  DNS Client configuré." -ForegroundColor Green

Write-Host "[3/5] Configuration des connexions réseau..." -ForegroundColor Yellow

# Exiger élévation pour emplacement réseau
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" -ValueName "NC_StdDomainUserSetLocation" -Type DWord -Value 1 -Domain $DomainName

# Interdire pont réseau
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" -ValueName "NC_AllowNetBridge_NLA" -Type DWord -Value 0 -Domain $DomainName

# Interdire partage de connexion Internet
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Network Connections" -ValueName "NC_ShowSharedAccessUI" -Type DWord -Value 0 -Domain $DomainName

# Désactiver les tests actifs de l'Indicateur de statut de connectivité réseau Windows (NCSI)
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator" -ValueName "NoActiveProbe" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Connexions réseau configurées." -ForegroundColor Green

Write-Host "[4/5] Désactivation des fichiers hors connexion..." -ForegroundColor Yellow

# Fichiers hors connexion - Désactiver
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" -ValueName "Enabled" -Type DWord -Value 0 -Domain $DomainName
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetCache" -ValueName "NoReminders" -Type DWord -Value 1 -Domain $DomainName

# Supprimer la commande "Rendre disponible hors connexion"
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\NetCache" -ValueName "NoMakeAvailableOffline" -Type DWord -Value 1 -Domain $DomainName

Write-Host "  Fichiers hors connexion désactivés." -ForegroundColor Green

Write-Host "[5/5] Configuration des autres paramètres réseau..." -ForegroundColor Yellow

# Windows Connect Now - Interdire l'accès aux Assistants
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WCN\UI" -ValueName "DisableWcnUi" -Type DWord -Value 1 -Domain $DomainName

# Affichage sans fil - Désactiver couplage PIN
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\WirelessDisplay" -ValueName "RequirePinForPairing" -Type DWord -Value 0 -Domain $DomainName

# Authentification zone d'accès sans fil - Désactivé
Set-GPRegistryValue -Guid $GPO.Id -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\HotspotAuthentication" -ValueName "Enabled" -Type DWord -Value 0 -Domain $DomainName

Write-Host "  Autres paramètres réseau configurés." -ForegroundColor Green
Write-Host ""
Write-Host "Module 6 terminé avec succès." -ForegroundColor Green
