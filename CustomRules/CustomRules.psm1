#Requires -Version 5.1

<#
.SYNOPSIS
    Custom PSScriptAnalyzer rules for PowerShell best practices.

.DESCRIPTION
    This module provides additional PSScriptAnalyzer rules that are not available
    in the built-in rule set. These rules enforce standards defined in AGENTS.md.

.NOTES
    Author: PSScriptAnalyzer-BestPractices Project
    License: MIT
    Repository: https://github.com/OlickQC/PSScriptAnalyzer-BestPractices
#>

#region Measure-AcronymCasing

<#
.SYNOPSIS
    Validates that acronyms in function/cmdlet names follow proper casing rules.

.DESCRIPTION
    Enforces acronym casing standards:
    - 2-letter acronyms: ALL CAPS (AD, VM, PS, IT, OS, IO)
    - 3+ letter acronyms: PascalCase (Html, Sql, Xml, Json, Csv, Api)
    
    Examples:
    - Correct: Get-ADUser, Get-VMHost, New-HtmlReport, Get-SqlDatabase
    - Incorrect: Get-AdUser, Get-HTMLReport, Get-SQLDatabase

.PARAMETER ScriptBlockAst
    AST of the script to analyze.

.EXAMPLE
    Measure-AcronymCasing -ScriptBlockAst $ScriptBlockAst

.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-AcronymCasing {
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
            
            # Common 2-letter acronyms (should be ALL CAPS)
            $TwoLetterAcronyms = @('AD', 'VM', 'PS', 'IT', 'OS', 'IO', 'DB', 'UI', 'ID', 'IP')
            
            # Common 3+ letter acronyms (should be PascalCase)
            $MultiLetterAcronyms = @('Html', 'Sql', 'Xml', 'Json', 'Csv', 'Api', 'Http', 'Https', 'Smtp', 'Ftp')
            
            # Find all function definitions
            $Functions = $ScriptBlockAst.FindAll({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)
            
            foreach ($Function in $Functions) {
                $FunctionName = $Function.Name
                
                # Check for incorrect 2-letter acronym casing (e.g., "Ad" instead of "AD")
                foreach ($Acronym in $TwoLetterAcronyms) {
                    $IncorrectPattern = "(?<![A-Z])$($Acronym[0])[a-z](?![a-z])"
                    if ($FunctionName -match $IncorrectPattern) {
                        $MatchedText = $Matches[0]
                        $CorrectedText = $Acronym
                        
                        $Result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message  = "Function '$FunctionName' contains incorrectly cased 2-letter acronym '$MatchedText'. Should be '$CorrectedText' (ALL CAPS for 2-letter acronyms)."
                            Extent   = $Function.Extent
                            RuleName = $PSCmdlet.MyInvocation.InvocationName
                            Severity = 'Warning'
                        }
                        $Results += $Result
                        break
                    }
                }
                
                # Check for incorrect 3+ letter acronym casing (e.g., "HTML" instead of "Html")
                foreach ($Acronym in $MultiLetterAcronyms) {
                    $AllCapsAcronym = $Acronym.ToUpper()
                    if ($FunctionName -cmatch $AllCapsAcronym -and $FunctionName -cnotmatch $Acronym) {
                        $Result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message  = "Function '$FunctionName' contains incorrectly cased 3+ letter acronym '$AllCapsAcronym'. Should be '$Acronym' (PascalCase for 3+ letter acronyms)."
                            Extent   = $Function.Extent
                            RuleName = $PSCmdlet.MyInvocation.InvocationName
                            Severity = 'Warning'
                        }
                        $Results += $Result
                        break
                    }
                }
            }
            
            return $Results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

#endregion

#region Measure-PathConcatenation

<#
.SYNOPSIS
    Detects string concatenation used for file paths instead of Join-Path.

.DESCRIPTION
    Identifies path construction using string concatenation (+ operator with \ or /)
    and suggests using Join-Path for cross-platform compatibility.
    
    Examples:
    - Bad: $Path = $env:TEMP + "\logs"
    - Good: $Path = Join-Path -Path $env:TEMP -ChildPath "logs"

.PARAMETER ScriptBlockAst
    AST of the script to analyze.

.EXAMPLE
    Measure-PathConcatenation -ScriptBlockAst $ScriptBlockAst

