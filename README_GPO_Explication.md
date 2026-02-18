# Explication de la GPO `_OU_Computers_CHU_ALL_W11`

## Informations générales

| Propriété | Valeur |
|---|---|
| **Nom** | `_OU_Computers_CHU_ALL_W11` |
| **Domaine** | `chu-angers.intra` |
| **Propriétaire** | `CHU_ANGERS\Domain Admins` |
| **Créée le** | 04/06/2025 |
| **Modifiée le** | 04/11/2025 |
| **ID unique** | `{13cdc148-d227-4e42-802b-b9235391834a}` |
| **État** | Paramètres utilisateur **désactivés** (seule la config ordinateur est active) |
| **Liaison** | OU `Computers W11` dans `chu-angers.intra` |
| **Filtrage de sécurité** | Utilisateurs authentifiés |

---

## Objectif global de cette GPO

Cette GPO est une **stratégie de durcissement et de standardisation** pour tous les postes **Windows 11** du CHU d'Angers. Elle vise à :

1. **Sécuriser les postes** en désactivant les fonctionnalités non nécessaires en milieu hospitalier
2. **Protéger la vie privée** en bloquant la télémétrie Microsoft et les accès des applications UWP
3. **Standardiser la configuration** (alimentation, écran de verrouillage, associations de fichiers)
4. **Faciliter l'administration** (WinRM, Bureau à distance, scripts automatisés)
5. **Contrôler les mises à jour** via WSUS avec des délais de report

---

## Détail des paramètres par catégorie

### 1. 🔒 Sécurité et durcissement

#### Options de sécurité locales
| Paramètre | Valeur | Explication |
|---|---|---|
| Énumération anonyme SAM | **Bloquée** | Empêche un attaquant d'énumérer les comptes locaux sans authentification |
| UAC - Bureau sécurisé | **Activé** | Les demandes d'élévation s'affichent sur un bureau sécurisé (anti-keylogger) |
| UAC - Invite admin | **Consentement pour binaires non-Windows** | Les admins doivent consentir pour les exécutables non signés Microsoft |
| UAC - Invite utilisateur standard | **Demande d'identifiants** | Les utilisateurs doivent fournir un mot de passe admin pour élever |
| UAC - Détection installations | **Activé** | Détecte automatiquement les installations et demande l'élévation |
| UAC - UIAccess emplacements sécurisés | **Activé** | Seules les apps dans `%ProgramFiles%` peuvent utiliser UIAccess |
| UAC - Mode d'approbation admin | **Activé** | Tous les comptes admin passent par l'UAC |
| Ne pas afficher le dernier utilisateur | **Activé** | L'écran de connexion ne montre pas le dernier nom d'utilisateur |
| Bloquer les comptes Microsoft | **Totalement bloqué** | Impossible d'ajouter ou de se connecter avec un compte Microsoft |

#### SmartScreen et Defender
| Paramètre | Valeur | Explication |
|---|---|---|
| Microsoft Defender Antivirus | **Désactivé** | Un autre antivirus est probablement utilisé (ex: solution hospitalière) |
| SmartScreen | **Désactivé** | Désactivé car les postes sont gérés centralement |
| Quarantaine Defender | **Purge après 30 jours** | Nettoyage automatique de la quarantaine |

### 2. 🔐 Confidentialité et télémétrie

Cette section est **très restrictive** — elle bloque quasiment toute communication de données vers Microsoft :

