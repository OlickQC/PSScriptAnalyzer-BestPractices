#Requires -Version 5.1

<#
.SYNOPSIS
    Converts PSScriptAnalyzer results to NUnit XML format for Azure DevOps test results.

.DESCRIPTION
    This script converts PSScriptAnalyzer diagnostic records into NUnit XML format
    that can be consumed by Azure DevOps test result publishing.
    
    Each PSScriptAnalyzer violation is represented as a test case:
    - Errors/Warnings = Failed test
    - Information = Passed test (with message)
    - Test name = "{RuleName} - {FileName}:{Line}"

.PARAMETER AnalyzerResults
    Array of PSScriptAnalyzer diagnostic records to convert.

.PARAMETER OutputPath
    Path where the NUnit XML file will be saved.

.PARAMETER PSVersion
    PowerShell version identifier for the test suite name.

.EXAMPLE
    $Results = Invoke-ScriptAnalyzer -Path .\src
    ConvertTo-NUnitXml -AnalyzerResults $Results -OutputPath .\report.xml -PSVersion "7.x"

.NOTES
    Author: PSScriptAnalyzer-BestPractices Project
    License: MIT
#>

function ConvertTo-NUnitXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$AnalyzerResults,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter()]
        [string]$PSVersion = 'Unknown'
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {
        try {
            # NUnit XML structure
            $Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
            $TotalTests = if ($AnalyzerResults.Count -eq 0) { 1 } else { $AnalyzerResults.Count }
            $Failures = ($AnalyzerResults | Where-Object { $_.Severity -in @('Error', 'Warning') }).Count
            $NotRun = 0
            $Inconclusive = 0
            $Ignored = 0
            $Skipped = 0
            $Invalid = 0
            $Success = if ($Failures -eq 0) { 'True' } else { 'False' }
            
            # Start building XML
            $XmlWriter = New-Object System.Xml.XmlTextWriter($OutputPath, [System.Text.Encoding]::UTF8)
            $XmlWriter.Formatting = 'Indented'
            $XmlWriter.Indentation = 2
            
            # Write XML declaration
            $XmlWriter.WriteStartDocument()
            
            # Root element: test-results
            $XmlWriter.WriteStartElement('test-results')
            $XmlWriter.WriteAttributeString('name', "PSScriptAnalyzer-$PSVersion")
            $XmlWriter.WriteAttributeString('total', $TotalTests.ToString())
            $XmlWriter.WriteAttributeString('errors', '0')
            $XmlWriter.WriteAttributeString('failures', $Failures.ToString())
            $XmlWriter.WriteAttributeString('not-run', $NotRun.ToString())
            $XmlWriter.WriteAttributeString('inconclusive', $Inconclusive.ToString())
            $XmlWriter.WriteAttributeString('ignored', $Ignored.ToString())
            $XmlWriter.WriteAttributeString('skipped', $Skipped.ToString())
            $XmlWriter.WriteAttributeString('invalid', $Invalid.ToString())
            $XmlWriter.WriteAttributeString('date', (Get-Date -Format "yyyy-MM-dd"))
            $XmlWriter.WriteAttributeString('time', (Get-Date -Format "HH:mm:ss"))
            
            # Environment information
            $XmlWriter.WriteStartElement('environment')
            $XmlWriter.WriteAttributeString('nunit-version', '2.6.4')
            $XmlWriter.WriteAttributeString('clr-version', $PSVersionTable.CLRVersion.ToString())
            $XmlWriter.WriteAttributeString('os-version', $PSVersionTable.OS)
            $XmlWriter.WriteAttributeString('platform', $PSVersionTable.Platform)
            $XmlWriter.WriteAttributeString('cwd', (Get-Location).Path)
            $XmlWriter.WriteAttributeString('machine-name', $env:COMPUTERNAME)
            $XmlWriter.WriteAttributeString('user', $env:USERNAME)
            $XmlWriter.WriteAttributeString('user-domain', $env:USERDOMAIN)
            $XmlWriter.WriteEndElement()  # environment
            
            # Culture info
            $XmlWriter.WriteStartElement('culture-info')
            $XmlWriter.WriteAttributeString('current-culture', (Get-Culture).Name)
            $XmlWriter.WriteAttributeString('current-uiculture', (Get-Culture).Name)
            $XmlWriter.WriteEndElement()  # culture-info
            
            # Test suite
            $XmlWriter.WriteStartElement('test-suite')
            $XmlWriter.WriteAttributeString('type', 'Assembly')
            $XmlWriter.WriteAttributeString('name', "PSScriptAnalyzer")
            $XmlWriter.WriteAttributeString('executed', 'True')
            $XmlWriter.WriteAttributeString('result', $(if ($Failures -eq 0) { 'Success' } else { 'Failure' }))
            $XmlWriter.WriteAttributeString('success', $Success)
            $XmlWriter.WriteAttributeString('time', '0.000')
            $XmlWriter.WriteAttributeString('asserts', '0')
            
            # Results container
            $XmlWriter.WriteStartElement('results')
            
            if ($AnalyzerResults.Count -eq 0) {
                # No issues found - create a passing test
                $XmlWriter.WriteStartElement('test-case')
                $XmlWriter.WriteAttributeString('name', 'PSScriptAnalyzer - No Issues Found')
                $XmlWriter.WriteAttributeString('executed', 'True')
                $XmlWriter.WriteAttributeString('result', 'Success')
                $XmlWriter.WriteAttributeString('success', 'True')
                $XmlWriter.WriteAttributeString('time', '0.000')
                $XmlWriter.WriteAttributeString('asserts', '0')
                $XmlWriter.WriteEndElement()  # test-case
            }
            else {
                # Create test case for each violation
                foreach ($Result in $AnalyzerResults) {
                    $TestName = "$($Result.RuleName) - $($Result.ScriptName):$($Result.Line)"
                    $IsFailure = $Result.Severity -in @('Error', 'Warning')
                    
                    $XmlWriter.WriteStartElement('test-case')
                    $XmlWriter.WriteAttributeString('name', $TestName)
                    $XmlWriter.WriteAttributeString('executed', 'True')
                    $XmlWriter.WriteAttributeString('result', $(if ($IsFailure) { 'Failure' } else { 'Success' }))
                    $XmlWriter.WriteAttributeString('success', $(if ($IsFailure) { 'False' } else { 'True' }))
                    $XmlWriter.WriteAttributeString('time', '0.000')
                    $XmlWriter.WriteAttributeString('asserts', '1')
                    
                    if ($IsFailure) {
                        # Add failure details
                        $XmlWriter.WriteStartElement('failure')
                        
                        # Message
                        $XmlWriter.WriteStartElement('message')
                        $XmlWriter.WriteCData("[$($Result.Severity)] $($Result.Message)")
                        $XmlWriter.WriteEndElement()  # message
                        
                        # Stack trace
                        $XmlWriter.WriteStartElement('stack-trace')
                        $StackTrace = "at $($Result.RuleName) in $($Result.ScriptPath):line $($Result.Line)"
                        $XmlWriter.WriteCData($StackTrace)
                        $XmlWriter.WriteEndElement()  # stack-trace
                        
                        $XmlWriter.WriteEndElement()  # failure
                    }
                    else {
                        # Add informational message as reason
                        $XmlWriter.WriteStartElement('reason')
                        $XmlWriter.WriteStartElement('message')
                        $XmlWriter.WriteCData("[$($Result.Severity)] $($Result.Message)")
                        $XmlWriter.WriteEndElement()  # message
                        $XmlWriter.WriteEndElement()  # reason
                    }
                    
                    $XmlWriter.WriteEndElement()  # test-case
                }
            }
            
            $XmlWriter.WriteEndElement()  # results
            $XmlWriter.WriteEndElement()  # test-suite
            $XmlWriter.WriteEndElement()  # test-results
            
            # Finalize document
            $XmlWriter.WriteEndDocument()
            $XmlWriter.Flush()
            $XmlWriter.Close()
            
            Write-Verbose "NUnit XML report generated: $OutputPath"
            Write-Verbose "Total tests: $TotalTests, Failures: $Failures"
        }
        catch {
            Write-Error "Failed to generate NUnit XML: $_"
            throw
        }
    }
}

# Export function if module is dot-sourced
if ($MyInvocation.InvocationName -eq '.') {
    Export-ModuleMember -Function ConvertTo-NUnitXml
}
