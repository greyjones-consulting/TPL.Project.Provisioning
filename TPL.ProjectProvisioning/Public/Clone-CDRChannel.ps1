[CmdletBinding()]
param(
    [string]$SourceUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegister"
)

Write-Host "=== Export Contractor Documentation Register Template (Config-driven) ===" -ForegroundColor Cyan

# === Load PnP.PowerShell safely (prevents "already loaded" errors) ===
if (-not (Get-Module -Name PnP.PowerShell)) {
    try {
        Import-Module PnP.PowerShell -ErrorAction Stop
        Write-Host "✅ PnP.PowerShell loaded" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to load PnP.PowerShell module. Please run: Install-Module PnP.PowerShell -Scope CurrentUser"
        exit 1
    }
}
else {
    Write-Host "PnP.PowerShell already loaded in this session" -ForegroundColor Yellow
}

# === Robust paths ===
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$repoRoot = Split-Path -Path $moduleRoot -Parent

$appConfigPath = Join-Path $moduleRoot "Config\AppConfig.psd1"
$provisioningConfigPath = Join-Path $repoRoot   "Data\Templates\ProvisioningConfigs\configFile_CDR.json"
$templateOutPath = Join-Path $repoRoot   "Data\Templates\projectSiteTemplates\ContractorDocumentationRegister_v1.xml"

# Load configuration
$appConfig = Import-PowerShellDataFile -Path $appConfigPath

if ($appConfig.CertificatePath -and -not [System.IO.Path]::IsPathRooted($appConfig.CertificatePath)) {
    $appConfig.CertificatePath = Join-Path $repoRoot $appConfig.CertificatePath
}
$cert = ConvertTo-SecureString $appConfig.CertificatePassword -AsPlainText -Force

# Connect and export
Connect-PnPOnline -Url $SourceUrl `
    -ClientId $appConfig.ClientID `
    -Tenant $appConfig.Tenant `
    -CertificatePath $appConfig.CertificatePath `
    -CertificatePassword $cert

Get-PnPSiteTemplate `
    -Configuration $provisioningConfigPath `
    -Out $templateOutPath `
    -ExcludeHandlers SiteSecurity `
    -Force

Write-Host "✅ Template exported successfully!" -ForegroundColor Green
Write-Host "   File: $templateOutPath" -ForegroundColor Green

Disconnect-PnPOnline