[CmdletBinding()]
param(
    [string]$SourceUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegister"
)

Write-Host "=== Export Contractor Documentation Register Template (Config-driven) ===" -ForegroundColor Cyan

# === Safer module loading (avoids "already loaded" errors on Mac) ===
try {
    Remove-Module PnP.PowerShell -Force -ErrorAction SilentlyContinue
    Import-Module PnP.PowerShell -Force -ErrorAction Stop
    Write-Host "✅ PnP.PowerShell loaded successfully" -ForegroundColor Green
}
catch {
    Write-Warning "PnP.PowerShell module loading warning (common when re-running). Continuing..."
}

# === Robust path handling (works from inside the module on Mac) ===
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent           # → TPL.ProjectProvisioning
$repoRoot = Split-Path -Path $moduleRoot -Parent             # → Repository root

$appConfigPath = Join-Path $moduleRoot "Config\AppConfig.psd1"
$provisioningConfigPath = Join-Path $repoRoot   "Data\Templates\ProvisioningConfigs\configFile_CDR.json"
$templateOutPath = Join-Path $repoRoot   "Data\Templates\projectSiteTemplates\ContractorDocumentationRegister_v1.xml"

# Load AppConfig
$appConfig = Import-PowerShellDataFile -Path $appConfigPath

if ($appConfig.CertificatePath -and -not [System.IO.Path]::IsPathRooted($appConfig.CertificatePath)) {
    $appConfig.CertificatePath = Join-Path $repoRoot $appConfig.CertificatePath
}
$cert = ConvertTo-SecureString $appConfig.CertificatePassword -AsPlainText -Force

# Connect and export using your config file
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
Write-Host "   File saved to: $templateOutPath" -ForegroundColor Green

Disconnect-PnPOnline