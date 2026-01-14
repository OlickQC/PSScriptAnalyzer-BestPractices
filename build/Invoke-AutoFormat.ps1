#Requires -Version 5.1

<#
.SYNOPSIS
    Automatically formats PowerShell files using PSScriptAnalyzer's Invoke-Formatter.

.DESCRIPTION
    This script applies PSScriptAnalyzer formatting rules to PowerShell files.
    It recursively processes .ps1, .psm1, and .psd1 files and formats them
    according to the specified settings file.
    
    Changes are made in-place, and a summary of modified files is generated.

.PARAMETER Path
    Path to the folder containing PowerShell files to format.

.PARAMETER SettingsPath
    Path to the PSScriptAnalyzerSettings.psd1 configuration file.

.PARAMETER OutputPath
    Optional path where a summary report will be saved.

.PARAMETER WhatIf
    Shows what would be formatted without making actual changes.

.EXAMPLE
    .\Invoke-AutoFormat.ps1 -Path ".\src" -SettingsPath ".\ScriptAnalyzer\PSScriptAnalyzerSettings.psd1"

.EXAMPLE
    .\Invoke-AutoFormat.ps1 -Path ".\src" -SettingsPath ".\Settings.psd1" -WhatIf

.NOTES
    Author: PSScriptAnalyzer-BestPractices Project
    License: MIT
    
    This script modifies files in-place. Ensure you have committed your changes
    to source control before running without -WhatIf.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Path,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$SettingsPath,

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$WhatIf
)

begin {
    $ErrorActionPreference = 'Stop'
    
    Write-Host "##[group]Initialize Auto-Format"
    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-Host "Format Path: $Path"
    Write-Host "Settings File: $SettingsPath"
    Write-Host "WhatIf Mode: $WhatIf"
    Write-Host "##[endgroup]"
}

