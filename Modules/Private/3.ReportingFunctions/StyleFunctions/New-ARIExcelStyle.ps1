<#
.Synopsis
Excel Style Fix Module for Azure Resource Inventory

.DESCRIPTION
This module provides a wrapper around New-ExcelStyle to handle the HorizontalAlignment property correctly.

.Link
https://github.com/microsoft/ARI/Modules/Private/3.ReportingFunctions/StyleFunctions/New-ARIExcelStyle.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 1.0.0
First Release Date: 21st Mar, 2025
Authors: Cascade AI Assistant
#>

function New-ARIExcelStyle {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [Parameter()]
        [ValidateSet('Center', 'Left', 'Right', 'Justify')]
        [string]$HorizontalAlignment,
        
        [Parameter()]
        [switch]$AutoSize,
        
        [Parameter()]
        [string]$NumberFormat,
        
        [Parameter()]
        [string]$Range,
        
        [Parameter()]
        [int]$Width,
        
        [Parameter()]
        [switch]$WrapText
    )
    
    process {
        try {
            # Create parameter hashtable for New-ExcelStyle
            $params = @{}
            
            # Only add parameters that were provided
            if ($PSBoundParameters.ContainsKey('HorizontalAlignment')) {
                # Check if we're using the ImportExcel module or direct EPPlus
                try {
                    # Try to create a style with HorizontalAlignment directly
                    $style = New-ExcelStyle -HorizontalAlignment $HorizontalAlignment
                    $params['HorizontalAlignment'] = $HorizontalAlignment
                }
                catch {
                    # If that fails, we need to handle it differently based on the error
                    Write-Verbose "HorizontalAlignment property error detected, using alternative approach"
                    # We'll handle the alignment after creating the style
                }
            }
            
            if ($PSBoundParameters.ContainsKey('AutoSize')) {
                $params['AutoSize'] = $AutoSize
            }
            
            if ($PSBoundParameters.ContainsKey('NumberFormat')) {
                $params['NumberFormat'] = $NumberFormat
            }
            
            if ($PSBoundParameters.ContainsKey('Range')) {
                $params['Range'] = $Range
            }
            
            if ($PSBoundParameters.ContainsKey('Width')) {
                $params['Width'] = $Width
            }
            
            if ($PSBoundParameters.ContainsKey('WrapText')) {
                $params['WrapText'] = $WrapText
            }
            
            # Create the style
            $style = New-ExcelStyle @params
            
            # If we couldn't add HorizontalAlignment directly, try to add it now
            if ($PSBoundParameters.ContainsKey('HorizontalAlignment') -and -not $params.ContainsKey('HorizontalAlignment')) {
                try {
                    # Try different approaches based on the module version
                    if ($null -eq $style.Style) {
                        # Some versions expose it directly
                        if ($null -ne $style.HorizontalAlignment) {
                            $style.HorizontalAlignment = $HorizontalAlignment
                        }
                        else {
                            # For other versions, we might need to use reflection or other approaches
                            # This is a fallback that might not work in all cases
                            $prop = $style | Get-Member -Name HorizontalAlignment -MemberType Property
                            if ($prop) {
                                $style.HorizontalAlignment = $HorizontalAlignment
                            }
                        }
                    }
                    else {
                        # EPPlus direct approach
                        $style.Style.HorizontalAlignment = $HorizontalAlignment
                    }
                }
                catch {
                    Write-Warning "Could not set HorizontalAlignment property: $_"
                }
            }
            
            return $style
        }
        catch {
            Write-Warning "Error in New-ARIExcelStyle: $_"
            # Return the input object unchanged if there's an error
            return $InputObject
        }
    }
}

# Export the function
Export-ModuleMember -Function New-ARIExcelStyle
