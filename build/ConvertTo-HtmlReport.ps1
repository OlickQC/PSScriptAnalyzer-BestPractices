#Requires -Version 5.1

<#
.SYNOPSIS
    Converts PSScriptAnalyzer results to a comprehensive HTML report.

.DESCRIPTION
    This script generates a styled HTML report from PSScriptAnalyzer diagnostic records.
    The report includes:
    - Executive summary with statistics
    - Issues grouped by severity
    - Issues grouped by file
    - Sortable and filterable tables
    - Color-coded severity indicators
    - Offline-viewable (no external dependencies)

.PARAMETER AnalyzerResults
    Array of PSScriptAnalyzer diagnostic records to convert.

.PARAMETER OutputPath
    Path where the HTML report will be saved.

.PARAMETER PSVersion
    PowerShell version identifier for the report header.

.PARAMETER AnalyzedPath
    The path that was analyzed (for display in report).

.EXAMPLE
    $Results = Invoke-ScriptAnalyzer -Path .\src
    ConvertTo-HtmlReport -AnalyzerResults $Results -OutputPath .\report.html -PSVersion "7.x" -AnalyzedPath ".\src"

.NOTES
    Author: PSScriptAnalyzer-BestPractices Project
    License: MIT
#>

function ConvertTo-HtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$AnalyzerResults,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter()]
        [string]$PSVersion = 'Unknown',

        [Parameter()]
        [string]$AnalyzedPath = 'Unknown'
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {
        try {
            # Calculate statistics
            $TotalIssues = $AnalyzerResults.Count
            $ErrorCount = ($AnalyzerResults | Where-Object { $_.Severity -eq 'Error' }).Count
            $WarningCount = ($AnalyzerResults | Where-Object { $_.Severity -eq 'Warning' }).Count
            $InfoCount = ($AnalyzerResults | Where-Object { $_.Severity -eq 'Information' }).Count
            $FileCount = ($AnalyzerResults | Select-Object -ExpandProperty ScriptName -Unique).Count
            $RuleCount = ($AnalyzerResults | Select-Object -ExpandProperty RuleName -Unique).Count
            
            $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

            # Build HTML
            $Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PSScriptAnalyzer Report - PowerShell $PSVersion</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
            color: #333;
            line-height: 1.6;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            border-radius: 8px;
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
        }
        
        .header .subtitle {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px;
            background: #f9f9f9;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            text-align: center;
        }
        
        .summary-card .number {
            font-size: 36px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .summary-card .label {
            font-size: 14px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .summary-card.error .number { color: #e74c3c; }
        .summary-card.warning .number { color: #f39c12; }
        .summary-card.info .number { color: #3498db; }
        .summary-card.total .number { color: #9b59b6; }
        
        .content {
            padding: 30px;
        }
        
        .section {
            margin-bottom: 40px;
        }
        
        .section h2 {
            font-size: 22px;
            margin-bottom: 20px;
            color: #667eea;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        
        .no-issues {
            text-align: center;
            padding: 60px 20px;
            color: #27ae60;
        }
        
        .no-issues .icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        
        .no-issues h3 {
            font-size: 24px;
            margin-bottom: 10px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            background: white;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            border-radius: 8px;
            overflow: hidden;
        }
        
        thead {
            background: #667eea;
            color: white;
        }
        
        th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 12px;
            letter-spacing: 1px;
        }
        
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #f0f0f0;
        }
        
        tr:hover {
            background: #f9f9f9;
        }
        
        .severity-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .severity-error {
            background: #fee;
            color: #e74c3c;
        }
        
        .severity-warning {
            background: #fef9e7;
            color: #f39c12;
        }
        
        .severity-information {
            background: #ebf5fb;
            color: #3498db;
        }
        
        .location {
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 12px;
            color: #666;
        }
        
        .message {
            color: #555;
            line-height: 1.5;
        }
        
        .rule-name {
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 13px;
            color: #667eea;
            font-weight: 600;
        }
        
        .footer {
            padding: 20px 30px;
            background: #f9f9f9;
            border-top: 1px solid #e0e0e0;
            text-align: center;
            font-size: 12px;
            color: #666;
        }
        
        .filter-controls {
            margin-bottom: 20px;
            padding: 15px;
            background: #f9f9f9;
            border-radius: 8px;
        }
        
        .filter-controls label {
            margin-right: 15px;
            font-weight: 600;
        }
        
        .filter-controls input,
        .filter-controls select {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .container {
                box-shadow: none;
            }
            
            .filter-controls {
                display: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>PSScriptAnalyzer Code Quality Report</h1>
            <div class="subtitle">
                PowerShell $PSVersion | Generated: $Timestamp<br>
                Analyzed Path: $AnalyzedPath
            </div>
        </div>
        
        <div class="summary">
            <div class="summary-card total">
                <div class="number">$TotalIssues</div>
                <div class="label">Total Issues</div>
            </div>
            <div class="summary-card error">
                <div class="number">$ErrorCount</div>
                <div class="label">Errors</div>
            </div>
            <div class="summary-card warning">
                <div class="number">$WarningCount</div>
                <div class="label">Warnings</div>
            </div>
            <div class="summary-card info">
                <div class="number">$InfoCount</div>
                <div class="label">Information</div>
            </div>
            <div class="summary-card">
                <div class="number">$FileCount</div>
                <div class="label">Files</div>
            </div>
            <div class="summary-card">
                <div class="number">$RuleCount</div>
                <div class="label">Rules</div>
            </div>
        </div>
        
        <div class="content">
"@

            if ($TotalIssues -eq 0) {
                # No issues found
                $Html += @"
            <div class="no-issues">
                <div class="icon">✓</div>
                <h3>Excellent! No Issues Found</h3>
                <p>Your PowerShell code passes all PSScriptAnalyzer rules.</p>
            </div>
"@
            }
            else {
                # Issues found - group by severity
                $Html += @"
            <div class="section">
                <h2>Issues by Severity</h2>
                
                <div class="filter-controls">
                    <label>Filter:</label>
                    <select id="severityFilter" onchange="filterTable()">
                        <option value="all">All Severities</option>
                        <option value="Error">Errors Only</option>
                        <option value="Warning">Warnings Only</option>
                        <option value="Information">Information Only</option>
                    </select>
                    
                    <input type="text" id="searchBox" placeholder="Search..." onkeyup="filterTable()" style="margin-left: 20px; width: 300px;">
                </div>
                
                <table id="issuesTable">
                    <thead>
                        <tr>
                            <th>Severity</th>
                            <th>Rule</th>
                            <th>File</th>
                            <th>Location</th>
                            <th>Message</th>
                        </tr>
                    </thead>
                    <tbody>
"@

                # Sort by severity (Error > Warning > Information) then by file
                $SortedResults = $AnalyzerResults | Sort-Object @{
                    Expression = {
                        switch ($_.Severity) {
                            'Error' { 1 }
                            'Warning' { 2 }
                            'Information' { 3 }
                        }
                    }
                }, ScriptName, Line

                foreach ($Result in $SortedResults) {
                    $SeverityClass = $Result.Severity.ToLower()
                    $Location = "Line $($Result.Line), Col $($Result.Column)"
                    $Message = [System.Web.HttpUtility]::HtmlEncode($Result.Message)
                    
                    $Html += @"
                        <tr data-severity="$($Result.Severity)">
                            <td><span class="severity-badge severity-$SeverityClass">$($Result.Severity)</span></td>
                            <td><span class="rule-name">$($Result.RuleName)</span></td>
                            <td>$($Result.ScriptName)</td>
                            <td><span class="location">$Location</span></td>
                            <td><span class="message">$Message</span></td>
                        </tr>
"@
                }

                $Html += @"
                    </tbody>
                </table>
            </div>
"@

                # Issues by file
                $FileGroups = $AnalyzerResults | Group-Object -Property ScriptName | Sort-Object Count -Descending

                $Html += @"
            <div class="section">
                <h2>Issues by File</h2>
                <table>
                    <thead>
                        <tr>
                            <th>File</th>
                            <th>Errors</th>
                            <th>Warnings</th>
                            <th>Information</th>
                            <th>Total</th>
                        </tr>
                    </thead>
                    <tbody>
"@

                foreach ($FileGroup in $FileGroups) {
                    $FileErrors = ($FileGroup.Group | Where-Object { $_.Severity -eq 'Error' }).Count
                    $FileWarnings = ($FileGroup.Group | Where-Object { $_.Severity -eq 'Warning' }).Count
                    $FileInfo = ($FileGroup.Group | Where-Object { $_.Severity -eq 'Information' }).Count
                    
                    $Html += @"
                        <tr>
                            <td>$($FileGroup.Name)</td>
                            <td>$FileErrors</td>
                            <td>$FileWarnings</td>
                            <td>$FileInfo</td>
                            <td><strong>$($FileGroup.Count)</strong></td>
                        </tr>
"@
                }

                $Html += @"
                    </tbody>
                </table>
            </div>
"@
            }

            # Close HTML
            $Html += @"
        </div>
        
        <div class="footer">
            Generated by PSScriptAnalyzer Best Practices Pipeline<br>
            <a href="https://github.com/OlickQC/PSScriptAnalyzer-BestPractices" target="_blank">GitHub Repository</a>
        </div>
    </div>
    
    <script>
        function filterTable() {
            const severityFilter = document.getElementById('severityFilter').value;
            const searchBox = document.getElementById('searchBox').value.toLowerCase();
            const table = document.getElementById('issuesTable');
            const rows = table.getElementsByTagName('tr');
            
            for (let i = 1; i < rows.length; i++) {
                const row = rows[i];
                const severity = row.getAttribute('data-severity');
                const text = row.textContent.toLowerCase();
                
                let showRow = true;
                
                // Filter by severity
                if (severityFilter !== 'all' && severity !== severityFilter) {
                    showRow = false;
                }
                
                // Filter by search text
                if (searchBox && !text.includes(searchBox)) {
                    showRow = false;
                }
                
                row.style.display = showRow ? '' : 'none';
            }
        }
    </script>
</body>
</html>
"@

            # Save HTML file
            $Html | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
            
            Write-Verbose "HTML report generated: $OutputPath"
            Write-Verbose "Total issues: $TotalIssues (Errors: $ErrorCount, Warnings: $WarningCount, Info: $InfoCount)"
        }
        catch {
            Write-Error "Failed to generate HTML report: $_"
            throw
        }
    }
}

# Add System.Web assembly for HTML encoding (if needed)
Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue

# Export function if module is dot-sourced
if ($MyInvocation.InvocationName -eq '.') {
    Export-ModuleMember -Function ConvertTo-HtmlReport
}
