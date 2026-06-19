<#
.SYNOPSIS
    Exports the exact PnP provisioning template for the "Contractor Documentation Register" (Shared) channel
    from the TPL Project Template team. Captures all custom lists, the "New Entry" view, and the
    customised home page design exactly as configured.

.DESCRIPTION
    This is the capture step for the WIP cloning of the Contractor Documentation Register channel.
    Run it from the root of the repository whenever you update the lists or home page in the
    template team's channel. The output .xml is stored in Data/Templates for version control and reuse.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = "URL of the Contractor Documentation Register channel site in the template team")]
    [string]$SourceUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegister"
)

Write-Host "=== Export Contractor Documentation Register Template ===" -ForegroundColor Cyan
Write-Host "Source site: $SourceUrl" -ForegroundColor Yellow

# ====================== LOAD CENTRALISED CONFIGURATION ======================
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\TPL.ProjectProvisioning\Config\AppConfig.psd1"
if (-not (Test-Path $configPath)) {
    Write-Error "AppConfig.psd1 not found at $configPath. Make sure it exists locally (it is gitignored for security)."
    exit 1
}
$appConfig = Import-PowerShellDataFile -Path $configPath

# Resolve CertificatePath if stored as relative path (follows pattern in Invoke-ChannelSitesProvisioning.ps1)
if ($appConfig.CertificatePath -and -not [System.IO.Path]::IsPathRooted($appConfig.CertificatePath)) {
    $appConfig.CertificatePath = Join-Path -Path $PSScriptRoot -ChildPath $appConfig.CertificatePath
}

$cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

# ====================== IMPORT REQUIRED MODULES ======================
try {
    Import-Module PnP.PowerShell -ErrorAction Stop
    Write-Verbose "PnP.PowerShell module loaded"
}
catch {
    Write-Error "Failed to import PnP.PowerShell. Please install it first: Install-Module PnP.PowerShell -Scope CurrentUser"
    exit 1
}

# ====================== CONNECT TO TEMPLATE SOURCE ======================
Write-Host "Connecting to PnP..." -ForegroundColor Yellow
try {
    Connect-PnPOnline `
        -Url $SourceUrl `
        -ClientId $appConfig.ClientID `
        -Tenant $appConfig.Tenant `
        -CertificatePath $appConfig.CertificatePath `
        -CertificatePassword $cert `
        -ErrorAction Stop

    Write-Host "✅ Connected successfully to source template site" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect: $($_.Exception.Message)"
    exit 1
}

# ====================== EXPORT THE TEMPLATE ======================
$templateDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Data\Templates\projectSiteTemplates"
$templatePath = Join-Path -Path $templateDir -ChildPath "ContractorDocumentationRegister_v1.xml"

if (-not (Test-Path $templateDir)) {
    New-Item -Path $templateDir -ItemType Directory -Force | Out-Null
}

Write-Host "Exporting provisioning template (Lists + Pages for home page + Views)..." -ForegroundColor Cyan

try {
    Get-PnPProvisioningTemplate `
        -Out $templatePath `
        -Handlers Lists, Pages, Views, Navigation, SiteSettings `
        -Force `
        -ErrorAction Stop

    Write-Host "✅ Export complete!" -ForegroundColor Green
    Write-Host "   Template saved to: $templatePath" -ForegroundColor Green
    Write-Host "   Now commit this file to GitHub so it is available for all future project clones." -ForegroundColor Yellow
}
catch {
    Write-Error "Export failed: $($_.Exception.Message)"
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
    Write-Verbose "Disconnected"
}

Write-Host "=== Script finished ===" -ForegroundColor Cyan