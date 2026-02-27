# GPO-11-TaskbarPinning.ps1

## Description

Ce script PowerShell permet de déployer une configuration de pinning de la barre des tâches Windows 11 via une Group Policy Object (GPO). Il utilise un fichier `LayoutModification.json` pour définir les applications épinglées sur la barre des tâches de tous les utilisateurs.

## Fonctionnalités

- Déploiement automatique du fichier `LayoutModification.json` dans SYSVOL
- Configuration de la clé de registre GPO pour référencer le layout
- Verrouillage du layout pour empêcher les modifications utilisateur
- Support des applications UWP (packagedAppId) et des applications desktop (.lnk)
- Application unique au premier profil utilisateur (applyOnce: true)

## Prérequis

- Windows Server avec rôle AD DS et DNS
- Module PowerShell `GroupPolicy` installé
- Droits d'administration du domaine
- Accès au partage SYSVOL
- Une GPO existante (ou créer une nouvelle GPO)

## Applications Épinglées

Le script configure les applications suivantes sur la barre des tâches :

### Applications Windows Natives
- Photos
- Paramètres (Immersive Control Panel)
- Calculatrice
- Alarmes et Horloge
- Bloc-notes
- Paint
- Capture d'écran et croquis

### Applications Desktop
- Explorateur de fichiers
- Outlook (classic)
- Applications CHU
- Applications de Gestion
- Adobe Acrobat
- Google Chrome
- VPN Global Protect

### Applications Microsoft Office
- Excel
- Word
- PowerPoint
- OneNote
- Visio

### Applications UWP
- Microsoft Teams (MSTeams)

## Utilisation

### Méthode 1 : Exécution Standalone

```powershell
.\GPO-11-TaskbarPinning.ps1 -GPOName "W11_TaskbarConfig" -DomainName "chu-angers.intra"
```

### Méthode 2 : Avec un fichier JSON personnalisé

```powershell
.\GPO-11-TaskbarPinning.ps1 -GPOName "W11_TaskbarConfig" -DomainName "chu-angers.intra" -LayoutJsonPath "C:\Temp\LayoutModification.json"
```

### Méthode 3 : Intégration avec Deploy-All-GPO-Modules.ps1

1. Modifier le fichier `Deploy-All-GPO-Modules.ps1` :

```powershell
$ModuleScripts = @{
    1  = "GPO-01-Security-UAC.ps1"
    2  = "GPO-02-Privacy-Telemetry.ps1"
    # ... autres modules ...
    10 = "GPO-10-SystemSettings.ps1"
    11 = "GPO-11-TaskbarPinning.ps1"  # Ajouter cette ligne
}
```

2. Exécuter avec le module 11 :

```powershell
.\Deploy-All-GPO-Modules.ps1 -GPOName "W11_Complete" -DomainName "chu-angers.intra" -Modules 1,2,3,4,5,6,7,8,9,10,11
```

## Paramètres

| Paramètre | Type | Obligatoire | Description |
|-----------|------|-------------|-------------|
| `GPOName` | String | Oui | Nom de la GPO à configurer |
| `DomainName` | String | Oui | Nom du domaine Active Directory |
| `LayoutJsonPath` | String | Non | Chemin vers un fichier JSON personnalisé |

## Structure du Fichier LayoutModification.json

```json
{
  "pinnedList": [
    {
      "packagedAppId": "Microsoft.Windows.Photos_8wekyb3d8bbwe!App"
    },
    {
      "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Excel.lnk"
    }
  ],
  "applyOnce": true
}
```

### Types d'entrées

1. **packagedAppId** : Pour les applications UWP/Microsoft Store
   - Format : `Package.Name_PublisherID!AppID`
   - Exemple : `Microsoft.WindowsCalculator_8wekyb3d8bbwe!App`

2. **desktopAppLink** : Pour les applications desktop
   - Format : Chemin vers un fichier `.lnk`
   - Variables d'environnement supportées :
     - `%APPDATA%` : Profil utilisateur
     - `%ALLUSERSPROFILE%` : Tous les utilisateurs
   - Exemple : `%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Excel.lnk`

## Clés de Registre Configurées

Le script configure les clés de registre suivantes dans la GPO :

```
HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer
├── StartLayoutFile = "\\domain\SYSVOL\...\LayoutModification.json"
└── LockedStartLayout = 1 (DWORD)
```

### Explication des Clés

- **StartLayoutFile** : Chemin vers le fichier JSON de configuration
- **LockedStartLayout** : Verrouille le layout pour empêcher les modifications utilisateur
  - `1` = Verrouillé
  - `0` = Non verrouillé

## Emplacement du Fichier JSON

Le fichier est copié dans :
```
\\<domain>\SYSVOL\<domain>\Policies\{GPO-GUID}\Machine\Scripts\LayoutModification.json
```

Exemple :
```
\\chu-angers.intra\SYSVOL\chu-angers.intra\Policies\{12345678-1234-1234-1234-123456789ABC}\Machine\Scripts\LayoutModification.json
```