.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-PathConcatenation {
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
            
            # Find all binary expressions (includes + operator)
            $BinaryExpressions = $ScriptBlockAst.FindAll({
                $args[0] -is [System.Management.Automation.Language.BinaryExpressionAst]
            }, $true)
            
            foreach ($Expression in $BinaryExpressions) {
                # Check if it's addition/concatenation
                if ($Expression.Operator -eq 'Plus') {
                    # Check if either side contains path separators
                    $LeftText = $Expression.Left.Extent.Text
                    $RightText = $Expression.Right.Extent.Text
                    
                    $HasPathSeparator = ($LeftText -match '[\\/]' -or $RightText -match '[\\/]')
                    
                    if ($HasPathSeparator) {
                        $Result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message  = "Avoid string concatenation for file paths. Use 'Join-Path -Path <path> -ChildPath <child>' for cross-platform compatibility."
                            Extent   = $Expression.Extent
                            RuleName = $PSCmdlet.MyInvocation.InvocationName
                            Severity = 'Warning'
                        }
                        $Results += $Result
                    }
                }
            }
            
            return $Results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

#endregion

#region Measure-EncodingParameter

<#
.SYNOPSIS
    Ensures Get-Content, Set-Content, and Out-File specify encoding.

.DESCRIPTION
    Validates that file content cmdlets explicitly specify the -Encoding parameter
    to prevent encoding issues across different PowerShell versions and platforms.
    
    Examples:
    - Bad: Get-Content -Path "file.txt"
    - Good: Get-Content -Path "file.txt" -Encoding UTF8

.PARAMETER ScriptBlockAst
    AST of the script to analyze.

.EXAMPLE
    Measure-EncodingParameter -ScriptBlockAst $ScriptBlockAst

.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-EncodingParameter {
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
            
            # Cmdlets that should have -Encoding parameter
            $EncodingCmdlets = @('Get-Content', 'Set-Content', 'Out-File', 'Add-Content')
            
            # Find all command ASTs
            $Commands = $ScriptBlockAst.FindAll({
                $args[0] -is [System.Management.Automation.Language.CommandAst]
            }, $true)
            
            foreach ($Command in $Commands) {
                $CommandName = $Command.GetCommandName()
                
                if ($CommandName -in $EncodingCmdlets) {
                    # Check if -Encoding parameter is present
                    $HasEncodingParam = $false
                    
                    foreach ($Element in $Command.CommandElements) {
                        if ($Element -is [System.Management.Automation.Language.CommandParameterAst]) {
                            if ($Element.ParameterName -eq 'Encoding') {
                                $HasEncodingParam = $true
                                break
                            }
                        }
                    }
                    
                    if (-not $HasEncodingParam) {
                        $Result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message  = "$CommandName should specify -Encoding parameter (e.g., -Encoding UTF8) to ensure consistent behavior across platforms."
                            Extent   = $Command.Extent
                            RuleName = $PSCmdlet.MyInvocation.InvocationName
                            Severity = 'Warning'
                        }
                        $Results += $Result
                    }
                }
            }
            
            return $Results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

#endregion

#region Measure-CmdletBindingPresence

<#
.SYNOPSIS
    Ensures all functions have [CmdletBinding()] attribute.

.DESCRIPTION
    Validates that functions include the [CmdletBinding()] attribute to enable
    advanced function features like -Verbose, -Debug, and proper error handling.
    
    Examples:
    - Bad: function Get-Data { param($Name) }
    - Good: function Get-Data { [CmdletBinding()] param($Name) }

.PARAMETER ScriptBlockAst
    AST of the script to analyze.

.EXAMPLE
    Measure-CmdletBindingPresence -ScriptBlockAst $ScriptBlockAst

.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
function Measure-CmdletBindingPresence {
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
            
            # Find all function definitions
            $Functions = $ScriptBlockAst.FindAll({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)
            
            foreach ($Function in $Functions) {
                # Check if function has a param block
                if ($Function.Body.ParamBlock) {
                    # Check if CmdletBinding attribute is present
                    $HasCmdletBinding = $Function.Body.ParamBlock.Attributes | 
                        Where-Object { $_.TypeName.Name -eq 'CmdletBinding' }
                    
                    if (-not $HasCmdletBinding) {
                        $Result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                            Message  = "Function '$($Function.Name)' should have [CmdletBinding()] attribute to enable advanced function features."
                            Extent   = $Function.Extent
                            RuleName = $PSCmdlet.MyInvocation.InvocationName
                            Severity = 'Warning'
                        }
                        $Results += $Result
                    }
                }
            }
            
            return $Results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}

#endregion

# Export all custom rules
Export-ModuleMember -Function @(
    'Measure-AcronymCasing'
    'Measure-PathConcatenation'
    'Measure-EncodingParameter'
    'Measure-CmdletBindingPresence'
)
