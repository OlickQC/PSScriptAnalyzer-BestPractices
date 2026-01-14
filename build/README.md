# Build Scripts

This folder contains PowerShell scripts used by the Azure DevOps pipeline to analyze, report, and format code.

## Scripts Overview

### Invoke-CodeAnalysis.ps1
**Main analysis orchestration script**

Runs PSScriptAnalyzer with custom rules and generates comprehensive reports.

**Parameters:**
- `-Path`: Folder containing PowerShell scripts to analyze
- `-SettingsPath`: Path to PSScriptAnalyzerSettings.psd1
- `-CustomRulePath`: Path to custom rules folder
- `-OutputPath`: Where to save reports
- `-FailOnSeverity`: Severity level that causes failure (Error, Warning, Information)
- `-GenerateHtmlReport`: Switch to generate HTML report
- `-GenerateNUnitReport`: Switch to generate NUnit XML report
- `-PSVersion`: PowerShell version identifier for report naming

**Usage:**
```powershell
.\Invoke-CodeAnalysis.ps1 `
    -Path ".\src" `
    -SettingsPath ".\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1" `
    -CustomRulePath ".\ScriptAnalyzer\CustomRules" `
    -OutputPath ".\reports" `
    -FailOnSeverity "Error" `
    -GenerateHtmlReport `
    -GenerateNUnitReport `
    -PSVersion "7.x"
```

**Exit Codes:**
- `0` = Success (no violations at failure threshold)
- `1` = Analysis failed (violations found)
- `2` = Script error (missing modules, invalid paths, etc.)

---

### ConvertTo-NUnitXml.ps1
**Converts PSScriptAnalyzer results to NUnit XML format**

Generates NUnit XML reports consumable by Azure DevOps test result publishing.

**Function Signature:**
```powershell
ConvertTo-NUnitXml `
    -AnalyzerResults $Results `
    -OutputPath ".\report.xml" `
    -PSVersion "7.x"
```

**NUnit XML Mapping:**
- Each violation = One test case
- Error/Warning severity = Failed test
- Information severity = Passed test (with message)
- Test name format: `"{RuleName} - {FileName}:{Line}"`

**Azure DevOps Integration:**
The generated XML appears in the Azure DevOps "Tests" tab with:
- Failed tests showing violation details
- Stack trace containing file:line:column location
- Filterable by test name and severity

---

### ConvertTo-HtmlReport.ps1
**Generates styled HTML reports from analysis results**

Creates professional, offline-viewable HTML reports with:
- Executive summary with statistics
- Issues grouped by severity
- Issues grouped by file
- Sortable and filterable tables
- Color-coded severity indicators
- No external dependencies (fully self-contained)

**Function Signature:**
```powershell
ConvertTo-HtmlReport `
    -AnalyzerResults $Results `
    -OutputPath ".\report.html" `
    -PSVersion "7.x" `
    -AnalyzedPath ".\src"
```

**Report Features:**
- 📊 Summary cards (Total, Errors, Warnings, Info, Files, Rules)
- 🔍 Client-side search/filter (no server required)
- 📱 Responsive design (works on mobile)
- 🖨️ Print-friendly CSS
- 🎨 Professional gradient header
- ⚡ Fast loading (single HTML file)

**Published As:**
Azure DevOps pipeline publishes HTML reports as artifacts:
- Navigate to pipeline run → Artifacts tab
- Download: `PSScriptAnalyzer-Report-{PSVersion}`
- Open HTML file in any browser

---

### Invoke-AutoFormat.ps1
**Automatically formats PowerShell code using Invoke-Formatter**

Applies PSScriptAnalyzer formatting rules to PowerShell files in-place.

**Parameters:**
- `-Path`: Folder containing PowerShell files to format
- `-SettingsPath`: Path to PSScriptAnalyzerSettings.psd1
- `-OutputPath`: Optional path for summary report
- `-WhatIf`: Preview changes without modifying files

**Usage:**
```powershell
# Preview changes
.\Invoke-AutoFormat.ps1 `
    -Path ".\src" `
    -SettingsPath ".\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1" `
    -WhatIf

# Apply formatting
.\Invoke-AutoFormat.ps1 `
    -Path ".\src" `
    -SettingsPath ".\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1" `
    -OutputPath ".\reports\format-summary.txt"
