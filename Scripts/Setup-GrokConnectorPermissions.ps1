<#
.SYNOPSIS
    One-time setup: Grants the Grok SharePoint Connector READ access ONLY to Marketing sites.
#>

[CmdletBinding()]
param()

# Import the module (same way your other scripts do it)
$modulePath = Join-Path $PSScriptRoot "..\GreyJones.ProjectProvisioning\GreyJones.ProjectProvisioning.psd1"
Import-Module $modulePath -Force -ErrorAction Stop

# Run the function
Grant-GrokConnectorReadAccess