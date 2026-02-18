# Documentation des Modules GPO Windows 11

## Vue d'ensemble

Cette collection de scripts PowerShell permet de créer et configurer une GPO (Group Policy Object) pour Windows 11 de manière modulaire. Chaque script est responsable d'un périmètre spécifique de la configuration.

## Architecture Modulaire

Au lieu d'un seul script monolithique, la GPO est divisée en **10 modules indépendants** :

| Module | Script | Périmètre | Paramètres |
|--------|--------|-----------|------------|
| **1** | `GPO-01-Security-UAC.ps1` | Sécurité et UAC | ~15 paramètres |
| **2** | `GPO-02-Privacy-Telemetry.ps1` | Confidentialité et Télémétrie | ~25 paramètres |
| **3** | `GPO-03-AppPrivacy-UWP.ps1` | Confidentialité des Apps UWP | ~20 paramètres |
| **4** | `GPO-04-WindowsComponents.ps1` | Composants Windows | ~30 paramètres |
| **5** | `GPO-05-PowerManagement.ps1` | Gestion de l'Alimentation | ~20 paramètres |
| **6** | `GPO-06-Network.ps1` | Réseau | ~15 paramètres |
| **7** | `GPO-07-WindowsUpdate.ps1` | Windows Update | ~15 paramètres |
| **8** | `GPO-08-Defender-SmartScreen.ps1` | Defender et SmartScreen | ~10 paramètres |
| **9** | `GPO-09-RemoteManagement.ps1` | Gestion à Distance | ~8 paramètres |
| **10** | `GPO-10-SystemSettings.ps1` | Paramètres Système | ~40 paramètres |

**Total : ~200 paramètres de registre configurés**

## Avantages de l'Approche Modulaire

### ✅ Flexibilité
- Appliquer uniquement les modules nécessaires
- Tester un module à la fois
- Désactiver facilement un périmètre spécifique

### ✅ Maintenance
- Modifications ciblées sans risque d'impact sur d'autres périmètres
- Code plus lisible et maintenable
- Facilite le débogage

### ✅ Réutilisabilité
- Utiliser les modules dans différentes GPO
- Créer des GPO spécialisées (ex: uniquement sécurité + réseau)

### ✅ Documentation
- Chaque module est auto-documenté
- Facilite la compréhension du rôle de chaque paramètre

## Utilisation

### Méthode 1 : Déploiement Complet (Tous les Modules)

```powershell
# Créer une GPO complète avec tous les modules
.\Deploy-All-GPO-Modules.ps1 -GPOName "W11_Complete" -DomainName "chu-angers.intra"
```

### Méthode 2 : Déploiement Sélectif

```powershell
# Créer une GPO avec uniquement les modules 1, 2, 3 (Sécurité + Confidentialité)
.\Deploy-All-GPO-Modules.ps1 -GPOName "W11_Security_Privacy" -DomainName "chu-angers.intra" -Modules 1,2,3

# Créer une GPO avec uniquement le réseau et Windows Update
.\Deploy-All-GPO-Modules.ps1 -GPOName "W11_Network_Update" -DomainName "chu-angers.intra" -Modules 6,7
```

### Méthode 3 : Exécution Manuelle d'un Module

```powershell
# Créer d'abord la GPO manuellement via GPMC ou PowerShell
New-GPO -Name "W11_Custom" -Domain "chu-angers.intra"

# Puis appliquer uniquement le module souhaité
.\GPO-01-Security-UAC.ps1 -GPOName "W11_Custom" -DomainName "chu-angers.intra"
.\GPO-06-Network.ps1 -GPOName "W11_Custom" -DomainName "chu-angers.intra"
```

## Détail des Modules

### Module 1 : Sécurité et UAC
**Fichier :** `GPO-01-Security-UAC.ps1`

Configure les paramètres de sécurité fondamentaux :
- Contrôle de compte d'utilisateur (UAC)
- Énumération anonyme SAM
- Blocage des comptes Microsoft
- Écran de connexion sécurisé
- Messages d'état détaillés

**Cas d'usage :** Durcissement de la sécurité des postes de travail

### Module 2 : Confidentialité et Télémétrie
**Fichier :** `GPO-02-Privacy-Telemetry.ps1`

Bloque la collecte de données Microsoft :
- Télémétrie Windows (niveau 0)
- Données de diagnostic
- Biométrie
- Cartes et localisation
- Compatibilité des applications
- Contenu cloud
- Programme d'amélioration

**Cas d'usage :** Conformité RGPD, environnement hospitalier sensible

### Module 3 : Confidentialité des Applications UWP
**Fichier :** `GPO-03-AppPrivacy-UWP.ps1`

Contrôle les accès des applications du Store :
- Caméra (autorisation sélective)
- Microphone (contrôle utilisateur)
- Localisation (refus)
- Contacts, Calendrier, E-mails (refus)
- Messagerie, Appels (refus)
- Exécution en arrière-plan (refus)

**Cas d'usage :** Protection de la vie privée, sécurité des données