```

**Formatting Rules Applied:**
- K&R brace style (opening brace on same line)
- 4-space indentation (no tabs)
- Consistent whitespace around operators
- Aligned assignment statements
- Maximum line length: 115 characters
- Correct cmdlet casing

**Pipeline Integration:**
In Azure DevOps, the auto-format job:
1. Runs only if analysis stage fails
2. Formats all PowerShell files in `src/`
3. Commits changes back to PR branch
4. Uses `[skip ci]` to prevent infinite loops

**⚠️ Important:**
- Modifies files in-place
- Always use version control
- Use `-WhatIf` to preview changes first
- Requires `persistCredentials: true` in pipeline for auto-commit

---

## Usage in Azure DevOps Pipeline

The `azure-pipelines.yml` file orchestrates these scripts:

```yaml
# Stage 1: Code Analysis (Matrix: PS 5.1 + PS 7)
- task: PowerShell@2
  inputs:
    filePath: 'build/Invoke-CodeAnalysis.ps1'
    arguments: >-
      -Path "src"
      -SettingsPath "ScriptAnalyzer/PSScriptAnalyzerSettings.psd1"
      -CustomRulePath "ScriptAnalyzer/CustomRules"
      -OutputPath "$(Build.ArtifactStagingDirectory)"
      -FailOnSeverity "Error"
      -GenerateHtmlReport
      -GenerateNUnitReport
      -PSVersion "7.x"

# Publish test results
- task: PublishTestResults@2
  inputs:
    testResultsFormat: 'NUnit'
    testResultsFiles: '**/*PSScriptAnalyzer*.xml'

# Publish HTML artifacts
- task: PublishPipelineArtifact@1
  inputs:
    targetPath: '$(Build.ArtifactStagingDirectory)'
    artifact: 'PSScriptAnalyzer-Report-7.x'

# Stage 2: Auto-Format (if Stage 1 fails)
- task: PowerShell@2
  inputs:
    filePath: 'build/Invoke-AutoFormat.ps1'
    arguments: >-
      -Path "src"
      -SettingsPath "ScriptAnalyzer/PSScriptAnalyzerSettings.psd1"
```

## Local Usage (Outside Pipeline)

You can run these scripts locally for development:

### Analyze Code Locally
```powershell
# Full analysis with reports
.\build\Invoke-CodeAnalysis.ps1 `
    -Path ".\src" `
    -SettingsPath ".\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1" `
    -CustomRulePath ".\ScriptAnalyzer\CustomRules" `
    -OutputPath ".\local-reports" `
    -FailOnSeverity "Warning" `
    -GenerateHtmlReport `
    -GenerateNUnitReport `
    -PSVersion "local" `
    -Verbose

# Open HTML report
Start-Process ".\local-reports\PSScriptAnalyzer-Report-local.html"
```

### Format Code Locally
```powershell
# Preview formatting changes
.\build\Invoke-AutoFormat.ps1 `
    -Path ".\src" `
    -SettingsPath ".\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1" `
    -WhatIf

# Apply formatting
.\build\Invoke-AutoFormat.ps1 `
    -Path ".\src" `
    -SettingsPath ".\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1" `
    -Verbose
```

## Script Requirements

All build scripts require:
- **PowerShell 5.1+** or **PowerShell 7+**
- **PSScriptAnalyzer module** (automatically installed in pipeline)

Scripts are designed to work cross-platform:
- ✅ Windows (PowerShell 5.1 and 7+)
- ✅ Linux (PowerShell 7+)
- ✅ macOS (PowerShell 7+)

## Modifying Build Scripts

When modifying these scripts:

1. **Follow AGENTS.md standards** - Scripts must pass PSScriptAnalyzer
2. **Test locally first** - Run scripts with `-WhatIf` and `-Verbose`
3. **Test both PS versions** - Test on PowerShell 5.1 AND 7.x
4. **Update documentation** - Update this README with changes
5. **Add error handling** - Use try/catch with specific exceptions
6. **Support -WhatIf** - For scripts that modify files
7. **Provide verbose output** - Use `Write-Verbose` for debugging

## Troubleshooting

### "PSScriptAnalyzer module not found"
```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

### "Custom rules module not found"
Ensure the path to CustomRules.psm1 is correct:
```powershell
Test-Path ".\ScriptAnalyzer\CustomRules\CustomRules.psm1"
```

### "Permission denied" when auto-formatting
In Azure DevOps, ensure:
```yaml
- checkout: self
  persistCredentials: true  # Required for git push
```

### HTML report displays incorrectly
- Ensure UTF8 encoding was used
- Try opening in different browser
- Check browser console for JavaScript errors

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on contributing to build scripts.

---

**Note:** These build scripts are production-ready and used in the Azure DevOps pipeline. They demonstrate PowerShell best practices and are themselves validated by PSScriptAnalyzer.
