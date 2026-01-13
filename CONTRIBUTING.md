# Contributing to PSScriptAnalyzer Best Practices

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Contribution Workflow](#contribution-workflow)
- [Custom Rule Guidelines](#custom-rule-guidelines)
- [Testing Your Changes](#testing-your-changes)
- [Style Guide](#style-guide)
- [Commit Messages](#commit-messages)

---

## Code of Conduct

This project follows the standard open-source code of conduct:

- **Be respectful** and constructive in all interactions
- **Welcome newcomers** and help them learn
- **Focus on the code**, not the person
- **Assume good intentions** from contributors
- **Report inappropriate behavior** to the maintainers

---

## How Can I Contribute?

### Reporting Bugs

Found a bug? Please open an issue with:

1. **Clear title** describing the problem
2. **Steps to reproduce** the issue
3. **Expected behavior** vs **actual behavior**
4. **Environment details**:
   - PowerShell version (`$PSVersionTable`)
   - PSScriptAnalyzer version (`Get-Module PSScriptAnalyzer`)
   - Operating system (Windows, Linux, macOS)
5. **Example code** that triggers the bug (if applicable)

**Example**:
```markdown
**Title**: Custom rule Measure-AcronymCasing fails on filters

**Description**: 
The Measure-AcronymCasing rule throws an error when analyzing a 
function that uses advanced filters.

**Steps to Reproduce**:
1. Create a function: `function Get-HTMLData { [CmdletBinding()] param() }`
2. Run: `Invoke-ScriptAnalyzer -Path .\test.ps1 -CustomRulePath .\ScriptAnalyzer\CustomRules`
3. Error occurs: ...

**Expected**: Should warn about HTML → Html
**Actual**: Throws NullReferenceException

**Environment**:
- PowerShell 7.4.1
- PSScriptAnalyzer 1.22.0
- Windows 11
```

### Suggesting Enhancements

Have an idea for improvement? Open an issue with:

1. **Clear description** of the enhancement
2. **Use case**: Why is this valuable?
3. **Proposed solution** (if you have one)
4. **Alternatives considered**
5. **Impact**: Does this change existing behavior?

**Example**:
```markdown
**Title**: Add custom rule for PSCustomObject property casing

**Description**:
Add a rule that validates PSCustomObject properties use PascalCase.

**Use Case**:
AGENTS.md requires PascalCase for all variables. PSCustomObject 
properties should follow the same standard.

**Proposed Solution**:
New rule: Measure-PSCustomObjectPropertyCasing
- Detects PSCustomObject creation
- Validates all properties are PascalCase
- Suggests corrections

**Impact**: New rule, no breaking changes.
```

### Pull Requests

Want to contribute code? Awesome! See [Contribution Workflow](#contribution-workflow) below.

---

## Development Setup

### Prerequisites

1. **PowerShell 5.1+** or **PowerShell 7+**
   ```powershell
   $PSVersionTable.PSVersion
   ```

2. **PSScriptAnalyzer module**
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
   ```

3. **Pester module** (for testing)
   ```powershell
   Install-Module -Name Pester -MinimumVersion 5.0 -Scope CurrentUser -Force
   ```

4. **Git** (for version control)

5. **VS Code** (recommended) with PowerShell extension

### Fork and Clone

1. **Fork** this repository on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/PSScriptAnalyzer-BestPractices.git
   cd PSScriptAnalyzer-BestPractices
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/OlickQC/PSScriptAnalyzer-BestPractices.git
   ```

4. **Verify remotes**:
   ```bash
   git remote -v
   ```
   Should show:
   ```
   origin    https://github.com/YOUR-USERNAME/PSScriptAnalyzer-BestPractices.git (fetch)
   origin    https://github.com/YOUR-USERNAME/PSScriptAnalyzer-BestPractices.git (push)
   upstream  https://github.com/OlickQC/PSScriptAnalyzer-BestPractices.git (fetch)
   upstream  https://github.com/OlickQC/PSScriptAnalyzer-BestPractices.git (push)
   ```

---

## Contribution Workflow

### 1. Create a Branch

Always create a feature branch from `main`:

```bash
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name
```

**Branch Naming**:
- `feature/` - New features (e.g., `feature/add-hashtable-casing-rule`)
- `fix/` - Bug fixes (e.g., `fix/acronym-casing-regex`)
- `docs/` - Documentation only (e.g., `docs/update-readme`)
- `refactor/` - Code refactoring (e.g., `refactor/simplify-path-detection`)

### 2. Make Your Changes

Edit the relevant files following the [Style Guide](#style-guide).

**Common Changes**:
- Add/modify custom rules: Edit `ScriptAnalyzer/CustomRules/CustomRules.psm1`
- Add/modify built-in rule config: Edit `ScriptAnalyzer/PSScriptAnalyzerSettings.psd1`
- Update standards: Edit `AGENTS.md`
- Update documentation: Edit `README.md` or `README-PSScriptAnalyzer.md`

### 3. Test Your Changes

See [Testing Your Changes](#testing-your-changes) section below.

### 4. Commit Your Changes

```bash
git add .
git commit -m "Add feature: Your feature description"
```

See [Commit Messages](#commit-messages) for format guidelines.

### 5. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 6. Create Pull Request

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Fill out the PR template:
   - **Title**: Clear, descriptive summary
   - **Description**: What changed and why
   - **Related Issues**: Link any related issues (#123)
   - **Testing**: How you tested the changes
   - **Breaking Changes**: Any breaking changes?

4. Submit the PR

### 7. Code Review

Maintainers will review your PR and may:
- **Approve and merge** - Great job!
- **Request changes** - Please address feedback
- **Ask questions** - Clarification needed

Be responsive to feedback and iterate as needed.

---

## Custom Rule Guidelines

When creating new custom rules:

### Rule Structure

```powershell
function Measure-YourRuleName {
    <#
    .SYNOPSIS
        Brief description of what the rule detects.
    
    .DESCRIPTION
        Detailed description including:
        - What it detects
        - Why it matters (reference AGENTS.md section)
        - Examples of violations
    
    .PARAMETER ScriptBlockAst
        AST of the script to analyze.
    
    .EXAMPLE
        Measure-YourRuleName -ScriptBlockAst $ScriptBlockAst
    
    .OUTPUTS
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )
    
    process {
        try {
            $Results = @()
            
            # Your detection logic here
            
            # Create diagnostic records for violations
            $Result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                Message  = "Clear message explaining the violation"
                Extent   = $ViolatingElement.Extent
                RuleName = $PSCmdlet.MyInvocation.InvocationName
                Severity = 'Warning'  # Or 'Error', 'Information'
            }
            $Results += $Result
            
            return $Results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
```

### Rule Requirements

1. **Function name**: Must start with `Measure-` or `Test-`
2. **CmdletBinding**: Required
3. **OutputType**: Must specify `DiagnosticRecord[]`
4. **Comment-based help**: Required (SYNOPSIS, DESCRIPTION, EXAMPLE)
5. **Error handling**: Use try/catch with `ThrowTerminatingError`
6. **AGENTS.md reference**: Link to relevant section in description

### Severity Guidelines

| Severity | Use When |
|----------|----------|
| **Error** | Security vulnerabilities, breaking issues, syntax errors |
| **Warning** | Best practice violations, potential bugs, maintainability issues |
| **Information** | Style suggestions, minor improvements, optional enhancements |

### Rule Message Guidelines

Messages should be:
- **Clear and actionable**: Tell the user what's wrong and how to fix it
- **Specific**: Include the violating element name/value
- **Helpful**: Explain why this matters (briefly)

**Good Messages**:
```powershell
"Function 'Get-AdUser' contains incorrectly cased 2-letter acronym 'Ad'. Should be 'AD' (ALL CAPS for 2-letter acronyms)."

"Avoid string concatenation for file paths. Use 'Join-Path -Path <path> -ChildPath <child>' for cross-platform compatibility."
```

**Bad Messages**:
```powershell
"Casing error"  # Not specific enough

"You did something wrong"  # Not helpful

"This is bad and you should feel bad"  # Not professional
```

### Export Your Rule

Add to the `Export-ModuleMember` at the end of `ScriptAnalyzer/CustomRules/CustomRules.psm1`:

```powershell
Export-ModuleMember -Function @(
    'Measure-AcronymCasing'
    'Measure-PathConcatenation'
    'Measure-EncodingParameter'
    'Measure-CmdletBindingPresence'
    'Measure-YourNewRule'  # Add here
)
```

---

## Testing Your Changes

### Manual Testing

1. **Test the rule directly**:
   ```powershell
   # Create a test script with known violations
   @'
   function Get-AdUser { }
   '@ | Set-Content -Path .\test.ps1
   
   # Run PSScriptAnalyzer with custom rules
   Invoke-ScriptAnalyzer -Path .\test.ps1 `
       -CustomRulePath .\ScriptAnalyzer\CustomRules\CustomRules.psm1 `
       -IncludeDefaultRules
   ```

2. **Verify the output**:
   - Rule name is correct
   - Message is clear and helpful
   - Severity is appropriate
   - Line/column numbers are accurate

3. **Test edge cases**:
   - Empty files
   - Files with no violations
   - Files with multiple violations
   - Files with syntax errors

### Automated Testing (Future)

We plan to add Pester tests. For now, manual testing is required.

**Future test structure**:
```powershell
Describe "Measure-AcronymCasing" {
    It "Detects incorrect 2-letter acronym casing" {
        $Script = 'function Get-AdUser { }'
        $Results = Invoke-ScriptAnalyzer -ScriptDefinition $Script -CustomRulePath .\ScriptAnalyzer\CustomRules
        $Results.Count | Should -Be 1
        $Results[0].RuleName | Should -Be 'Measure-AcronymCasing'
    }
    
    It "Does not flag correct casing" {
        $Script = 'function Get-ADUser { }'
        $Results = Invoke-ScriptAnalyzer -ScriptDefinition $Script -CustomRulePath .\ScriptAnalyzer\CustomRules
        $Results.Count | Should -Be 0
    }
}
```

### Test Against Real Code

Before submitting, test your changes against real PowerShell code:

1. **Test against this repository**:
   ```powershell
   Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1
   ```

2. **Test against your own PowerShell projects**

3. **Test against popular modules** (if applicable)

---

## Style Guide

All code contributions must follow the standards in **AGENTS.md**.

### Quick Checklist

- [ ] **Naming**: Verb-Noun, approved verbs, PascalCase
- [ ] **Formatting**: K&R braces, 4-space indentation, max 115 chars
- [ ] **[CmdletBinding()]**: On all functions
- [ ] **Comment-based help**: SYNOPSIS, DESCRIPTION, EXAMPLE
- [ ] **Error handling**: try/catch, no empty catch blocks
- [ ] **No aliases**: Use full cmdlet names
- [ ] **Encoding specified**: On Get-Content/Set-Content
- [ ] **Join-Path**: For file paths (not concatenation)

### Run PSScriptAnalyzer

Before committing, ensure your code passes:

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1 -Severity Error,Warning
```

**Zero errors and warnings required for PR approval.**

---

## Commit Messages

Follow the conventional commits format:

### Format

```
<type>: <description>

[optional body]

[optional footer]
```

### Types

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Code style/formatting (no logic change)
- `refactor:` - Code restructuring (no behavior change)
- `test:` - Adding/updating tests
- `chore:` - Maintenance tasks

### Examples

**Good**:
```
feat: Add Measure-PSCustomObjectPropertyCasing rule

Implements validation for PSCustomObject property names to ensure
they follow PascalCase convention as specified in AGENTS.md.

Closes #42
```

```
fix: Correct regex in Measure-AcronymCasing for hyphenated names

The previous regex failed on function names like Get-AD-User.
Updated pattern to properly handle hyphens.

Fixes #56
```

```
docs: Update README with Windows PowerShell 5.1 compatibility note
```

**Bad**:
```
fixed stuff
```

```
WIP
```

```
Updated files
```

### Commit Frequency

- Make **small, logical commits** (one feature/fix per commit)
- Don't commit **work in progress** to main branch
- **Squash commits** if needed before creating PR

---

## Questions?

- **General questions**: Open a [Discussion](https://github.com/OlickQC/PSScriptAnalyzer-BestPractices/discussions)
- **Bug reports**: Open an [Issue](https://github.com/OlickQC/PSScriptAnalyzer-BestPractices/issues)
- **Security issues**: Email the maintainers (see README.md)

---

**Thank you for contributing!** 🎉