### Module 4 : Composants Windows
**Fichier :** `GPO-04-WindowsComponents.ps1`

Désactive les composants non nécessaires :
- OneDrive
- Windows Store
- Cortana et Recherche web
- Widgets et Nouvelles
- Windows Ink
- Fonctionnalités de jeux
- Messagerie cloud

**Cas d'usage :** Simplification de l'environnement professionnel

### Module 5 : Gestion de l'Alimentation
**Fichier :** `GPO-05-PowerManagement.ps1`

Configure l'alimentation pour les postes fixes et portables :
- Extinction écran (10 min)
- Veille système (jamais sur secteur)
- Batterie critique (arrêt à 6%)
- Boutons d'alimentation (arrêt)
- Masquage des options de veille

**Cas d'usage :** Standardisation de l'alimentation, économie d'énergie

### Module 6 : Réseau
**Fichier :** `GPO-06-Network.ps1`

Sécurise et optimise le réseau :
- Désactivation IPv6
- Blocage LLMNR et mDNS (anti-poisoning)
- Interdiction pont réseau et partage de connexion
- Désactivation fichiers hors connexion
- Blocage Windows Connect Now

**Cas d'usage :** Sécurité réseau, conformité aux standards IT

### Module 7 : Windows Update
**Fichier :** `GPO-07-WindowsUpdate.ps1`

Configure WSUS et le report des mises à jour :
- Désactivation mises à jour automatiques
- Report qualité : 30 jours
- Report fonctionnalités : 365 jours
- Blocage accès Windows Update Internet
- Gestion des redémarrages

**Cas d'usage :** Contrôle centralisé des mises à jour via WSUS

### Module 8 : Defender et SmartScreen
**Fichier :** `GPO-08-Defender-SmartScreen.ps1`

Configure l'antivirus et SmartScreen :
- Désactivation Windows Defender (si autre AV)
- Configuration MAPS
- Quarantaine (30 jours)
- Désactivation SmartScreen

**Cas d'usage :** Utilisation d'un antivirus tiers

### Module 9 : Gestion à Distance
**Fichier :** `GPO-09-RemoteManagement.ps1`

Active les outils d'administration à distance :
- WinRM (Windows Remote Management)
- Bureau à distance (RDP)
- Désactivation Assistance à distance

**Cas d'usage :** Support informatique, administration centralisée

### Module 10 : Paramètres Système
**Fichier :** `GPO-10-SystemSettings.ps1`

Configure les paramètres système divers :
- Explorateur de fichiers
- Autorun/Autoplay (désactivé)
- Synchronisation des paramètres (désactivée)
- Système de fichiers (chemins longs, noms courts)
- Profils utilisateur (nettoyage 333 jours)
- Imprimantes et périphériques
- PowerShell (RemoteSigned)

**Cas d'usage :** Standardisation de l'environnement utilisateur

## Prérequis

### Environnement
- Contrôleur de domaine ou poste avec **RSAT** (Remote Server Administration Tools)
- Module PowerShell **GroupPolicy**
- Droits **Domain Admin** ou équivalent

### Vérification des prérequis
```powershell
# Vérifier le module GroupPolicy
Get-Module -ListAvailable GroupPolicy

# Importer le module si nécessaire
Import-Module GroupPolicy

# Vérifier les droits
whoami /groups | findstr "Domain Admins"
```

## Exemples de Scénarios

### Scénario 1 : GPO de Sécurité Maximale
```powershell
.\Deploy-All-GPO-Modules.ps1 `
    -GPOName "W11_Security_Max" `
    -DomainName "chu-angers.intra" `
    -Modules 1,2,3,6,8
```
**Modules :** Sécurité UAC + Confidentialité + Apps UWP + Réseau + Defender

### Scénario 2 : GPO Postes Fixes (Pas de Batterie)
```powershell
.\Deploy-All-GPO-Modules.ps1 `
    -GPOName "W11_Desktop" `
    -DomainName "chu-angers.intra" `
    -Modules 1,2,4,6,7,10
```
**Modules :** Sécurité + Confidentialité + Composants + Réseau + Update + Système (sans alimentation)

### Scénario 3 : GPO Postes Portables
```powershell
.\Deploy-All-GPO-Modules.ps1 `
    -GPOName "W11_Laptop" `
    -DomainName "chu-angers.intra" `
    -Modules 1,2,3,4,5,6,7,9,10
```
**Modules :** Tous sauf Defender (si antivirus tiers)

### Scénario 4 : GPO Minimale (Test)
```powershell
.\Deploy-All-GPO-Modules.ps1 `
    -GPOName "W11_Test" `
    -DomainName "chu-angers.intra" `
    -Modules 1,6
```
**Modules :** Sécurité de base + Réseau uniquement

## Vérification et Validation

### Vérifier la GPO créée
```powershell
# Afficher les détails de la GPO
Get-GPO -Name "W11_Complete" -Domain "chu-angers.intra"

# Générer un rapport HTML
Get-GPOReport -Name "W11_Complete" -ReportType Html -Path "C:\Temp\GPO_Report.html"

# Vérifier la liaison à l'OU
Get-GPInheritance -Target "OU=Computers W11,DC=chu-angers,DC=intra"
```

