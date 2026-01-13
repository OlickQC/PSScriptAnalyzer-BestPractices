# PSScriptAnalyzer Best Practices

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![PSScriptAnalyzer](https://img.shields.io/badge/PSScriptAnalyzer-1.21%2B-green.svg)](https://github.com/PowerShell/PSScriptAnalyzer)

Production-ready PSScriptAnalyzer configuration and custom rules that enforce PowerShell best practices, security standards, and code quality guidelines. Perfect for teams wanting to maintain consistent, high-quality PowerShell codebases.

## Features

- **Comprehensive PSScriptAnalyzer Settings** - Pre-configured rules enforcing security, naming conventions, and code quality
- **Custom Validation Rules** - Additional rules not available in PSScriptAnalyzer out-of-the-box:
  - Acronym casing validation (AD, VM vs Html, Sql, Xml)
  - Path concatenation detection (enforces `Join-Path`)
  - Encoding parameter validation for file operations
  - CmdletBinding presence enforcement
- **VS Code Integration** - Seamless integration with Visual Studio Code PowerShell extension
- **Complete Documentation** - Detailed style guide ([AGENTS.md](AGENTS.md)) covering all PowerShell best practices
- **Zero Configuration** - Clone and start using immediately

## Quick Start

### Prerequisites

- PowerShell 5.1+ or PowerShell 7+
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) module
- [Visual Studio Code](https://code.visualstudio.com/) with [PowerShell extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell) (recommended)

### Installation

1. **Install PSScriptAnalyzer** (if not already installed):
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
   ```

2. **Clone this repository**:
   ```bash
   git clone https://github.com/OlickQC/PSScriptAnalyzer-BestPractices.git
   cd PSScriptAnalyzer-BestPractices
   ```

3. **Use in your projects**:
   
   **Option A:** Copy files to your project root
   ```powershell
   Copy-Item PSScriptAnalyzerSettings.psd1 <YourProjectPath>\
   Copy-Item -Recurse CustomRules\ <YourProjectPath>\
   Copy-Item -Recurse .vscode\ <YourProjectPath>\
   ```

   **Option B:** Reference settings from this repository
   ```powershell
   Invoke-ScriptAnalyzer -Path .\YourScript.ps1 -Settings .\PSScriptAnalyzer-BestPractices\PSScriptAnalyzerSettings.psd1
   ```

### Usage

#### Command Line

Run analysis on a single file:
```powershell
Invoke-ScriptAnalyzer -Path .\YourScript.ps1 -Settings .\PSScriptAnalyzerSettings.psd1
```

Run analysis on an entire directory:
```powershell
Invoke-ScriptAnalyzer -Path .\YourModule\ -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

Filter by severity:
```powershell
Invoke-ScriptAnalyzer -Path .\YourScript.ps1 -Settings .\PSScriptAnalyzerSettings.psd1 -Severity Error,Warning
```

#### Visual Studio Code

If you copied `.vscode/settings.json` to your project, PSScriptAnalyzer will automatically:
- Highlight issues with squiggly lines (red = Error, yellow = Warning, blue = Info)
- Show problems in the Problems panel (Ctrl+Shift+M)
- Apply formatting on save (Ctrl+S)
- Format document on command (Shift+Alt+F)

## What's Included

### Configuration Files

| File | Description |
|------|-------------|
| `PSScriptAnalyzerSettings.psd1` | Main configuration with 50+ rules enforcing best practices |
| `CustomRules/CustomRules.psm1` | Custom rules for advanced validation |
| `.vscode/settings.json` | VS Code workspace settings for seamless integration |
| `AGENTS.md` | Complete PowerShell style guide and standards documentation |

### Rules Enforced

#### Security (Error Level)
- No plaintext passwords or hardcoded credentials
- No hardcoded server/computer names
- Mandatory use of PSCredential type for credentials
- Prevention of `Invoke-Expression` usage

#### Code Quality (Warning Level)
- Approved PowerShell verbs only (Get, Set, New, Remove, etc.)
- No cmdlet aliases (gci, ?, %, etc.)
- No empty catch blocks
- Proper error handling patterns
- CmdletBinding on all functions
- Comment-based help required

#### Formatting (Warning Level)
- K&R brace style (opening brace on same line)
- 4-space indentation (no tabs)
- Maximum line length: 115 characters
- No semicolons as line terminators
- Consistent whitespace

#### Custom Rules (Warning Level)
- **Acronym Casing**: 2-letter acronyms ALL CAPS (AD, VM), 3+ letters PascalCase (Html, Sql)
- **Path Operations**: Use `Join-Path` instead of string concatenation
- **Encoding**: Require explicit encoding on Get-Content/Set-Content
- **Advanced Functions**: All functions must have [CmdletBinding()]

## Examples

### Before (❌ Issues Detected)
```powershell
function getdata {
    param($path)
    $file = $path + "\data.txt"
    $content = Get-Content $file
    gci | ? {$_.Length -gt 1MB}
}
```

**Issues Found:**
- Function name not Verb-Noun format
- No [CmdletBinding()]
- Missing comment-based help
- Path concatenation instead of Join-Path
- No encoding specified on Get-Content
- Uses aliases (gci, ?)

### After (✅ Compliant)
```powershell
function Get-DataContent {
    <#
    .SYNOPSIS
        Retrieves data content from file.
    .PARAMETER Path
        Base path to the data directory.
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

- **[README-PSScriptAnalyzer.md](README-PSScriptAnalyzer.md)** - Detailed PSScriptAnalyzer configuration documentation
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines

## Standards Based On

This configuration is based on:
- [Microsoft PowerShell Best Practices](https://docs.microsoft.com/powershell/)
- [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
- Community best practices and real-world experience

## Compatibility

- **PowerShell 5.1** (Windows PowerShell) ✅
- **PowerShell 7+** (PowerShell Core) ✅
- **Cross-platform** (Windows, Linux, macOS) ✅

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-rule`)
3. Commit your changes (`git commit -m 'Add amazing custom rule'`)
4. Push to the branch (`git push origin feature/amazing-rule`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) - The PowerShell static analysis tool
- PowerShell community for best practices and standards
- All contributors to this project

## Support

- **Issues**: [GitHub Issues](https://github.com/OlickQC/PSScriptAnalyzer-BestPractices/issues)
- **Discussions**: [GitHub Discussions](https://github.com/OlickQC/PSScriptAnalyzer-BestPractices/discussions)

---

**Made with ❤️ for the PowerShell community**
