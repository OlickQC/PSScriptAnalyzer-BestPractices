#Requires -Version 5.1

<#
.SYNOPSIS
    Runs PSScriptAnalyzer with custom rules and generates comprehensive reports.

.DESCRIPTION
    This script orchestrates the PSScriptAnalyzer code analysis process:
    - Imports custom rules from the CustomRules module
    - Runs analysis with specified settings
    - Generates NUnit XML reports for Azure DevOps test results
    - Generates HTML reports for offline viewing
    - Returns appropriate exit codes based on findings

.PARAMETER Path
    Path to the folder containing PowerShell scripts to analyze.

.PARAMETER SettingsPath
    Path to the PSScriptAnalyzerSettings.psd1 configuration file.

.PARAMETER CustomRulePath
    Path to the folder containing custom PSScriptAnalyzer rules.

.PARAMETER OutputPath
    Directory where reports will be saved.

.PARAMETER FailOnSeverity
    Severity level that will cause the script to exit with error code 1.
    Valid values: Error, Warning, Information
    Default: Error

.PARAMETER GenerateHtmlReport
    Generate an HTML report artifact.

.PARAMETER GenerateNUnitReport
    Generate NUnit XML report for Azure DevOps test results.

.PARAMETER PSVersion
    PowerShell version identifier for report naming (e.g., "5.1", "7.x").

.EXAMPLE
    .\Invoke-CodeAnalysis.ps1 -Path ".\src" -SettingsPath ".\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1" -CustomRulePath ".\ScriptAnalyzer\CustomRules" -OutputPath ".\reports"

.NOTES
    Author: PSScriptAnalyzer-BestPractices Project
    License: MIT
    Exit Codes:
        0 = Success (no issues at failure threshold)
        1 = Analysis failed (violations found at failure threshold)
        2 = Script error (invalid parameters, missing modules, etc.)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Path,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$SettingsPath,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$CustomRulePath,

    [Parameter(Mandatory)]
    [string]$OutputPath,

    [Parameter()]
    [ValidateSet('Error', 'Warning', 'Information')]
    [string]$FailOnSeverity = 'Error',

    [Parameter()]
    [switch]$GenerateHtmlReport,

    [Parameter()]
    [switch]$GenerateNUnitReport,

    [Parameter()]
    [string]$PSVersion = 'Unknown'
)

begin {
    $ErrorActionPreference = 'Stop'
    
    Write-Host "##[group]Initialize Code Analysis"
    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-Host "PSEdition: $($PSVersionTable.PSEdition)"
    Write-Host "Analysis Path: $Path"
    Write-Host "Settings File: $SettingsPath"
    Write-Host "Custom Rules: $CustomRulePath"
    Write-Host "Output Path: $OutputPath"
    Write-Host "Fail On Severity: $FailOnSeverity"
    Write-Host "##[endgroup]"
}