| Paramètre | Valeur |
|---|---|
| Données de diagnostic | **Désactivé** (niveau 0 = aucune donnée) |
| Pipeline de données commerciales | **Désactivé** |
| Nom de l'appareil dans la télémétrie | **Désactivé** |
| Builds Insider | **Désactivé** |
| Proxy télémétrie | `127.0.0.1:8085` (trou noir local) |
| ID commercial | **Désactivé** |
| OneSettings | **Désactivé** |
| Notifications de commentaire | **Désactivé** |
| Biométrie | **Désactivée** |
| Cartes hors connexion | **Téléchargement auto désactivé** |
| Inventory Collector | **Désactivé** |
| Télémétrie applicative | **Désactivée** |
| CEIP (Programme d'amélioration) | **Désactivé** |
| Rapport d'erreurs Windows | **Désactivé** |
| NCSI (tests de connectivité) | **Désactivé** |

### 3. 📱 Confidentialité des applications UWP

Presque **tous les accès sont forcés en refus** pour les applications du Microsoft Store :

| Accès | Valeur par défaut |
|---|---|
| Localisation | **Forcer le refus** |
| Caméra | **Forcer l'autorisation** (sauf Cortana, Edge, Store, Xbox → refus) |
| Microphone | **Sous contrôle utilisateur** (sauf Cortana, Edge, Xbox → refus) |
| Contacts | **Forcer le refus** |
| Calendrier | **Forcer le refus** |
| Historique des appels | **Forcer le refus** |
| E-mails | **Forcer le refus** |
| Messagerie | **Forcer le refus** |
| Tâches | **Forcer le refus** |
| Appels téléphoniques | **Forcer le refus** |
| Données de mouvement | **Forcer le refus** |
| Informations de compte | **Forcer le refus** |
| Diagnostic d'autres apps | **Forcer le refus** |
| Exécution en arrière-plan | **Forcer le refus** |
| Appareils approuvés | **Forcer le refus** |
| Suivi oculaire | **Forcer le refus** |
| Activation vocale (verrouillé) | **Forcer le refus** |

### 4. 🖥️ Composants Windows désactivés

| Composant | État | Raison |
|---|---|---|
| **OneDrive** | Désactivé | Stockage cloud non autorisé en milieu hospitalier |
| **Windows Store** | Désactivé | Contrôle des installations logicielles |
| **Cortana** | Désactivée | Pas de besoin en milieu professionnel |
| **Widgets** | Désactivés | Distraction inutile |
| **Nouvelles et intérêts** | Désactivés | Idem |
| **Recherche web** | Désactivée | Pas de recherche Bing dans le menu Démarrer |
| **Recherche cloud** | Désactivée | Pas de résultats cloud |
| **Windows Ink** | Désactivé | Non nécessaire |
| **Enregistrement de jeux** | Désactivé | Pas de jeux en milieu hospitalier |
| **Explorateur de jeux** | Désactivé | Idem |
| **Messagerie (sync cloud)** | Désactivée | Pas de sync cloud |
| **Localiser mon appareil** | Désactivé | Géré autrement |
| **Calendrier Windows** | Non configuré | À voir avec Outlook |
| **Lecteur Windows Media** | Partage et mises à jour désactivés | |
| **Internet Explorer** | Écran de démarrage désactivé, TLS 1.0/1.1/1.2 | |
| **OOBE** | Expérience de confidentialité désactivée | Pas de popup au premier login |
| **Contenu cloud** | Désactivé | Pas de suggestions Microsoft |
| **Expériences consommateur** | Désactivées | Pas d'apps suggérées |
| **Conseils Windows** | Désactivés | |

### 5. 🔄 Synchronisation

**Toute synchronisation est désactivée** et les utilisateurs ne peuvent pas la réactiver :
- Paramètres généraux, Bureau, Applications, Mots de passe, Options personnalisées, Paramètres d'application, Démarrage, Navigateur, Connexion limitée

### 6. ⚡ Gestion de l'alimentation

| Paramètre | Batterie | Secteur |
|---|---|---|
| Extinction écran | 600s (10 min) | 600s (10 min) |
| Réduction luminosité | 500s | - |
| Luminosité estompée | 75% | - |
| Veille système | - | **Jamais** (0s) |
| Veille prolongée | **Jamais** (0s) | - |
| Mot de passe au réveil | **Oui** | **Oui** |
| Diaporama arrière-plan | **Désactivé** | **Désactivé** |
| Fichiers réseau ouverts | **Pas de veille** | **Pas de veille** |
| Batterie critique (6%) | **Arrêter** | - |
| Batterie faible (15%) | **Ne rien faire** | - |
| Fermeture capot | **Arrêter** | **Arrêter** |
| Bouton alimentation | **Arrêter** | **Arrêter** |
| Bouton menu Démarrer | **Arrêter** | **Arrêter** |
| Arrêt disque dur | 5400s (90 min) | **Désactivé** |
| Veille dans le menu | **Masquée** | **Masquée** |
| Veille prolongée dans le menu | **Masquée** | **Masquée** |

### 7. 🌐 Réseau

| Paramètre | Valeur | Explication |
|---|---|---|
| **IPv6** | **Désactivé** (tous composants) | Le réseau CHU fonctionne en IPv4 |
| **LLMNR** (résolution multicast) | **Désactivé** | Sécurité : évite les attaques LLMNR poisoning |
| **mDNS** | **Désactivé** (via registre) | Idem |
| **Résolution intelligente multirésidents** | **Désactivée** | Évite les fuites DNS |
| **Pont réseau** | **Interdit** | Sécurité réseau |
| **Partage de connexion Internet** | **Interdit** | Sécurité réseau |
| **Élévation pour emplacement réseau** | **Requise** | Les utilisateurs ne peuvent pas changer le profil réseau |
| **Fichiers hors connexion** | **Désactivés** | Pas de cache local de fichiers réseau |
| **Windows Connect Now** | **Interdit** | Pas de configuration réseau simplifiée |
| **Hotspot sans fil** | **Désactivé** | Pas d'authentification hotspot |
| **802.1X filaire** | **Activé** (PEAP/EAP-MSCHAPv2) | Authentification réseau filaire avec les identifiants Windows |

### 8. 🔄 Windows Update

| Paramètre | Valeur |
|---|---|
| Mises à jour automatiques | **Désactivées** (géré par WSUS) |
| Notifications de mise à jour | Désactivées sauf avertissements de redémarrage |
| Accès Windows Update | **Supprimé** pour les utilisateurs |
| Connexion Internet WU | **Bloquée** (WSUS uniquement) |
| Report mises à jour qualité | **30 jours** |
| Report mises à jour fonctionnalités | **365 jours** |
| Redemander redémarrage | Toutes les **45 minutes** |
| Échéance redémarrage | **7 jours** |
| Redémarrage automatique planifié | **30 minutes** |
| Preview Builds | **Désactivés** |

### 9. 📜 Scripts de démarrage et d'arrêt

#### Au démarrage (PowerShell en premier) :
| Script | Rôle probable |
|---|---|
| `Disable_Onedrive_Task.ps1` | Désactive les tâches planifiées OneDrive |
| `DisableNetBiosTCPIP.ps1` | Désactive NetBIOS sur TCP/IP (sécurité) |
| `StopTacheMicrosoft_W11.cmd` | Arrête des tâches planifiées Microsoft inutiles |

#### À l'arrêt (PowerShell en dernier) :
| Script | Rôle probable |
|---|---|
| `MenageDisque.ps1` | Nettoyage disque (fichiers temporaires, etc.) |
| `StartStopAdmin.ps1 Stop` | Arrête un service d'administration |

### 10. ⚙️ Services système

| Service | Mode de démarrage |
|---|---|
| Propagation du certificat | **Désactivé** |
| Expériences des utilisateurs connectés et télémétrie | **Désactivé** |
| gupdate (Google Update) | **Manuel** |
| gupdatem (Google Update Machine) | **Manuel** |
| Registre à distance | **Automatique** |
| WinRM (Gestion à distance Windows) | **Automatique** |
| Contrôle parental | **Désactivé** |

### 11. 👥 Groupes locaux (GPP)

**Administrateurs locaux** — Mise à jour :
- ✅ **Ajoutés** : `AD_SIT-CDSS`, `AD_SIT-GIS`, `AD_SIT-ADMINPCS`
- ❌ **Retirés** : `TELEMAINTENANCES`

### 12. 📝 Préférences de registre (GPP)

| Clé | Valeur | Explication |
|---|---|---|
| `Device Installer\DisableCoInstallers` | `1` | Désactive les co-installateurs USB |
| `Dnscache\Parameters\EnableMDNS` | `0` | Désactive mDNS |
| `Session Manager\Power\HiberbootEnabled` | `0` | Désactive le Fast Startup |
| `Bandizip\AutoReport` | `0` | Désactive le rapport automatique Bandizip |
| `Winlogon\DefaultPassword` | *(vide)* | Nettoie le mot de passe d'autologon si DefaultUserName = "Administrateur" |
| `Winlogon\DefaultUserName` | *(vide)* | Nettoie le nom d'utilisateur d'autologon |
| `LanmanServer\DefaultSecurity\SrvsvcSessionInfo` | *(binaire)* | Sécurise les informations de session du serveur |

### 13. 📁 Fichiers déployés (GPP)

| Fichier | Source | Destination | Condition |
|---|---|---|---|
| `ifmember.exe` | `\\aw20\Appliteq\Vaccin\` | `C:\Program Files (x86)\Command\` | Toujours |
| `img100.jpg` | *(lockscreen CHU)* | `%WindowsDir%\Web\Screen\` | Windows 10 Pro, Build 17134 |
| `tnsnames.ora` | `\\teledistrib-p\Referentiel\applications\Oracle\` | `C:\oracle\ora_cli10\network\ADMIN\` | Si le dossier existe |
| `tnsnames.ora` | Idem | `C:\oracle\ora_cli11\NETWORK\ADMIN\` | Si le dossier existe |
| `tnsnames.ora` | Idem | `C:\oracle\oradev6i\NET80\ADMIN\` | Si le dossier existe |
| `exception.sites` | `\\teledistrib-p\Referentiel\applications\Java\` | `%WindowsDir%\sun\java\Deployment\` | Si le fichier existe |
| `config.ini` | `\\teledistrib-p\Referentiel\applications\Bandizip\` | `C:\Program Files\BandiZip\` | Toujours |

### 14. 🔐 Permissions système de fichiers

| Dossier | Permissions spéciales |
|---|---|
| `%ProgramFiles% (x86)\KLS` | Utilisateurs = Modification + Supprimer sous-dossiers |
| `%SystemDrive%\bat` | AD_ETUDES = Modification, Utilisateurs authentifiés = Lecture |
| `%SystemRoot%\rustine` | Utilisateurs = Lecture+Exécution+Écriture+Supprimer sous-dossiers |

### 15. 🔌 Réseau câblé 802.1X

| Paramètre | Valeur |
|---|---|
| Services réseau LAN câblés Windows | **Activé** |
| Authentification IEEE 802.1X | **Activée** |
| Méthode d'authentification | **PEAP** (Protected EAP) |
| Méthode interne | **EAP-MSCHAPv2** (mot de passe sécurisé) |
| Validation certificat serveur | **Activée** |
| Reconnexion rapide | **Activée** |
| Utiliser identifiants Windows | **Activé** |
| Authentification de l'ordinateur | Nouvelle authentification de l'utilisateur |

### 16. 🖥️ Système et ouverture de session

| Paramètre | Valeur |
|---|---|
| Messages d'état détaillés | **Activé** (affiche les détails au démarrage) |
| Domaine par défaut | `chu_angers` |
| Animation première connexion | **Désactivée** |
| Son de démarrage | **Désactivé** |
| Notifications écran de verrouillage | **Désactivées** |
| Attendre le réseau au démarrage | **Activé** |
| ID de publicité | **Désactivé** |
| Suppression profils anciens | **333 jours** |
| Assistance à distance | **Désactivée** |
| Nettoyage corbeille (Storage Sense) | **60 jours** |
| Dépannage (Assistants) | **Désactivé** (protection Follina) |
| Flux d'activité | **Désactivé** |
| Publication activités utilisateur | **Désactivée** |
| Presse-papiers multi-appareils | **Désactivé** |
| Noms de chemin Win32 longs | **Activé** |
| Noms courts NTFS | **Désactivés** sur tous les volumes |
| Restauration du système | **Non désactivée** (reste disponible) |
| Caméra écran de verrouillage | **Désactivée** |
| Modification image verrouillage | **Interdite** |
| Reconnaissance vocale en ligne | **Désactivée** |
| Apprentissage automatique écriture | **Désactivé** |
| Astuces en ligne | **Désactivées** |

---

## Comment utiliser le script PowerShell

### Prérequis
1. Un contrôleur de domaine ou un poste avec **RSAT** installé
2. Le module **GroupPolicy** (`Import-Module GroupPolicy`)
3. Des droits **Domain Admin** ou équivalent
4. Adapter les variables en haut du script si nécessaire

### Exécution
```powershell
# Exécution standard
.\Deploy-GPO_OU_Computers_CHU_ALL_W11.ps1

# Avec un nom personnalisé
.\Deploy-GPO_OU_Computers_CHU_ALL_W11.ps1 -GPOName "TEST_GPO_W11"

# Simulation (WhatIf)
.\Deploy-GPO_OU_Computers_CHU_ALL_W11.ps1 -WhatIf
```

### Éléments à configurer manuellement après le script

Le script configure **~90% de la GPO** via `Set-GPRegistryValue`. Les éléments suivants nécessitent une configuration manuelle ou des fichiers XML SYSVOL :

1. **Scripts de démarrage/arrêt** → Copier les scripts dans `SYSVOL\...\Machine\Scripts\Startup` et `Shutdown`
2. **Services système** (mode de démarrage) → Configurer via GPMC ou fichier XML GPP
3. **Groupes locaux** (ajout/retrait de membres) → Configurer via GPMC ou fichier XML GPP
4. **Fichiers déployés** (GPP Files) → Configurer via GPMC ou fichier XML GPP
5. **Permissions système de fichiers** → Configurer via GPMC (Security Settings > File System)
6. **Stratégie de réseau câblé 802.1X** → Configurer via GPMC (Wired Network Policies)
7. **Certificats intermédiaires** → Importer via GPMC (Public Key Policies)
8. **Pare-feu Windows** → Configurer via GPMC si nécessaire

### Vérification
```powershell
# Vérifier que la GPO existe
Get-GPO -Name "_OU_Computers_CHU_ALL_W11"

# Générer un rapport HTML
Get-GPOReport -Name "_OU_Computers_CHU_ALL_W11" -ReportType Html -Path "C:\temp\GPO_Report.html"

# Vérifier la liaison
Get-GPInheritance -Target "OU=Computers W11,DC=chu-angers,DC=intra"

# Appliquer sur un poste cible
gpupdate /force
```
