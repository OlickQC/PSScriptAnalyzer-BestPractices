# PSScriptAnalyzer Configuration Guide

This document provides comprehensive documentation for the PSScriptAnalyzer configuration used in this project.

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration Overview](#configuration-overview)
- [Built-in Rules Reference](#built-in-rules-reference)
- [Custom Rules Reference](#custom-rules-reference)
- [VS Code Integration](#vs-code-integration)
- [Manual Checklist](#manual-checklist)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

---

## Quick Start

### Installation

1. **Install PSScriptAnalyzer module**:
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
   ```

2. **Verify installation**:
   ```powershell
   Get-Module -ListAvailable PSScriptAnalyzer
   ```

3. **Test the configuration**:
   ```powershell
   Invoke-ScriptAnalyzer -Path .\YourScript.ps1 -Settings .\PSScriptAnalyzerSettings.psd1
   ```

### Running Analysis

**Single file**:
```powershell
Invoke-ScriptAnalyzer -Path .\Script.ps1 -Settings .\PSScriptAnalyzerSettings.psd1
```

**Entire directory (recursive)**:
```powershell
Invoke-ScriptAnalyzer -Path .\MyModule\ -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

**Filter by severity**:
```powershell
Invoke-ScriptAnalyzer -Path .\Script.ps1 -Settings .\PSScriptAnalyzerSettings.psd1 -Severity Error
```

**Export results to file**:
```powershell
Invoke-ScriptAnalyzer -Path .\Script.ps1 -Settings .\PSScriptAnalyzerSettings.psd1 | 
    Export-Csv -Path .\AnalysisResults.csv -NoTypeInformation
```

---

## Configuration Overview

### Files Included

| File | Purpose |
|------|---------|
| `PSScriptAnalyzerSettings.psd1` | Main configuration with 50+ built-in rules |
| `CustomRules/CustomRules.psm1` | 4 custom rules for additional validation |
| `.vscode/settings.json` | VS Code workspace integration settings |
| `AGENTS.md` | Complete PowerShell standards documentation |

### Severity Levels

| Severity | Color (VS Code) | Description | When to Fix |
|----------|----------------|-------------|-------------|
| **Error** | Red | Critical issues that MUST be fixed | Before committing |
| **Warning** | Yellow | Issues that SHOULD be fixed | Before committing |
| **Information** | Blue | Suggestions for improvement | As time permits |

### Coverage

**What PSScriptAnalyzer Enforces (~85% of AGENTS.md standards)**:
- ✅ Security (credentials, hardcoding, Invoke-Expression)
- ✅ Naming conventions (Verb-Noun, approved verbs)
- ✅ Code quality (aliases, empty catch, Write-Host)
- ✅ Formatting (braces, indentation, line length)
- ✅ Best practices (CmdletBinding, ShouldProcess)

**What Requires Manual Review (~15%)**:
- ❌ Semantic correctness (does code do what it claims?)
- ❌ Idempotency (checking state before modification)
- ❌ Documentation accuracy
- ❌ Module deprecation (AzureRM → Az)

---

## Built-in Rules Reference

### Security Rules (Error Level)

| Rule Name | What It Detects | Example Violation | AGENTS.md Section |
|-----------|----------------|-------------------|-------------------|
| `PSAvoidUsingPlainTextForPassword` | Parameters with "password" in name but not `[SecureString]` | `param([string]$Password)` | Sécurité:180 |
| `PSAvoidUsingConvertToSecureStringWithPlainText` | Using `-AsPlainText` with `ConvertTo-SecureString` | `ConvertTo-SecureString "pass" -AsPlainText` | Sécurité:180 |
| `PSAvoidUsingComputerNameHardcoded` | Hardcoded server/computer names | `$Server = "PROD-SQL-01"` | Anti-patterns:471 |
| `PSAvoidUsingUsernameAndPasswordParams` | Separate username/password params instead of PSCredential | `param($Username, $Password)` | Sécurité:180 |
| `PSReservedParams` | Use of reserved parameter names | `param($WhatIf)` | Structure:118 |

### Naming Convention Rules (Warning Level)

| Rule Name | What It Detects | Example Violation | AGENTS.md Section |
|-----------|----------------|-------------------|-------------------|
| `PSUseApprovedVerbs` | Non-approved PowerShell verbs | `function Create-File` (use `New-File`) | Conventions:48 |
| `PSUseSingularNouns` | Plural nouns in function names | `function Get-Users` (use `Get-User`) | Conventions:48 |
| `PSReservedCmdletChar` | Invalid characters in cmdlet names | `function Get-My#Data` | Conventions:48 |
| `PSUseCorrectCasing` | Incorrect casing (not PascalCase) | `function get-data` | Conventions:83 |

### Code Quality Rules (Warning Level)

| Rule Name | What It Detects | Example Violation | AGENTS.md Section |
|-----------|----------------|-------------------|-------------------|
| `PSAvoidUsingCmdletAliases` | Aliases used in scripts | `gci`, `?`, `%`, `select` | Anti-patterns:498 |
| `PSAvoidUsingEmptyCatchBlock` | Empty catch blocks (silent errors) | `try {...} catch {}` | Gestion d'Erreurs:310 |
| `PSAvoidUsingWriteHost` | `Write-Host` in scripts | `Write-Host "message"` | Anti-patterns:460 |
| `PSUseDeclaredVarsMoreThanAssignments` | Variables declared but never used | `$UnusedVar = "value"` | Structure:83 |
| `PSAvoidGlobalVars` | Global variable usage | `$global:MyVar = "value"` | Structure:118 |
| `PSAvoidDefaultValueSwitchParameter` | Switch params defaulting to `$true` | `param([switch]$Force = $true)` | Structure:118 |
| `PSAvoidUsingWMICmdlet` | Deprecated WMI cmdlets | `Get-WmiObject` (use `Get-CimInstance`) | Versions:41 |
| `PSAvoidUsingInvokeExpression` | Dangerous `Invoke-Expression` | `Invoke-Expression $UserInput` | Anti-patterns:507 |

### Formatting Rules (Warning Level)

| Rule Name | What It Detects | Configuration | AGENTS.md Section |
|-----------|----------------|---------------|-------------------|
| `PSPlaceOpenBrace` | Opening brace placement | Same line (K&R style) | Structure:157 |
| `PSPlaceCloseBrace` | Closing brace placement | New line after | Structure:157 |
| `PSUseConsistentIndentation` | Indentation consistency | 4 spaces (no tabs) | Structure:157 |
| `PSUseConsistentWhitespace` | Whitespace consistency | Around operators, braces | Structure:157 |
| `PSAlignAssignmentStatement` | Assignment alignment | Align `=` in hashtables | Structure:157 |
| `PSAvoidLongLines` | Line length | Max 115 characters | Structure:157 |
| `PSAvoidSemicolonsAsLineTerminators` | Semicolons at end of lines | No semicolons | Structure:157 |
| `PSAvoidTrailingWhitespace` | Trailing whitespace | Remove trailing spaces | Structure:157 |

### Best Practices Rules (Warning/Information)

| Rule Name | What It Detects | Severity | AGENTS.md Section |
|-----------|----------------|----------|-------------------|
| `PSUseShouldProcessForStateChangingFunctions` | State-changing functions missing ShouldProcess | Warning | Anti-patterns:485 |
| `PSUseSupportsShouldProcess` | ShouldProcess used without `SupportsShouldProcess` | Warning | Anti-patterns:485 |
| `PSShouldProcess` | `SupportsShouldProcess` declared but not called | Warning | Anti-patterns:485 |
| `PSProvideCommentHelp` | Missing comment-based help | Information | Documentation:400 |
| `PSUseProcessBlockForPipelineCommand` | Pipeline functions missing `process` block | Warning | Structure:137 |
| `PSUseToExportFieldsInManifest` | Wildcards in module manifest exports | Warning | Tests:283 |
| `PSMissingModuleManifestField` | Missing required manifest fields | Warning | Tests:283 |
| `PSUsePSCredentialType` | Non-PSCredential credential parameters | Warning | Sécurité:180 |
| `PSAvoidUsingPositionalParameters` | Positional parameters used | Information | Structure:118 |

### Compatibility Rules (Error/Warning)

| Rule Name | What It Detects | AGENTS.md Section |
|-----------|----------------|-------------------|
| `PSUseCompatibleSyntax` | Syntax incompatible with target PowerShell versions | Versions:21 |
| `PSUseCompatibleCmdlets` | Cmdlets not available in target environments | Versions:21 |
| `PSUseCompatibleCommands` | Commands not available in target environments | Versions:21 |
| `PSUseCompatibleTypes` | .NET types not available in target frameworks | Versions:21 |

**Target Compatibility**:
- PowerShell 5.1 (Windows PowerShell)
- PowerShell 7.0, 7.1, 7.2, 7.3, 7.4 (PowerShell Core)
- Windows, Linux, macOS

---

## Custom Rules Reference

These rules extend PSScriptAnalyzer with validation not available in built-in rules.

### 1. Measure-AcronymCasing

**Severity**: Warning

**What It Detects**: Incorrect acronym casing in function/cmdlet names

**Rules**:
- 2-letter acronyms: ALL CAPS (AD, VM, PS, IT, OS, IO, DB, UI, ID, IP)
- 3+ letter acronyms: PascalCase (Html, Sql, Xml, Json, Csv, Api, Http, Smtp, Ftp)

**Examples**:

❌ **Incorrect**:
```powershell
function Get-AdUser { }      # Should be Get-ADUser
function Get-HTMLReport { }  # Should be Get-HtmlReport
function Get-SQLDatabase { } # Should be Get-SqlDatabase
function New-XMLDocument { } # Should be New-XmlDocument
```

✅ **Correct**:
```powershell
function Get-ADUser { }      # 2-letter: ALL CAPS
function Get-VMHost { }      # 2-letter: ALL CAPS
function Get-HtmlReport { }  # 3+ letter: PascalCase
function Get-SqlDatabase { } # 3+ letter: PascalCase
function New-XmlDocument { } # 3+ letter: PascalCase
function Invoke-ApiRequest { } # 3+ letter: PascalCase
```

**AGENTS.md Reference**: Conventions de Nommage:100

---

### 2. Measure-PathConcatenation

**Severity**: Warning

**What It Detects**: String concatenation used for file paths instead of `Join-Path`

**Why It Matters**: Path separators vary by platform (`\` on Windows, `/` on Linux/macOS). Using `Join-Path` ensures cross-platform compatibility.

**Examples**:

❌ **Incorrect**:
```powershell
$LogPath = $env:TEMP + "\logs"
$FilePath = $LogPath + "\app.log"
$ConfigPath = "C:\Config" + "\settings.json"
```

✅ **Correct**:
```powershell
$LogPath = Join-Path -Path $env:TEMP -ChildPath "logs"
$FilePath = Join-Path -Path $LogPath -ChildPath "app.log"
$ConfigPath = Join-Path -Path "C:\Config" -ChildPath "settings.json"
```

**AGENTS.md Reference**: Compatibilité et Portabilité:347

---

### 3. Measure-EncodingParameter

**Severity**: Warning

**What It Detects**: `Get-Content`, `Set-Content`, `Out-File`, `Add-Content` without `-Encoding` parameter

**Why It Matters**: Default encoding varies across PowerShell versions and platforms, leading to encoding issues.

**Examples**:

❌ **Incorrect**:
```powershell
Get-Content -Path ".\file.txt"
Set-Content -Path ".\file.txt" -Value $Data
Out-File -FilePath ".\output.txt" -InputObject $Result
Add-Content -Path ".\log.txt" -Value $Message
```

✅ **Correct**:
```powershell
Get-Content -Path ".\file.txt" -Encoding UTF8
Set-Content -Path ".\file.txt" -Value $Data -Encoding UTF8
Out-File -FilePath ".\output.txt" -InputObject $Result -Encoding UTF8
Add-Content -Path ".\log.txt" -Value $Message -Encoding UTF8
```

**Common Encodings**:
- `UTF8` - Standard for cross-platform text files
- `UTF8BOM` - UTF-8 with byte order mark
- `UTF8NoBOM` - UTF-8 without BOM (PowerShell 7+ default)
- `Unicode` - UTF-16 LE
- `ASCII` - 7-bit ASCII

**AGENTS.md Reference**: Compatibilité et Portabilité:361

---

### 4. Measure-CmdletBindingPresence

**Severity**: Warning

**What It Detects**: Functions with `param()` block but missing `[CmdletBinding()]` attribute

**Why It Matters**: `[CmdletBinding()]` enables advanced function features:
- Common parameters (`-Verbose`, `-Debug`, `-ErrorAction`, `-WhatIf`)
- Pipeline support
- Automatic `$PSBoundParameters` population
- Better error handling

**Examples**:

❌ **Incorrect**:
```powershell
function Get-UserData {
    param(
        [string]$Username
    )
    # Missing [CmdletBinding()]
}
```

✅ **Correct**:
```powershell
function Get-UserData {
    [CmdletBinding()]  # Required for advanced functions
    param(
        [Parameter(Mandatory)]
        [string]$Username
    )
    
    Write-Verbose "Getting data for: $Username"  # Now works!
}
```

**AGENTS.md Reference**: Structure de Code:118

---

## VS Code Integration

### Setup

1. **Install PowerShell Extension**:
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "PowerShell"
   - Install "PowerShell" by Microsoft

2. **Copy `.vscode/settings.json`** to your project (or use workspace settings)

3. **Reload VS Code** (Ctrl+Shift+P → "Reload Window")

### Features

#### Real-Time Analysis

As you type, PSScriptAnalyzer runs in the background:

- **Red squiggly lines** = Error severity
- **Yellow squiggly lines** = Warning severity
- **Blue squiggly lines** = Information severity

Hover over the squiggly line to see the rule violation message.

#### Problems Panel

View all issues at once:

1. Press **Ctrl+Shift+M** or go to View → Problems
2. See all violations grouped by file
3. Click on any issue to jump to that line
4. Filter by severity using the filter icon

#### Format Document

Apply all formatting rules at once:

- **Keyboard**: Shift+Alt+F
- **Menu**: Right-click → Format Document
- **On Save**: Automatic (if `editor.formatOnSave: true`)

Formatting applies:
- K&R brace style
- 4-space indentation
- Correct whitespace
- Line length wrapping (at 115 chars)

#### Quick Fixes

Some rules provide automatic fixes:

1. Click on the lightbulb icon (💡) next to the violation
2. Select "Fix: [Rule Name]"
3. Code is automatically corrected

**Rules with Quick Fixes**:
- `PSUseCorrectCasing` - Auto-correct cmdlet casing
- `PSAvoidUsingCmdletAliases` - Replace aliases with full names
- `PSUseConsistentWhitespace` - Add/remove whitespace

### User vs Workspace Settings

**Workspace Settings** (`.vscode/settings.json`):
- Apply only to this project
- Committed to git (shared with team)
- Recommended for team projects

**User Settings** (File → Preferences → Settings):
- Apply to all PowerShell files on your machine
- Not committed to git
- Recommended for personal preferences

To apply these settings globally:

1. Open VS Code Settings (Ctrl+,)
2. Search for "powershell.scriptAnalysis"
3. Enable "Script Analysis: Enable"
4. Set "Script Analysis: Settings Path" to the full path of `PSScriptAnalyzerSettings.psd1`

---

## Manual Checklist

Some standards from AGENTS.md cannot be automated. Use this checklist for code reviews.

### Idempotency ✅

Scripts should check state before modifying:

```powershell
# Good - Idempotent
if (-not (Test-Path $FolderPath)) {
    New-Item -Path $FolderPath -ItemType Directory
}

# Bad - Will error if run twice
New-Item -Path $FolderPath -ItemType Directory
```

**Reference**: AGENTS.md:385

### Module Deprecation ✅

Check for deprecated modules:

| Deprecated | Use Instead |
|------------|-------------|
| `AzureRM` | `Az` |
| `SQLPS` | `SqlServer` |
| `MSOnline` | `Microsoft.Graph` |

**Reference**: AGENTS.md:41

### Documentation Accuracy ✅

- [ ] Comment-based help matches actual functionality
- [ ] Examples in help actually work
- [ ] Parameter descriptions are accurate
- [ ] Author field reflects original creator (not modifiers)

**Reference**: AGENTS.md:400

### AI-Generated Code ✅

If code was AI-generated:

- [ ] Understood line by line
- [ ] Verified cmdlets actually exist (no hallucinations)
- [ ] Tested in isolated environment
- [ ] Reviewed by human
- [ ] No sensitive info was shared with AI

**Reference**: AGENTS.md:518

### Error Handling Semantics ✅

PSScriptAnalyzer detects empty catch blocks, but can't verify error handling is *correct*:

```powershell
# Structure is valid, but is this the right error handling?
try {
    Get-Item -Path $FilePath -ErrorAction Stop
}
catch [System.IO.FileNotFoundException] {
    Write-Warning "File not found: $FilePath"
    # Is this the appropriate action? Manual review required.
}
```

**Reference**: AGENTS.md:310

---

## Troubleshooting

### PSScriptAnalyzer Not Running

**Symptom**: No squiggly lines in VS Code, no analysis output

**Solutions**:

1. **Verify module is installed**:
   ```powershell
   Get-Module -ListAvailable PSScriptAnalyzer
   ```
   If not found:
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
   ```

2. **Check VS Code PowerShell extension**:
   - Extensions → Search "PowerShell" → Should be installed and enabled

3. **Verify settings path**:
   - Open `.vscode/settings.json`
   - Ensure `"powershell.scriptAnalysis.settingsPath": "PSScriptAnalyzerSettings.psd1"` is correct
   - Path is relative to workspace root

4. **Reload VS Code**:
   - Ctrl+Shift+P → "Reload Window"

5. **Check PowerShell extension logs**:
   - View → Output → Select "PowerShell Extension" from dropdown
   - Look for errors

### Custom Rules Not Working

**Symptom**: Built-in rules work, custom rules don't appear

**Solutions**:

1. **Verify CustomRules path**:
   ```powershell
   Test-Path .\CustomRules\CustomRules.psm1
   ```

2. **Test custom rules manually**:
   ```powershell
   Invoke-ScriptAnalyzer -Path .\YourScript.ps1 `
       -CustomRulePath .\CustomRules\CustomRules.psm1 `
       -IncludeDefaultRules
   ```

3. **Check for syntax errors in CustomRules.psm1**:
   ```powershell
   Import-Module .\CustomRules\CustomRules.psm1 -Force
   Get-Command -Module CustomRules
   ```

4. **Verify rule names**:
   Custom rules must start with `Measure-*` or `Test-*`

### Performance Issues

**Symptom**: VS Code is slow when editing PowerShell files

**Solutions**:

1. **Disable analysis for large files**:
   Add to `.vscode/settings.json`:
   ```json
   "powershell.scriptAnalysis.maximumFileSizeKB": 500
   ```

2. **Reduce rule count**:
   Comment out rarely-needed rules in `PSScriptAnalyzerSettings.psd1`

3. **Exclude compatibility checks**:
   Compatibility rules are slow. If not needed, disable in settings file:
   ```powershell
   ExcludeRules = @(
       'PSUseCompatibleSyntax'
       'PSUseCompatibleCmdlets'
       'PSUseCompatibleCommands'
       'PSUseCompatibleTypes'
   )
   ```

### False Positives

**Symptom**: Rule violation reported incorrectly

**Solutions**:

1. **Suppress specific violation** (use sparingly):
   ```powershell
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
   param()
   Write-Host "This is justified because..."
   ```

2. **Exclude rule globally** (if consistently problematic):
   Add to `PSScriptAnalyzerSettings.psd1`:
   ```powershell
   ExcludeRules = @('RuleName')
   ```

3. **Report issue**:
   - For built-in rules: https://github.com/PowerShell/PSScriptAnalyzer/issues
   - For custom rules: https://github.com/OlickQC/PSScriptAnalyzer-BestPractices/issues

---

## Maintenance

### Updating PSScriptAnalyzer

Check for updates monthly:

```powershell
# Check current version
Get-Module -ListAvailable PSScriptAnalyzer

# Update to latest
Update-Module -Name PSScriptAnalyzer -Force

# Verify new version
Get-Module -ListAvailable PSScriptAnalyzer
```

After updating, test against your codebase:

```powershell
Invoke-ScriptAnalyzer -Path .\MyModule\ -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

### Adding New Custom Rules

1. **Edit `CustomRules/CustomRules.psm1`**

2. **Create new function**:
   ```powershell
   function Measure-YourNewRule {
       [CmdletBinding()]
       [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
       param(
           [Parameter(Mandatory)]
           [ValidateNotNullOrEmpty()]
           [System.Management.Automation.Language.ScriptBlockAst]
           $ScriptBlockAst
       )
       
       process {
           # Your rule logic here
       }
   }
   ```

3. **Export the function**:
   ```powershell
   Export-ModuleMember -Function 'Measure-YourNewRule'
   ```

4. **Test the rule**:
   ```powershell
   Import-Module .\CustomRules\CustomRules.psm1 -Force
   Invoke-ScriptAnalyzer -Path .\TestScript.ps1 -CustomRulePath .\CustomRules\CustomRules.psm1
   ```

### Modifying Existing Rules

1. **Edit `PSScriptAnalyzerSettings.psd1`**

2. **Find the rule** in the `Rules = @{}` section

3. **Modify parameters**:
   ```powershell
   PSAvoidLongLines = @{
       Enable = $true
       MaximumLineLength = 120  # Changed from 115
   }
   ```

4. **Test changes**:
   ```powershell
   Invoke-ScriptAnalyzer -Path .\YourScript.ps1 -Settings .\PSScriptAnalyzerSettings.psd1
   ```

5. **Reload VS Code** to apply changes

---

## Additional Resources

- **PSScriptAnalyzer GitHub**: https://github.com/PowerShell/PSScriptAnalyzer
- **Rule Documentation**: https://github.com/PowerShell/PSScriptAnalyzer/tree/master/RuleDocumentation
- **AGENTS.md**: Complete PowerShell standards guide (this repository)
- **PowerShell Best Practices**: https://poshcode.gitbook.io/powershell-practice-and-style/

---

**Questions or Issues?**  
Open an issue: https://github.com/OlickQC/PSScriptAnalyzer-BestPractices/issues
