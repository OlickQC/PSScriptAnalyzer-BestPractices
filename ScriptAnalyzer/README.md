# ScriptAnalyzer Configuration

This folder contains PSScriptAnalyzer configuration files for enforcing PowerShell best practices.

## Contents

- **PSScriptAnalyzerSettings.psd1** - Main configuration file with 50+ rules
- **CustomRules/** - Folder containing custom validation rules
  - **CustomRules.psm1** - Custom rules module (4 rules)

## Usage

### From Project Root

When running PSScriptAnalyzer from your project root:

```powershell
Invoke-ScriptAnalyzer -Path .\YourScript.ps1 `
    -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1 `
    -CustomRulePath .\ScriptAnalyzer\CustomRules `
    -IncludeDefaultRules
```

### When Copied to Your Project

If you copy the `ScriptAnalyzer/` folder to your project root:

```powershell
Invoke-ScriptAnalyzer -Path .\YourScript.ps1 `
    -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1 `
    -CustomRulePath .\ScriptAnalyzer\CustomRules `
    -IncludeDefaultRules
```

### VS Code Integration

If using VS Code with the `.vscode/settings.json` from this project, analysis runs automatically.
No need to run commands manually - violations appear as squiggly lines in the editor.

## Custom Rules

The CustomRules module includes:

1. **Measure-AcronymCasing** - Enforces 2-letter ALL CAPS (AD, VM) vs 3+ PascalCase (Html, Sql)
2. **Measure-PathConcatenation** - Detects string concatenation for paths, suggests Join-Path
3. **Measure-EncodingParameter** - Ensures Get-Content/Set-Content specify -Encoding
4. **Measure-CmdletBindingPresence** - Validates [CmdletBinding()] on functions

## More Information

See [README-PSScriptAnalyzer.md](../README-PSScriptAnalyzer.md) in the repository root for complete documentation.
