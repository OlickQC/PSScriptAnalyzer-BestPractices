# Test script with intentional violations for demonstration
# This file demonstrates what PSScriptAnalyzer detects

# VIOLATION 1: Function without CmdletBinding
function getdata {
    param($path)
    
    # VIOLATION 2: String concatenation for paths
    $file = $path + "\data.txt"
    
    # VIOLATION 3: No encoding specified
    $content = Get-Content $file
    
    # VIOLATION 4: Using aliases
    gci | ? {$_.Length -gt 1MB}
    
    # VIOLATION 5: Empty catch block
    try {
        Remove-Item $file
    }
    catch {
        # Silent error - bad!
    }
}

# VIOLATION 6: Incorrect acronym casing
function Get-HTMLReport {
    [CmdletBinding()]
    param()
    
    # VIOLATION 7: Using Write-Host
    Write-Host "Generating report..."
}

# VIOLATION 8: Non-approved verb
function Create-User {
    param($name)
}