## Comportement

### Application du Layout

- **applyOnce: true** : Le layout s'applique uniquement lors de la première connexion d'un utilisateur
- Les utilisateurs existants conservent leur configuration actuelle
- Les nouveaux utilisateurs reçoivent automatiquement ce layout
- Une fois appliqué, les utilisateurs peuvent modifier leur barre des tâches (si LockedStartLayout = 0)

### Verrouillage du Layout

Si `LockedStartLayout = 1` :
- Les utilisateurs ne peuvent pas ajouter/supprimer d'applications épinglées
- Le layout reste fixe pour tous les utilisateurs
- Utile pour des environnements très contrôlés

## Considérations Importantes

### 1. Raccourcis Desktop (.lnk)

Les raccourcis doivent exister aux emplacements spécifiés :
- Les applications doivent être installées avant l'application de la GPO
- Les chemins doivent être valides
- Les raccourcis manquants seront ignorés silencieusement

### 2. Applications UWP

Les applications UWP doivent être :
- Installées sur le système (via Windows Store ou DISM)
- Correctement identifiées avec leur packagedAppId
- Accessibles à tous les utilisateurs

### 3. Profils Existants

Pour appliquer aux profils existants :
- Supprimer le fichier `%LOCALAPPDATA%\Microsoft\Windows\Shell\LayoutModification.json` du profil utilisateur
- Ou créer un script de démarrage pour forcer l'application

### 4. Ordre des Applications

L'ordre dans le JSON correspond à l'ordre d'affichage sur la barre des tâches (de gauche à droite).

## Vérification du Déploiement

### Sur le Contrôleur de Domaine

```powershell
# Vérifier l'existence du fichier JSON
$GPO = Get-GPO -Name "W11_TaskbarConfig"
$GPOGUID = $GPO.Id.ToString()
$JsonPath = "\\chu-angers.intra\SYSVOL\chu-angers.intra\Policies\{$GPOGUID}\Machine\Scripts\LayoutModification.json"
Test-Path $JsonPath

# Vérifier le contenu
Get-Content $JsonPath

# Vérifier les clés de registre GPO
Get-GPRegistryValue -Name "W11_TaskbarConfig" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer"
```

### Sur un Poste Client

```powershell
# Forcer la mise à jour GPO
gpupdate /force

# Vérifier les clés de registre appliquées
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"

# Vérifier le fichier local (après application)
Get-Content "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.json"
```

## Dépannage

### Le layout ne s'applique pas

1. Vérifier que la GPO est liée à la bonne OU
2. Vérifier que le fichier JSON est accessible depuis le client
3. Vérifier les permissions NTFS sur le fichier JSON
4. Vérifier que les raccourcis .lnk existent
5. Consulter les logs d'événements Windows

```powershell
# Logs GPO
Get-WinEvent -LogName "Microsoft-Windows-GroupPolicy/Operational" -MaxEvents 50 | Where-Object {$_.Message -like "*Explorer*"}

# Vérifier l'application de la GPO
gpresult /h gpresult.html
```

### Les applications n'apparaissent pas

- Vérifier que les applications sont installées
- Vérifier les chemins des raccourcis .lnk
- Pour les UWP, vérifier le packagedAppId correct :

```powershell
# Lister toutes les applications UWP installées
Get-AppxPackage | Select-Object Name, PackageFullName, PackageFamilyName
```

### Le layout est ignoré

- Vérifier que `applyOnce: true` permet l'application
- Supprimer le fichier local pour forcer la réapplication :

```powershell
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.json" -Force
```

## Personnalisation

### Ajouter une Application

Modifier le fichier JSON ou le contenu `$LayoutJsonContent` dans le script :

```json
{
  "desktopAppLink": "%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\MonApp.lnk"
}
```

### Trouver le packagedAppId d'une Application UWP

```powershell
Get-AppxPackage | Where-Object {$_.Name -like "*teams*"} | Select-Object Name, PackageFamilyName

# Le packagedAppId est : PackageFamilyName!AppID
# Exemple : MSTeams_8wekyb3d8bbwe!MSTeams
```

### Désactiver le Verrouillage

Modifier la ligne dans le script :

```powershell
# Changer de :
-Value 1

# À :
-Value 0
```

## Références Microsoft

- [Customize the Taskbar on Windows 11](https://learn.microsoft.com/en-us/windows/configuration/taskbar/)
- [Pinned Apps on Windows 11 Taskbar](https://learn.microsoft.com/en-us/windows/configuration/taskbar/pinned-apps)
- [Configure Windows 11 Taskbar](https://learn.microsoft.com/en-us/windows/configuration/customize-and-export-start-layout)
- [LayoutModification.xml/json Reference](https://learn.microsoft.com/en-us/windows/configuration/start-layout-xml-desktop)

## Auteur

**CHU Angers - Service Informatique**
Version 1.0 - Février 2026

## Licence

Usage interne CHU Angers