process {
    try {
        # Create output directory if it doesn't exist
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            Write-Verbose "Created output directory: $OutputPath"
        }

        # Import PSScriptAnalyzer module
        Write-Host "##[group]Import Modules"
        try {
            Import-Module PSScriptAnalyzer -ErrorAction Stop
            $AnalyzerVersion = (Get-Module PSScriptAnalyzer).Version
            Write-Host "✓ PSScriptAnalyzer $AnalyzerVersion loaded successfully"
        }
        catch {
            Write-Host "##vso[task.logissue type=error]Failed to import PSScriptAnalyzer module: $_"
            exit 2
        }

        # Import custom rules module
        $CustomRulesModule = Join-Path -Path $CustomRulePath -ChildPath "CustomRules.psm1"
        if (Test-Path $CustomRulesModule) {
            try {
                Import-Module $CustomRulesModule -Force -ErrorAction Stop
                Write-Host "✓ Custom rules loaded from: $CustomRulesModule"
                
                # List custom rules
                $CustomRules = Get-Command -Module CustomRules | Where-Object { $_.Name -like 'Measure-*' }
                Write-Host "  Custom rules available: $($CustomRules.Count)"
                foreach ($Rule in $CustomRules) {
                    Write-Host "    - $($Rule.Name)"
                }
            }
            catch {
                Write-Host "##vso[task.logissue type=warning]Failed to import custom rules: $_"
            }
        }
        else {
            Write-Host "##vso[task.logissue type=warning]Custom rules module not found: $CustomRulesModule"
        }
        Write-Host "##[endgroup]"

        # Run PSScriptAnalyzer
        Write-Host ""
        Write-Host "##[section]Running PSScriptAnalyzer Analysis"
        Write-Host "Analyzing: $Path"
        
        $AnalyzerParams = @{
            Path            = $Path
            Settings        = $SettingsPath
            Recurse         = $true
            ReportSummary   = $true
            ErrorAction     = 'Stop'
        }

        # Add custom rule path if module was loaded successfully
        if (Get-Module CustomRules) {
            $AnalyzerParams['CustomRulePath'] = $CustomRulePath
        }

        $Results = Invoke-ScriptAnalyzer @AnalyzerParams

        # Display analysis summary
        Write-Host ""
        Write-Host "##[section]Analysis Results Summary"
        Write-Host "======================================================"
        
        $TotalIssues = $Results.Count
        $ErrorCount = ($Results | Where-Object { $_.Severity -eq 'Error' }).Count
        $WarningCount = ($Results | Where-Object { $_.Severity -eq 'Warning' }).Count
        $InfoCount = ($Results | Where-Object { $_.Severity -eq 'Information' }).Count
        
        Write-Host "Total Issues Found: $TotalIssues"
        Write-Host "  Errors:       $ErrorCount"
        Write-Host "  Warnings:     $WarningCount"
        Write-Host "  Information:  $InfoCount"
        Write-Host "======================================================"

        # Group by severity and display
        if ($Results.Count -gt 0) {
            Write-Host ""
            Write-Host "##[group]Issues by Severity"
            
            foreach ($Severity in @('Error', 'Warning', 'Information')) {
                $SeverityResults = $Results | Where-Object { $_.Severity -eq $Severity }
                if ($SeverityResults) {
                    Write-Host ""
                    Write-Host "[$Severity] - $($SeverityResults.Count) issue(s):" -ForegroundColor $(
                        switch ($Severity) {
                            'Error' { 'Red' }
                            'Warning' { 'Yellow' }
                            'Information' { 'Cyan' }
                        }
                    )
                    
                    $SeverityResults | ForEach-Object {
                        Write-Host "  $($_.ScriptName):$($_.Line):$($_.Column) - $($_.RuleName)"
                        Write-Host "    $($_.Message)" -ForegroundColor Gray
                    }
                }
            }
            Write-Host "##[endgroup]"
        }

        # Generate NUnit XML report
        if ($GenerateNUnitReport) {
            Write-Host ""
            Write-Host "##[section]Generating NUnit XML Report"
            
            $NUnitPath = Join-Path -Path $OutputPath -ChildPath "PSScriptAnalyzer-$PSVersion.xml"
            
            # Load converter script
            $ConverterScript = Join-Path -Path $PSScriptRoot -ChildPath "ConvertTo-NUnitXml.ps1"
            if (Test-Path $ConverterScript) {
                . $ConverterScript
                
                try {
                    ConvertTo-NUnitXml -AnalyzerResults $Results -OutputPath $NUnitPath -PSVersion $PSVersion
                    Write-Host "✓ NUnit XML report saved: $NUnitPath"
                }
                catch {
                    Write-Host "##vso[task.logissue type=warning]Failed to generate NUnit XML: $_"
                }
            }
            else {
                Write-Host "##vso[task.logissue type=warning]NUnit converter not found: $ConverterScript"
            }
        }

        # Generate HTML report
        if ($GenerateHtmlReport) {
            Write-Host ""
            Write-Host "##[section]Generating HTML Report"
            
            $HtmlPath = Join-Path -Path $OutputPath -ChildPath "PSScriptAnalyzer-Report-$PSVersion.html"
            
            # Load HTML generator script
            $HtmlGeneratorScript = Join-Path -Path $PSScriptRoot -ChildPath "ConvertTo-HtmlReport.ps1"
            if (Test-Path $HtmlGeneratorScript) {
                . $HtmlGeneratorScript
                
                try {
                    ConvertTo-HtmlReport -AnalyzerResults $Results -OutputPath $HtmlPath -PSVersion $PSVersion -AnalyzedPath $Path
                    Write-Host "✓ HTML report saved: $HtmlPath"
                }
                catch {
                    Write-Host "##vso[task.logissue type=warning]Failed to generate HTML report: $_"
                }
            }
            else {
                Write-Host "##vso[task.logissue type=warning]HTML generator not found: $HtmlGeneratorScript"
            }
        }

        # Determine exit code based on severity threshold
        Write-Host ""
        Write-Host "##[section]Determining Build Status"
        
        $ShouldFail = $false
        $FailureMessage = ""
        
        switch ($FailOnSeverity) {
            'Error' {
                if ($ErrorCount -gt 0) {
                    $ShouldFail = $true
                    $FailureMessage = "Found $ErrorCount error(s)"
                }
            }
            'Warning' {
                if ($ErrorCount -gt 0 -or $WarningCount -gt 0) {
                    $ShouldFail = $true
                    $FailureMessage = "Found $ErrorCount error(s) and $WarningCount warning(s)"
                }
            }
            'Information' {
                if ($Results.Count -gt 0) {
                    $ShouldFail = $true
                    $FailureMessage = "Found $TotalIssues issue(s)"
                }
            }
        }

        if ($ShouldFail) {
            Write-Host "##vso[task.logissue type=error]Analysis failed: $FailureMessage"
            Write-Host "##vso[task.complete result=Failed;]FAILED"
            exit 1
        }
        else {
            Write-Host "##[section]✓ Analysis passed! No issues found at '$FailOnSeverity' severity level or higher."
            Write-Host "##vso[task.complete result=Succeeded;]PASSED"
            exit 0
        }
    }
    catch {
        Write-Host "##vso[task.logissue type=error]Script execution failed: $_"
        Write-Host "##vso[task.logissue type=error]Stack Trace: $($_.ScriptStackTrace)"
        Write-Host "##vso[task.complete result=Failed;]ERROR"
        exit 2
    }
}
