[CmdletBinding()]
param(
    [string]$SourceUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegister"
)

Write-Host "=== Export Contractor Documentation Register Template (Config-driven) ===" -ForegroundColor Cyan

# ====================== CALCULATE PATHS ======================
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent          # TPL.ProjectProvisioning
$repoRoot = Split-Path -Path $moduleRoot -Parent            # Repository Root

# Load AppConfig
$appConfigPath = Join-Path $moduleRoot "Config\AppConfig.psd1"
$appConfig = Import-PowerShellDataFile -Path $appConfigPath

# Resolve Certificate Path from repo root
$appConfig.CertificatePath = Join-Path $repoRoot $appConfig.CertificatePath
$CertificatePath = $appConfig.CertificatePath

$cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

# ====================== OTHER PATHS ======================
$provisioningConfigPath = Join-Path $repoRoot "Data\Templates\ProvisioningConfigs\configFile_CDR.json"
$templateOutPath = Join-Path $repoRoot "Data\Templates\projectSiteTemplates\ContractorDocumentationRegister_v1.xml"

# ====================== CONNECT ======================
Connect-PnPOnline -Url $SourceUrl `
    -ClientId $appConfig.ClientID `
    -Tenant $appConfig.Tenant `
    -CertificatePath $CertificatePath `
    -CertificatePassword $cert

# ====================== EXPORT ======================
Get-PnPSiteTemplate `
    -Configuration $provisioningConfigPath `
    -Out $templateOutPath `
    -ExcludeHandlers SiteSecurity `
    -Force

Write-Host "✅ Template exported successfully!" -ForegroundColor Green
Write-Host "   File: $templateOutPath" -ForegroundColor Green

Disconnect-PnPOnline