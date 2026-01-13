# PSScriptAnalyzer Settings
# Enforces PowerShell best practices and standards from AGENTS.md
# See: https://github.com/OlickQC/PSScriptAnalyzer-BestPractices

@{
    # Include all severity levels for comprehensive analysis
    Severity = @('Error', 'Warning', 'Information')
    
    # Include default PSScriptAnalyzer rules plus custom rules
    IncludeDefaultRules = $true
    
    # Path to custom rules module (relative to project root when running from root)
    # Or specify absolute path when calling Invoke-ScriptAnalyzer with -CustomRulePath
    # When used from root: .\ScriptAnalyzer\CustomRules
    # When settings file is in project: .\CustomRules (relative to settings file location)
    # Leave empty and specify via -CustomRulePath parameter for flexibility
    CustomRulePath = @()
    
    # Exclude specific rules if needed (currently none excluded)
    ExcludeRules = @()
    
    # ============================================================
    # RULE CONFIGURATION
    # ============================================================
    
    Rules = @{
        
        # --------------------------------------------------------
        # CODE FORMATTING RULES
        # --------------------------------------------------------
        
        # K&R Style: Opening brace on same line
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }
        
        # Closing brace placement
        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore = $false
        }
        
        # 4-space indentation (no tabs)
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
        }
        
        # Consistent whitespace usage
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckSeparator = $true
            CheckParameter = $false
            IgnoreAssignmentOperatorInsideHashTable = $true
        }
        
        # Align assignment statements for readability
        PSAlignAssignmentStatement = @{
            Enable = $true
            CheckHashtable = $true
        }
        
        # Maximum line length: 115 characters
        PSAvoidLongLines = @{
            Enable = $true
            MaximumLineLength = 115
        }
        
        # Enforce correct casing (PascalCase for cmdlets/functions)
        PSUseCorrectCasing = @{
            Enable = $true
        }
        
        # --------------------------------------------------------
        # SECURITY RULES (HIGHEST PRIORITY)
        # --------------------------------------------------------
        
        # Error: Prevent plaintext passwords in parameters
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }
        
        # Error: Prevent insecure SecureString conversion
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }
        
        # Error: Prevent hardcoded computer/server names
        PSAvoidUsingComputerNameHardcoded = @{
            Enable = $true
        }
        
        # Error: Enforce PSCredential type instead of username/password params
        PSAvoidUsingUsernameAndPasswordParams = @{
            Enable = $true
        }
        
        # Warning: Require PSCredential type for credential parameters
        PSUsePSCredentialType = @{
            Enable = $true
        }
        
        # Warning: Prevent dangerous Invoke-Expression usage
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
        }
        
        # --------------------------------------------------------
        # NAMING CONVENTION RULES
        # --------------------------------------------------------
        
        # Warning: Use approved PowerShell verbs only
        PSUseApprovedVerbs = @{
            Enable = $true
        }
        
        # Warning: Use singular nouns in function names
        PSUseSingularNouns = @{
            Enable = $true
        }
        
        # Warning: Avoid reserved characters in cmdlet names
        PSReservedCmdletChar = @{
            Enable = $true
        }
        
        # Error: Avoid reserved parameter names
        PSReservedParams = @{
            Enable = $true
        }
        
        # --------------------------------------------------------
        # CODE QUALITY RULES
        # --------------------------------------------------------
        
        # Warning: No cmdlet aliases in scripts (use full names)
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        
        # Warning: No empty catch blocks (silent error swallowing)
        PSAvoidUsingEmptyCatchBlock = @{
            Enable = $true
        }
        
        # Warning: Avoid Write-Host (use Write-Output/Verbose/Warning)
        PSAvoidUsingWriteHost = @{
            Enable = $true
        }
        
        # Warning: Detect unused variables
        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
        }
        
        # Warning: Avoid global variables
        PSAvoidGlobalVars = @{
            Enable = $true
        }
        
        # Warning: Avoid default values for switch parameters
        PSAvoidDefaultValueSwitchParameter = @{
            Enable = $true
        }
        
        # Warning: Avoid deprecated WMI cmdlets (use CIM instead)
        PSAvoidUsingWMICmdlet = @{
            Enable = $true
        }
        
        # Information: Prefer named parameters over positional
        PSAvoidUsingPositionalParameters = @{
            Enable = $true
        }
        
        # Information: Remove trailing whitespace
        PSAvoidTrailingWhitespace = @{
            Enable = $true
        }
        
        # --------------------------------------------------------
        # BEST PRACTICES RULES
        # --------------------------------------------------------
        
        # Warning: State-changing functions should support ShouldProcess
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
        }
        
        # Warning: If ShouldProcess is declared, it must be called
        PSShouldProcess = @{
            Enable = $true
        }
        
        # Warning: Functions with ShouldProcess need SupportsShouldProcess
        PSUseSupportsShouldProcess = @{
            Enable = $true
        }
        
        # Information: Provide comment-based help for functions
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $false
            BlockComment = $true
            VSCodeSnippetCorrection = $true
            Placement = 'begin'
        }
        
        # Warning: Use process block for pipeline-enabled functions
        PSUseProcessBlockForPipelineCommand = @{
            Enable = $true
        }
        
        # Warning: Use explicit exports in module manifests
        PSUseToExportFieldsInManifest = @{
            Enable = $true
        }
        
        # Warning: Include required manifest fields
        PSMissingModuleManifestField = @{
            Enable = $true
        }
        
        # --------------------------------------------------------
        # DSC RULES (if applicable)
        # --------------------------------------------------------
        
        # Error: DSC resources must have standard functions
        PSDSCStandardDSCFunctionsInResource = @{
            Enable = $true
        }
        
        # Error: DSC Get/Test/Set must have identical parameters
        PSDSCUseIdenticalParametersForDSC = @{
            Enable = $true
        }
        
        # Information: DSC functions must return correct types
        PSDSCReturnCorrectTypesForDSCFunctions = @{
            Enable = $true
        }
        
        # Information: DSC resources should have tests
        PSDSCDscTestsPresent = @{
            Enable = $true
        }
        
        # Information: DSC resources should have examples
        PSDSCDscExamplesPresent = @{
            Enable = $true
        }
        
        # --------------------------------------------------------
        # COMPATIBILITY RULES
        # --------------------------------------------------------
        
        # Check PowerShell version compatibility
        PSUseCompatibleSyntax = @{
            Enable = $true
            # Target PowerShell 5.1 and 7.0+
            TargetVersions = @(
                '5.1'
                '7.0'
                '7.1'
                '7.2'
                '7.3'
                '7.4'
            )
        }
        
        # Check cmdlet compatibility across versions
        PSUseCompatibleCmdlets = @{
            Enable = $true
            Compatibility = @(
                'core-6.1.0-windows'
                'core-6.1.0-linux'
                'desktop-5.1.14393.206-windows'
            )
        }
        
        # Check command compatibility
        PSUseCompatibleCommands = @{
            Enable = $true
            # Target Windows PowerShell 5.1 and PowerShell 7+
            TargetProfiles = @(
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
                'win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core'
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
        }
        
        # Check .NET type compatibility
        PSUseCompatibleTypes = @{
            Enable = $true
            TargetProfiles = @(
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
                'win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core'
            )
        }
    }
}