### Tester sur un poste cible
```powershell
# Sur le poste Windows 11
gpupdate /force

# Vérifier les GPO appliquées
gpresult /r

# Rapport détaillé HTML
gpresult /h C:\Temp\gpresult.html
```

### Vérifier un paramètre spécifique
```powershell
# Exemple : Vérifier si la télémétrie est désactivée
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry"

# Exemple : Vérifier si IPv6 est désactivé
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents"
```

## Éléments Non Couverts par les Scripts

Les éléments suivants nécessitent une configuration manuelle via GPMC (Group Policy Management Console) :

### 1. Scripts de Démarrage/Arrêt
- Copier les scripts dans `SYSVOL\...\Machine\Scripts\Startup` et `Shutdown`
- Configurer via GPMC : Computer Configuration > Policies > Windows Settings > Scripts

### 2. Services Système
- Configurer via GPMC : Computer Configuration > Preferences > Control Panel Settings > Services
- Ou créer un fichier XML GPP manuellement

### 3. Groupes Locaux
- Configurer via GPMC : Computer Configuration > Preferences > Control Panel Settings > Local Users and Groups
- Exemple : Ajouter `AD_SIT-CDSS` aux Administrateurs locaux

### 4. Fichiers Déployés
- Configurer via GPMC : Computer Configuration > Preferences > Windows Settings > Files
- Exemple : Déployer `tnsnames.ora` pour Oracle

### 5. Permissions Système de Fichiers
- Configurer via GPMC : Computer Configuration > Policies > Windows Settings > Security Settings > File System

### 6. Stratégie de Réseau Câblé 802.1X
- Configurer via GPMC : Computer Configuration > Policies > Windows Settings > Security Settings > Wired Network (IEEE 802.3) Policies

### 7. Certificats Intermédiaires
- Configurer via GPMC : Computer Configuration > Policies > Windows Settings > Security Settings > Public Key Policies > Intermediate Certification Authorities

## Dépannage

### Erreur : "GPO introuvable"
```powershell
# Vérifier que la GPO existe
Get-GPO -All -Domain "chu-angers.intra" | Where-Object { $_.DisplayName -like "*W11*" }
```

### Erreur : "Accès refusé"
```powershell
# Vérifier les droits
Get-GPPermission -Name "W11_Complete" -All
```

### Erreur : "Module GroupPolicy introuvable"
```powershell
# Installer RSAT (Windows 10/11)
Add-WindowsCapability -Online -Name Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0
```

### Les paramètres ne s'appliquent pas
```powershell
# Forcer la mise à jour sur le poste cible
gpupdate /force /boot

# Vérifier les événements
Get-WinEvent -LogName "Microsoft-Windows-GroupPolicy/Operational" -MaxEvents 50
```

## Maintenance et Évolution

### Ajouter un Nouveau Paramètre
1. Identifier le module concerné
2. Éditer le script du module
3. Ajouter le paramètre avec `Set-GPRegistryValue`
4. Tester sur une GPO de test
5. Documenter le changement

### Créer un Nouveau Module
1. Copier un module existant comme template
2. Renommer (ex: `GPO-11-CustomModule.ps1`)
3. Modifier le contenu
4. Ajouter au script `Deploy-All-GPO-Modules.ps1`
5. Mettre à jour cette documentation

### Versionner les Scripts
```powershell
# Utiliser Git pour versionner
git init
git add *.ps1 *.md
git commit -m "Version initiale des modules GPO"
```

## Bonnes Pratiques

### ✅ Toujours Tester
- Créer une GPO de test avant de déployer en production
- Tester sur un poste pilote
- Vérifier les logs d'événements

### ✅ Documenter les Changements
- Commenter les modifications dans les scripts
- Tenir à jour un changelog
- Documenter les raisons des choix

### ✅ Sauvegarder
- Exporter régulièrement les GPO
```powershell
Backup-GPO -Name "W11_Complete" -Path "C:\GPO_Backups"
```

### ✅ Utiliser WhatIf
```powershell
# Simuler l'exécution (si le script supporte -WhatIf)
.\Deploy-All-GPO-Modules.ps1 -GPOName "W11_Test" -DomainName "chu-angers.intra" -WhatIf
```

## Support et Contribution

### Signaler un Problème
- Vérifier les logs PowerShell
- Tester le module individuellement
- Vérifier les prérequis

### Améliorer les Scripts
- Proposer des optimisations
- Ajouter de nouveaux modules
- Améliorer la documentation

## Licence et Crédits

**Auteur :** Script généré automatiquement depuis le rapport GPMC HTML  
**Date :** 2026-02-18  
**Domaine :** chu-angers.intra  
**Version :** 1.0

---

**Note :** Ces scripts sont fournis "tels quels" sans garantie. Testez toujours dans un environnement de test avant de déployer en production.
