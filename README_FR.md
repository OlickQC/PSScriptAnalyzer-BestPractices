# PSScriptAnalyzer Meilleures Pratiques

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![PSScriptAnalyzer](https://img.shields.io/badge/PSScriptAnalyzer-1.21%2B-green.svg)](https://github.com/PowerShell/PSScriptAnalyzer)

> 🌍 **Autres langues**: [English](README.md) | Français

Configuration PSScriptAnalyzer prête pour la production avec règles personnalisées qui appliquent les meilleures pratiques PowerShell, les standards de sécurité et les directives de qualité de code. Parfait pour les équipes souhaitant maintenir des bases de code PowerShell cohérentes et de haute qualité.

## Fonctionnalités

- **Configuration PSScriptAnalyzer Complète** - Règles pré-configurées appliquant la sécurité, les conventions de nommage et la qualité du code
- **Règles de Validation Personnalisées** - Règles additionnelles non disponibles dans PSScriptAnalyzer :
  - Validation de la casse des acronymes (AD, VM vs Html, Sql, Xml)
  - Détection de concaténation de chemins (impose `Join-Path`)
  - Validation du paramètre d'encodage pour les opérations de fichiers
  - Vérification de la présence de CmdletBinding
- **Intégration VS Code** - Intégration transparente avec l'extension PowerShell de Visual Studio Code
- **Documentation Complète** - Guide de style détaillé ([AGENTS.md](AGENTS.md)) couvrant toutes les meilleures pratiques PowerShell
- **Zéro Configuration** - Clonez et commencez à utiliser immédiatement

## Démarrage Rapide

### Prérequis

- PowerShell 5.1+ ou PowerShell 7+
- Module [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
- [Visual Studio Code](https://code.visualstudio.com/) avec [extension PowerShell](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell) (recommandé)

### Installation

1. **Installer PSScriptAnalyzer** (si pas déjà installé) :
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
   ```

2. **Cloner ce dépôt** :
   ```bash
   git clone https://github.com/OlickQC/PSScriptAnalyzer-BestPractices.git
   cd PSScriptAnalyzer-BestPractices
   ```

3. **Utiliser dans vos projets** :
   
   **Option A :** Copier les fichiers à la racine de votre projet
   ```powershell
   Copy-Item -Recurse ScriptAnalyzer\ <CheminVotreProjet>\
   Copy-Item -Recurse .vscode\ <CheminVotreProjet>\
   ```

   **Option B :** Référencer les paramètres depuis ce dépôt
   ```powershell
   Invoke-ScriptAnalyzer -Path .\VotreScript.ps1 -Settings .\PSScriptAnalyzer-BestPractices\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1
   ```

### Utilisation

#### Ligne de Commande

Analyser un fichier unique :
```powershell
Invoke-ScriptAnalyzer -Path .\VotreScript.ps1 -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1
```

Analyser un répertoire entier :
```powershell
Invoke-ScriptAnalyzer -Path .\VotreModule\ -Recurse -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1
```

Filtrer par sévérité :
```powershell
Invoke-ScriptAnalyzer -Path .\VotreScript.ps1 -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1 -Severity Error,Warning
```

#### Visual Studio Code

Si vous avez copié `.vscode/settings.json` dans votre projet, PSScriptAnalyzer va automatiquement :
- Surligner les problèmes avec des lignes ondulées (rouge = Erreur, jaune = Avertissement, bleu = Info)
- Afficher les problèmes dans le panneau Problèmes (Ctrl+Shift+M)
- Appliquer le formatage lors de la sauvegarde (Ctrl+S)
- Formater le document sur commande (Shift+Alt+F)

## Contenu

### Fichiers de Configuration

| Fichier | Description |
|---------|-------------|
| `ScriptAnalyzer/PSScriptAnalyzerSettings.psd1` | Configuration principale avec 50+ règles appliquant les meilleures pratiques |
| `ScriptAnalyzer/CustomRules/CustomRules.psm1` | Règles personnalisées pour validation avancée |
| `.vscode/settings.json` | Paramètres d'espace de travail VS Code pour intégration transparente |
| `AGENTS.md` | Guide de style PowerShell complet et documentation des standards |

### Règles Appliquées

#### Sécurité (Niveau Erreur)
- Pas de mots de passe en clair ou credentials codés en dur
- Pas de noms de serveur/ordinateur codés en dur
- Utilisation obligatoire du type PSCredential pour les credentials
- Prévention de l'utilisation d'`Invoke-Expression`

#### Qualité du Code (Niveau Avertissement)
- Uniquement les verbes PowerShell approuvés (Get, Set, New, Remove, etc.)
- Pas d'aliases de cmdlet (gci, ?, %, etc.)
- Pas de blocs catch vides
- Patterns appropriés de gestion d'erreurs
- CmdletBinding sur toutes les fonctions
- Aide basée sur commentaires requise

#### Formatage (Niveau Avertissement)
- Style d'accolades K&R (accolade ouvrante sur la même ligne)
- Indentation de 4 espaces (pas de tabulations)
- Longueur de ligne maximale : 115 caractères
- Pas de points-virgules comme terminateurs de ligne
- Espacement cohérent

#### Règles Personnalisées (Niveau Avertissement)
- **Casse des Acronymes** : Acronymes de 2 lettres EN MAJUSCULES (AD, VM), 3+ lettres PascalCase (Html, Sql)
- **Opérations de Chemin** : Utiliser `Join-Path` au lieu de la concaténation de chaînes
- **Encodage** : Exiger un encodage explicite sur Get-Content/Set-Content
- **Fonctions Avancées** : Toutes les fonctions doivent avoir [CmdletBinding()]

## Exemples

### Avant (❌ Problèmes Détectés)
```powershell
function getdata {
    param($path)
    $file = $path + "\data.txt"
    $content = Get-Content $file
    gci | ? {$_.Length -gt 1MB}
}
```

**Problèmes Trouvés :**
- Nom de fonction pas au format Verbe-Nom
- Pas de [CmdletBinding()]
- Aide basée sur commentaires manquante
- Concaténation de chemin au lieu de Join-Path
- Pas d'encodage spécifié sur Get-Content
- Utilise des aliases (gci, ?)

### Après (✅ Conforme)
```powershell
function Get-DataContent {
    <#
    .SYNOPSIS
        Récupère le contenu de données depuis un fichier.
    .PARAMETER Path
        Chemin de base vers le répertoire de données.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    $FilePath = Join-Path -Path $Path -ChildPath "data.txt"
    $Content = Get-Content -Path $FilePath -Encoding UTF8
    Get-ChildItem | Where-Object { $_.Length -gt 1MB }
}
```

## Documentation

- **[AGENTS.md](AGENTS.md)** - Guide de style PowerShell complet et standards (en français)
- **[README-PSScriptAnalyzer.md](README-PSScriptAnalyzer.md)** - Documentation détaillée de la configuration PSScriptAnalyzer (anglais)
- **[README-PSScriptAnalyzer_FR.md](README-PSScriptAnalyzer_FR.md)** - Documentation détaillée de la configuration PSScriptAnalyzer (français)
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Directives de contribution (anglais)

## Standards Basés Sur

Cette configuration est basée sur :
- [Microsoft PowerShell Best Practices](https://docs.microsoft.com/powershell/)
- [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
- Meilleures pratiques de la communauté et expérience réelle

## Compatibilité

- **PowerShell 5.1** (Windows PowerShell) ✅
- **PowerShell 7+** (PowerShell Core) ✅
- **Multiplateforme** (Windows, Linux, macOS) ✅

## Contribution

Les contributions sont les bienvenues ! Veuillez consulter [CONTRIBUTING.md](CONTRIBUTING.md) pour les directives.

1. Forker le dépôt
2. Créer une branche de fonctionnalité (`git checkout -b feature/regle-geniale`)
3. Committer vos changements (`git commit -m 'Ajout règle personnalisée géniale'`)
4. Pousser vers la branche (`git push origin feature/regle-geniale`)
5. Ouvrir une Pull Request

## Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour les détails.

## Remerciements

- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) - L'outil d'analyse statique PowerShell
- Communauté PowerShell pour les meilleures pratiques et standards
- Tous les contributeurs à ce projet

## Support

- **Issues** : [GitHub Issues](https://github.com/OlickQC/PSScriptAnalyzer-BestPractices/issues)
- **Discussions** : [GitHub Discussions](https://github.com/OlickQC/PSScriptAnalyzer-BestPractices/discussions)

---

**Fait avec ❤️ pour la communauté PowerShell**