process {
    try {
        # Import PSScriptAnalyzer
        Write-Host "##[section]Importing PSScriptAnalyzer"
        try {
            Import-Module PSScriptAnalyzer -ErrorAction Stop
            $AnalyzerVersion = (Get-Module PSScriptAnalyzer).Version
            Write-Host "✓ PSScriptAnalyzer $AnalyzerVersion loaded"
        }
        catch {
            Write-Host "##vso[task.logissue type=error]Failed to import PSScriptAnalyzer: $_"
            exit 2
        }

        # Find all PowerShell files
        Write-Host ""
        Write-Host "##[section]Finding PowerShell Files"
        
        $FileExtensions = @('*.ps1', '*.psm1', '*.psd1')
        $Files = Get-ChildItem -Path $Path -Include $FileExtensions -Recurse -File
        
        Write-Host "Found $($Files.Count) PowerShell file(s) to process"

        if ($Files.Count -eq 0) {
            Write-Host "##vso[task.logissue type=warning]No PowerShell files found in: $Path"
            exit 0
        }

        # Process each file
        Write-Host ""
        Write-Host "##[section]Formatting Files"
        
        $ModifiedFiles = @()
        $ErrorFiles = @()
        $SkippedFiles = @()
        $ProcessedCount = 0

        foreach ($File in $Files) {
            $ProcessedCount++
            $RelativePath = $File.FullName.Replace((Get-Location).Path, '.').TrimStart('\').TrimStart('/')
            
            Write-Host "[$ProcessedCount/$($Files.Count)] Processing: $RelativePath" -NoNewline
            
            try {
                # Read original content
                $OriginalContent = Get-Content -Path $File.FullName -Raw -Encoding UTF8
                
                # Skip empty files
                if ([string]::IsNullOrWhiteSpace($OriginalContent)) {
                    Write-Host " - SKIPPED (empty)" -ForegroundColor Gray
                    $SkippedFiles += [PSCustomObject]@{
                        File   = $RelativePath
                        Reason = "Empty file"
                    }
                    continue
                }
                
                # Format content
                $FormattedContent = Invoke-Formatter -ScriptDefinition $OriginalContent -Settings $SettingsPath
                
                # Compare and determine if file changed
                if ($OriginalContent -ne $FormattedContent) {
                    if ($WhatIf) {
                        Write-Host " - WOULD MODIFY" -ForegroundColor Yellow
                    }
                    else {
                        # Save formatted content
                        Set-Content -Path $File.FullName -Value $FormattedContent -Encoding UTF8 -NoNewline
                        Write-Host " - MODIFIED" -ForegroundColor Green
                    }
                    
                    # Calculate change statistics
                    $OriginalLines = ($OriginalContent -split "`n").Count
                    $FormattedLines = ($FormattedContent -split "`n").Count
                    $LineDiff = $FormattedLines - $OriginalLines
                    
                    $ModifiedFiles += [PSCustomObject]@{
                        File          = $RelativePath
                        OriginalLines = $OriginalLines
                        FormattedLines = $FormattedLines
                        LineDifference = $LineDiff
                    }
                }
                else {
                    Write-Host " - OK (no changes)" -ForegroundColor Cyan
                }
            }
            catch {
                Write-Host " - ERROR" -ForegroundColor Red
                Write-Host "  Error: $_" -ForegroundColor Red
                
                $ErrorFiles += [PSCustomObject]@{
                    File  = $RelativePath
                    Error = $_.Exception.Message
                }
            }
        }

        # Display summary
        Write-Host ""
        Write-Host "##[section]Auto-Format Summary"
        Write-Host "======================================================"
        Write-Host "Total Files Processed: $ProcessedCount"
        Write-Host "Modified Files: $($ModifiedFiles.Count)" -ForegroundColor Green
        Write-Host "Skipped Files: $($SkippedFiles.Count)" -ForegroundColor Gray
        Write-Host "Error Files: $($ErrorFiles.Count)" -ForegroundColor Red
        Write-Host "======================================================"

        # Display modified files
        if ($ModifiedFiles.Count -gt 0) {
            Write-Host ""
            Write-Host "##[group]Modified Files Details"
            foreach ($File in $ModifiedFiles) {
                Write-Host "  $($File.File)"
                Write-Host "    Lines: $($File.OriginalLines) → $($File.FormattedLines) ($(if ($File.LineDifference -ge 0) { '+' })$($File.LineDifference))" -ForegroundColor Gray
            }
            Write-Host "##[endgroup]"
        }

        # Display errors
        if ($ErrorFiles.Count -gt 0) {
            Write-Host ""
            Write-Host "##[group]Files with Errors"
            foreach ($ErrorFile in $ErrorFiles) {
                Write-Host "  $($ErrorFile.File)" -ForegroundColor Red
                Write-Host "    Error: $($ErrorFile.Error)" -ForegroundColor Red
            }
            Write-Host "##[endgroup]"
        }

        # Generate summary report
        if ($OutputPath) {
            Write-Host ""
            Write-Host "##[section]Generating Summary Report"
            
            $SummaryReport = @"
PSScriptAnalyzer Auto-Format Summary
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
PowerShell Version: $($PSVersionTable.PSVersion)

STATISTICS
==========
Total Files Processed: $ProcessedCount
Modified Files: $($ModifiedFiles.Count)
Skipped Files: $($SkippedFiles.Count)
Error Files: $($ErrorFiles.Count)

MODIFIED FILES
==============
"@

            if ($ModifiedFiles.Count -eq 0) {
                $SummaryReport += "`nNo files were modified.`n"
            }
            else {
                foreach ($File in $ModifiedFiles) {
                    $SummaryReport += "`n$($File.File)"
                    $SummaryReport += "`n  Original Lines: $($File.OriginalLines)"
                    $SummaryReport += "`n  Formatted Lines: $($File.FormattedLines)"
                    $SummaryReport += "`n  Difference: $(if ($File.LineDifference -ge 0) { '+' })$($File.LineDifference) lines"
                }
            }

            if ($ErrorFiles.Count -gt 0) {
                $SummaryReport += "`n`nERRORS`n======"
                foreach ($ErrorFile in $ErrorFiles) {
                    $SummaryReport += "`n$($ErrorFile.File): $($ErrorFile.Error)"
                }
            }

            $SummaryReport | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
            Write-Host "✓ Summary report saved: $OutputPath"
        }

        # Set output variable for Azure DevOps
        Write-Host ""
        Write-Host "##vso[task.setvariable variable=ModifiedFileCount]$($ModifiedFiles.Count)"
        Write-Host "##vso[task.setvariable variable=ErrorFileCount]$($ErrorFiles.Count)"

        # Exit code
        if ($ErrorFiles.Count -gt 0) {
            Write-Host "##vso[task.logissue type=warning]$($ErrorFiles.Count) file(s) could not be formatted"
        }

        if ($ModifiedFiles.Count -gt 0) {
            if ($WhatIf) {
                Write-Host "##[section]WhatIf: $($ModifiedFiles.Count) file(s) would be modified"
            }
            else {
                Write-Host "##[section]✓ Successfully formatted $($ModifiedFiles.Count) file(s)"
            }
        }
        else {
            Write-Host "##[section]✓ All files are already properly formatted"
        }

        exit 0
    }
    catch {
        Write-Host "##vso[task.logissue type=error]Auto-format failed: $_"
        Write-Host "##vso[task.logissue type=error]Stack Trace: $($_.ScriptStackTrace)"
        exit 2
    }
}
