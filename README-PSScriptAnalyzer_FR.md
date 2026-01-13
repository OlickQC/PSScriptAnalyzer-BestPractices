# Guide de Configuration PSScriptAnalyzer

> 🌍 **Autres langues**: [English](README-PSScriptAnalyzer.md) | Français

Ce document fournit une documentation complète pour la configuration PSScriptAnalyzer utilisée dans ce projet.

## Table des Matières

- [Démarrage Rapide](#démarrage-rapide)
- [Aperçu de la Configuration](#aperçu-de-la-configuration)
- [Référence des Règles Intégrées](#référence-des-règles-intégrées)
- [Référence des Règles Personnalisées](#référence-des-règles-personnalisées)
- [Intégration VS Code](#intégration-vs-code)
- [Liste de Vérification Manuelle](#liste-de-vérification-manuelle)
- [Dépannage](#dépannage)
- [Maintenance](#maintenance)

---

## Démarrage Rapide

### Installation

1. **Installer le module PSScriptAnalyzer** :
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
   ```

2. **Vérifier l'installation** :
   ```powershell
   Get-Module -ListAvailable PSScriptAnalyzer
   ```

3. **Tester la configuration** :
   ```powershell
   Invoke-ScriptAnalyzer -Path .\VotreScript.ps1 -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1
   ```

### Exécuter l'Analyse

**Fichier unique** :
```powershell
Invoke-ScriptAnalyzer -Path .\Script.ps1 -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1
```

**Répertoire entier (récursif)** :
```powershell
Invoke-ScriptAnalyzer -Path .\MonModule\ -Recurse -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1
```

**Filtrer par sévérité** :
```powershell
Invoke-ScriptAnalyzer -Path .\Script.ps1 -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1 -Severity Error
```

**Exporter les résultats vers un fichier** :
```powershell
Invoke-ScriptAnalyzer -Path .\Script.ps1 -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1 | 
    Export-Csv -Path .\ResultatsAnalyse.csv -NoTypeInformation
```

---

## Aperçu de la Configuration

### Fichiers Inclus

| Fichier | Objectif |
|---------|----------|
| `ScriptAnalyzer/PSScriptAnalyzerSettings.psd1` | Configuration principale avec 50+ règles intégrées |
| `ScriptAnalyzer/CustomRules/CustomRules.psm1` | 4 règles personnalisées pour validation additionnelle |
| `.vscode/settings.json` | Paramètres d'intégration de l'espace de travail VS Code |
| `AGENTS.md` | Documentation complète des standards PowerShell |

### Niveaux de Sévérité

| Sévérité | Couleur (VS Code) | Description | Quand Corriger |
|----------|------------------|-------------|----------------|
| **Error** | Rouge | Problèmes critiques qui DOIVENT être corrigés | Avant de committer |
| **Warning** | Jaune | Problèmes qui DEVRAIENT être corrigés | Avant de committer |
| **Information** | Bleu | Suggestions d'amélioration | Selon le temps disponible |

### Couverture

**Ce que PSScriptAnalyzer Applique (~85% des standards AGENTS.md)** :
- ✅ Sécurité (credentials, codage en dur, Invoke-Expression)
- ✅ Conventions de nommage (Verbe-Nom, verbes approuvés)
- ✅ Qualité du code (aliases, catch vides, Write-Host)
- ✅ Formatage (accolades, indentation, longueur de ligne)
- ✅ Meilleures pratiques (CmdletBinding, ShouldProcess)

**Ce qui Nécessite une Révision Manuelle (~15%)** :
- ❌ Exactitude sémantique (le code fait-il ce qu'il prétend ?)
- ❌ Idempotence (vérification de l'état avant modification)
- ❌ Précision de la documentation
- ❌ Dépréciation de modules (AzureRM → Az)

---

## Référence des Règles Intégrées

### Règles de Sécurité (Niveau Erreur)

| Nom de la Règle | Ce qu'elle Détecte | Exemple de Violation | Section AGENTS.md |
|-----------------|-------------------|---------------------|-------------------|
| `PSAvoidUsingPlainTextForPassword` | Paramètres avec "password" dans le nom mais pas `[SecureString]` | `param([string]$Password)` | Sécurité:180 |
| `PSAvoidUsingConvertToSecureStringWithPlainText` | Utilisation de `-AsPlainText` avec `ConvertTo-SecureString` | `ConvertTo-SecureString "pass" -AsPlainText` | Sécurité:180 |
| `PSAvoidUsingComputerNameHardcoded` | Noms de serveur/ordinateur codés en dur | `$Server = "PROD-SQL-01"` | Anti-patterns:471 |
| `PSAvoidUsingUsernameAndPasswordParams` | Paramètres séparés username/password au lieu de PSCredential | `param($Username, $Password)` | Sécurité:180 |
| `PSReservedParams` | Utilisation de noms de paramètres réservés | `param($WhatIf)` | Structure:118 |

### Règles de Convention de Nommage (Niveau Avertissement)

| Nom de la Règle | Ce qu'elle Détecte | Exemple de Violation | Section AGENTS.md |
|-----------------|-------------------|---------------------|-------------------|
| `PSUseApprovedVerbs` | Verbes PowerShell non approuvés | `function Create-File` (utiliser `New-File`) | Conventions:48 |
| `PSUseSingularNouns` | Noms pluriels dans les noms de fonction | `function Get-Users` (utiliser `Get-User`) | Conventions:48 |
| `PSReservedCmdletChar` | Caractères invalides dans les noms de cmdlet | `function Get-My#Data` | Conventions:48 |
| `PSUseCorrectCasing` | Casse incorrecte (pas PascalCase) | `function get-data` | Conventions:83 |

### Règles de Qualité du Code (Niveau Avertissement)

| Nom de la Règle | Ce qu'elle Détecte | Exemple de Violation | Section AGENTS.md |
|-----------------|-------------------|---------------------|-------------------|
| `PSAvoidUsingCmdletAliases` | Aliases utilisés dans les scripts | `gci`, `?`, `%`, `select` | Anti-patterns:498 |
| `PSAvoidUsingEmptyCatchBlock` | Blocs catch vides (erreurs silencieuses) | `try {...} catch {}` | Gestion d'Erreurs:310 |
| `PSAvoidUsingWriteHost` | `Write-Host` dans les scripts | `Write-Host "message"` | Anti-patterns:460 |
| `PSUseDeclaredVarsMoreThanAssignments` | Variables déclarées mais jamais utilisées | `$VarInutilisee = "valeur"` | Structure:83 |
| `PSAvoidGlobalVars` | Utilisation de variables globales | `$global:MaVar = "valeur"` | Structure:118 |
| `PSAvoidDefaultValueSwitchParameter` | Paramètres switch par défaut à `$true` | `param([switch]$Force = $true)` | Structure:118 |
| `PSAvoidUsingWMICmdlet` | Cmdlets WMI dépréciées | `Get-WmiObject` (utiliser `Get-CimInstance`) | Versions:41 |
| `PSAvoidUsingInvokeExpression` | `Invoke-Expression` dangereux | `Invoke-Expression $EntreeUtilisateur` | Anti-patterns:507 |

### Règles de Formatage (Niveau Avertissement)

| Nom de la Règle | Ce qu'elle Détecte | Configuration | Section AGENTS.md |
|-----------------|-------------------|---------------|-------------------|
| `PSPlaceOpenBrace` | Placement de l'accolade ouvrante | Même ligne (style K&R) | Structure:157 |
| `PSPlaceCloseBrace` | Placement de l'accolade fermante | Nouvelle ligne après | Structure:157 |
| `PSUseConsistentIndentation` | Cohérence de l'indentation | 4 espaces (pas de tabs) | Structure:157 |
| `PSUseConsistentWhitespace` | Cohérence des espaces | Autour des opérateurs, accolades | Structure:157 |
| `PSAlignAssignmentStatement` | Alignement des assignations | Aligner `=` dans les hashtables | Structure:157 |
| `PSAvoidLongLines` | Longueur de ligne | Max 115 caractères | Structure:157 |
| `PSAvoidSemicolonsAsLineTerminators` | Points-virgules en fin de ligne | Pas de points-virgules | Structure:157 |
| `PSAvoidTrailingWhitespace` | Espaces en fin de ligne | Supprimer les espaces de fin | Structure:157 |

### Règles de Meilleures Pratiques (Avertissement/Information)

| Nom de la Règle | Ce qu'elle Détecte | Sévérité | Section AGENTS.md |
|-----------------|-------------------|----------|-------------------|
| `PSUseShouldProcessForStateChangingFunctions` | Fonctions modifiant l'état sans ShouldProcess | Warning | Anti-patterns:485 |
| `PSUseSupportsShouldProcess` | ShouldProcess utilisé sans `SupportsShouldProcess` | Warning | Anti-patterns:485 |
| `PSShouldProcess` | `SupportsShouldProcess` déclaré mais non appelé | Warning | Anti-patterns:485 |
| `PSProvideCommentHelp` | Aide basée sur commentaires manquante | Information | Documentation:400 |
| `PSUseProcessBlockForPipelineCommand` | Fonctions pipeline sans bloc `process` | Warning | Structure:137 |
| `PSUseToExportFieldsInManifest` | Wildcards dans les exports du manifeste de module | Warning | Tests:283 |
| `PSMissingModuleManifestField` | Champs de manifeste requis manquants | Warning | Tests:283 |
| `PSUsePSCredentialType` | Paramètres de credential non-PSCredential | Warning | Sécurité:180 |
| `PSAvoidUsingPositionalParameters` | Paramètres positionnels utilisés | Information | Structure:118 |

### Règles de Compatibilité (Erreur/Avertissement)

| Nom de la Règle | Ce qu'elle Détecte | Section AGENTS.md |
|-----------------|-------------------|-------------------|
| `PSUseCompatibleSyntax` | Syntaxe incompatible avec les versions PowerShell cibles | Versions:21 |
| `PSUseCompatibleCmdlets` | Cmdlets non disponibles dans les environnements cibles | Versions:21 |
| `PSUseCompatibleCommands` | Commandes non disponibles dans les environnements cibles | Versions:21 |
| `PSUseCompatibleTypes` | Types .NET non disponibles dans les frameworks cibles | Versions:21 |

**Compatibilité Cible** :
- PowerShell 5.1 (Windows PowerShell)
- PowerShell 7.0, 7.1, 7.2, 7.3, 7.4 (PowerShell Core)
- Windows, Linux, macOS

---

## Référence des Règles Personnalisées

Ces règles étendent PSScriptAnalyzer avec des validations non disponibles dans les règles intégrées.

### 1. Measure-AcronymCasing

**Sévérité** : Warning

**Ce qu'elle Détecte** : Casse incorrecte des acronymes dans les noms de fonction/cmdlet

**Règles** :
- Acronymes de 2 lettres : TOUT EN MAJUSCULES (AD, VM, PS, IT, OS, IO, DB, UI, ID, IP)
- Acronymes de 3+ lettres : PascalCase (Html, Sql, Xml, Json, Csv, Api, Http, Smtp, Ftp)

**Exemples** :

❌ **Incorrect** :
```powershell
function Get-AdUser { }      # Devrait être Get-ADUser
function Get-HTMLReport { }  # Devrait être Get-HtmlReport
function Get-SQLDatabase { } # Devrait être Get-SqlDatabase
function New-XMLDocument { } # Devrait être New-XmlDocument
```

✅ **Correct** :
```powershell
function Get-ADUser { }      # 2 lettres : TOUT EN MAJUSCULES
function Get-VMHost { }      # 2 lettres : TOUT EN MAJUSCULES
function Get-HtmlReport { }  # 3+ lettres : PascalCase
function Get-SqlDatabase { } # 3+ lettres : PascalCase
function New-XmlDocument { } # 3+ lettres : PascalCase
function Invoke-ApiRequest { } # 3+ lettres : PascalCase
```

**Référence AGENTS.md** : Conventions de Nommage:100

---

### 2. Measure-PathConcatenation

**Sévérité** : Warning

**Ce qu'elle Détecte** : Concaténation de chaînes utilisée pour les chemins de fichiers au lieu de `Join-Path`

**Pourquoi c'est Important** : Les séparateurs de chemin varient selon la plateforme (`\` sur Windows, `/` sur Linux/macOS). Utiliser `Join-Path` assure la compatibilité multiplateforme.

**Exemples** :

❌ **Incorrect** :
```powershell
$CheminLog = $env:TEMP + "\logs"
$CheminFichier = $CheminLog + "\app.log"
$CheminConfig = "C:\Config" + "\settings.json"
```

✅ **Correct** :
```powershell
$CheminLog = Join-Path -Path $env:TEMP -ChildPath "logs"
$CheminFichier = Join-Path -Path $CheminLog -ChildPath "app.log"
$CheminConfig = Join-Path -Path "C:\Config" -ChildPath "settings.json"
```

**Référence AGENTS.md** : Compatibilité et Portabilité:347

---

### 3. Measure-EncodingParameter

**Sévérité** : Warning

**Ce qu'elle Détecte** : `Get-Content`, `Set-Content`, `Out-File`, `Add-Content` sans paramètre `-Encoding`

**Pourquoi c'est Important** : L'encodage par défaut varie selon les versions PowerShell et les plateformes, causant des problèmes d'encodage.

**Exemples** :

❌ **Incorrect** :
```powershell
Get-Content -Path ".\fichier.txt"
Set-Content -Path ".\fichier.txt" -Value $Donnees
Out-File -FilePath ".\sortie.txt" -InputObject $Resultat
Add-Content -Path ".\log.txt" -Value $Message
```

✅ **Correct** :
```powershell
Get-Content -Path ".\fichier.txt" -Encoding UTF8
Set-Content -Path ".\fichier.txt" -Value $Donnees -Encoding UTF8
Out-File -FilePath ".\sortie.txt" -InputObject $Resultat -Encoding UTF8
Add-Content -Path ".\log.txt" -Value $Message -Encoding UTF8
```

**Encodages Courants** :
- `UTF8` - Standard pour les fichiers texte multiplateformes
- `UTF8BOM` - UTF-8 avec marque d'ordre des octets
- `UTF8NoBOM` - UTF-8 sans BOM (défaut PowerShell 7+)
- `Unicode` - UTF-16 LE
- `ASCII` - ASCII 7-bit

**Référence AGENTS.md** : Compatibilité et Portabilité:361

---

### 4. Measure-CmdletBindingPresence

**Sévérité** : Warning

**Ce qu'elle Détecte** : Fonctions avec bloc `param()` mais sans attribut `[CmdletBinding()]`

**Pourquoi c'est Important** : `[CmdletBinding()]` active les fonctionnalités de fonction avancée :
- Paramètres communs (`-Verbose`, `-Debug`, `-ErrorAction`, `-WhatIf`)
- Support du pipeline
- Population automatique de `$PSBoundParameters`
- Meilleure gestion des erreurs

**Exemples** :

❌ **Incorrect** :
```powershell
function Get-UserData {
    param(
        [string]$Username
    )
    # [CmdletBinding()] manquant
}
```

✅ **Correct** :
```powershell
function Get-UserData {
    [CmdletBinding()]  # Requis pour les fonctions avancées
    param(
        [Parameter(Mandatory)]
        [string]$Username
    )
    
    Write-Verbose "Récupération des données pour : $Username"  # Fonctionne maintenant !
}
```

**Référence AGENTS.md** : Structure de Code:118

---

## Intégration VS Code

### Configuration

1. **Installer l'Extension PowerShell** :
   - Ouvrir VS Code
   - Aller dans Extensions (Ctrl+Shift+X)
   - Rechercher "PowerShell"
   - Installer "PowerShell" par Microsoft

2. **Copier `.vscode/settings.json` et `ScriptAnalyzer/`** dans votre projet (ou utiliser les paramètres d'espace de travail)

3. **Recharger VS Code** (Ctrl+Shift+P → "Reload Window")

### Fonctionnalités

#### Analyse en Temps Réel

Pendant que vous tapez, PSScriptAnalyzer s'exécute en arrière-plan :

- **Lignes ondulées rouges** = Sévérité Erreur
- **Lignes ondulées jaunes** = Sévérité Avertissement
- **Lignes ondulées bleues** = Sévérité Information

Survolez la ligne ondulée pour voir le message de violation de règle.

#### Panneau Problèmes

Voir tous les problèmes en une fois :

1. Appuyez sur **Ctrl+Shift+M** ou allez dans Affichage → Problèmes
2. Voir toutes les violations groupées par fichier
3. Cliquer sur un problème pour sauter à cette ligne
4. Filtrer par sévérité en utilisant l'icône de filtre

#### Formater le Document

Appliquer toutes les règles de formatage en une fois :

- **Clavier** : Shift+Alt+F
- **Menu** : Clic droit → Formater le Document
- **À la Sauvegarde** : Automatique (si `editor.formatOnSave: true`)

Le formatage applique :
- Style d'accolades K&R
- Indentation de 4 espaces
- Espacement correct
- Adaptation de longueur de ligne (à 115 caractères)

#### Corrections Rapides

Certaines règles fournissent des corrections automatiques :

1. Cliquer sur l'icône d'ampoule (💡) à côté de la violation
2. Sélectionner "Fix: [Nom de la Règle]"
3. Le code est automatiquement corrigé

**Règles avec Corrections Rapides** :
- `PSUseCorrectCasing` - Auto-corriger la casse des cmdlet
- `PSAvoidUsingCmdletAliases` - Remplacer les aliases par les noms complets
- `PSUseConsistentWhitespace` - Ajouter/supprimer les espaces

### Paramètres Utilisateur vs Espace de Travail

**Paramètres d'Espace de Travail** (`.vscode/settings.json`) :
- S'appliquent uniquement à ce projet
- Committés dans git (partagés avec l'équipe)
- Recommandés pour les projets d'équipe

**Paramètres Utilisateur** (Fichier → Préférences → Paramètres) :
- S'appliquent à tous les fichiers PowerShell sur votre machine
- Non committés dans git
- Recommandés pour les préférences personnelles

Pour appliquer ces paramètres globalement :

1. Ouvrir les Paramètres VS Code (Ctrl+,)
2. Rechercher "powershell.scriptAnalysis"
3. Activer "Script Analysis: Enable"
4. Définir "Script Analysis: Settings Path" au chemin complet de `ScriptAnalyzer/PSScriptAnalyzerSettings.psd1`

---

## Liste de Vérification Manuelle

Certains standards d'AGENTS.md ne peuvent pas être automatisés. Utilisez cette liste de vérification pour les revues de code.

### Idempotence ✅

Les scripts doivent vérifier l'état avant de modifier :

```powershell
# Bon - Idempotent
if (-not (Test-Path $CheminDossier)) {
    New-Item -Path $CheminDossier -ItemType Directory
}

# Mauvais - Erreur si exécuté deux fois
New-Item -Path $CheminDossier -ItemType Directory
```

**Référence** : AGENTS.md:385

### Dépréciation de Modules ✅

Vérifier les modules dépréciés :

| Déprécié | Utiliser À la Place |
|----------|---------------------|
| `AzureRM` | `Az` |
| `SQLPS` | `SqlServer` |
| `MSOnline` | `Microsoft.Graph` |

**Référence** : AGENTS.md:41

### Précision de la Documentation ✅

- [ ] L'aide basée sur commentaires correspond à la fonctionnalité réelle
- [ ] Les exemples dans l'aide fonctionnent vraiment
- [ ] Les descriptions de paramètres sont précises
- [ ] Le champ Author reflète le créateur original (pas les modificateurs)

**Référence** : AGENTS.md:400

### Code Généré par IA ✅

Si le code a été généré par IA :

- [ ] Compris ligne par ligne
- [ ] Vérifié que les cmdlets existent vraiment (pas d'hallucinations)
- [ ] Testé dans un environnement isolé
- [ ] Révisé par un humain
- [ ] Aucune info sensible n'a été partagée avec l'IA

**Référence** : AGENTS.md:518

---

## Dépannage

### PSScriptAnalyzer Ne S'exécute Pas

**Symptôme** : Pas de lignes ondulées dans VS Code, pas de sortie d'analyse

**Solutions** :

1. **Vérifier que le module est installé** :
   ```powershell
   Get-Module -ListAvailable PSScriptAnalyzer
   ```
   Si non trouvé :
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
   ```

2. **Vérifier l'extension PowerShell de VS Code** :
   - Extensions → Rechercher "PowerShell" → Doit être installée et activée

3. **Vérifier le chemin des paramètres** :
   - Ouvrir `.vscode/settings.json`
   - S'assurer que `"powershell.scriptAnalysis.settingsPath": "ScriptAnalyzer/PSScriptAnalyzerSettings.psd1"` est correct

4. **Recharger VS Code** :
   - Ctrl+Shift+P → "Reload Window"

### Règles Personnalisées Ne Fonctionnent Pas

**Symptôme** : Les règles intégrées fonctionnent, les règles personnalisées n'apparaissent pas

**Solutions** :

1. **Vérifier le chemin CustomRules** :
   ```powershell
   Test-Path .\ScriptAnalyzer\CustomRules\CustomRules.psm1
   ```

2. **Tester les règles personnalisées manuellement** :
   ```powershell
   Invoke-ScriptAnalyzer -Path .\VotreScript.ps1 `
       -CustomRulePath .\ScriptAnalyzer\CustomRules\CustomRules.psm1 `
       -IncludeDefaultRules
   ```

3. **Vérifier les erreurs de syntaxe dans CustomRules.psm1** :
   ```powershell
   Import-Module .\ScriptAnalyzer\CustomRules\CustomRules.psm1 -Force
   Get-Command -Module CustomRules
   ```

---

## Maintenance

### Mise à Jour de PSScriptAnalyzer

Vérifier les mises à jour mensuellement :

```powershell
# Vérifier la version actuelle
Get-Module -ListAvailable PSScriptAnalyzer

# Mettre à jour vers la dernière version
Update-Module -Name PSScriptAnalyzer -Force

# Vérifier la nouvelle version
Get-Module -ListAvailable PSScriptAnalyzer
```

Après la mise à jour, tester contre votre base de code :

```powershell
Invoke-ScriptAnalyzer -Path .\MonModule\ -Recurse -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1
```

### Ajouter de Nouvelles Règles Personnalisées

1. **Éditer `ScriptAnalyzer/CustomRules/CustomRules.psm1`**

2. **Créer une nouvelle fonction** :
   ```powershell
   function Measure-VotreNouvelleRegle {
       [CmdletBinding()]
       [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
       param(
           [Parameter(Mandatory)]
           [ValidateNotNullOrEmpty()]
           [System.Management.Automation.Language.ScriptBlockAst]
           $ScriptBlockAst
       )
       
       process {
           # Votre logique de règle ici
       }
   }
   ```

3. **Exporter la fonction** :
   ```powershell
   Export-ModuleMember -Function 'Measure-VotreNouvelleRegle'
   ```

4. **Tester la règle** :
   ```powershell
   Import-Module .\ScriptAnalyzer\CustomRules\CustomRules.psm1 -Force
   Invoke-ScriptAnalyzer -Path .\TestScript.ps1 -CustomRulePath .\ScriptAnalyzer\CustomRules\CustomRules.psm1
   ```

---

## Ressources Additionnelles

- **GitHub PSScriptAnalyzer** : https://github.com/PowerShell/PSScriptAnalyzer
- **Documentation des Règles** : https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation
- **AGENTS.md** : Guide complet des standards PowerShell (ce dépôt)
- **Meilleures Pratiques PowerShell** : https://poshcode.gitbook.io/powershell-practice-and-style/

---

**Questions ou Problèmes ?**  
Ouvrir une issue : https://github.com/OlickQC/PSScriptAnalyzer-BestPractices/issues
