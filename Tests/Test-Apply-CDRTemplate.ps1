[CmdletBinding()]
param(
    [string]$SourceUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegister"
)

Write-Host "=== Export Contractor Documentation Register Template (Config-driven) ===" -ForegroundColor Cyan

# ====================== LOAD CENTRALISED CONFIGURATION ======================
$appConfig = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot "../TPL.ProjectProvisioning/Config/AppConfig.psd1")

# Resolve paths from the repository root
$repoRoot = Split-Path -Path $PSScriptRoot -Parent

$appConfig.CertificatePath = Join-Path $repoRoot $appConfig.CertificatePath
$CertificatePath = $appConfig.CertificatePath

$cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

# ====================== PATHS ======================
$provisioningConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "../../Data/Templates/ProvisioningConfigs/configFile_CDR.json"
$templateOutPath = Join-Path -Path $PSScriptRoot -ChildPath "../../Data/Templates/projectSiteTemplates/ContractorDocumentationRegister_v1.xml"

# ====================== CONNECT + EXPORT ======================
Connect-PnPOnline -Url $SourceUrl `
    -ClientId $appConfig.ClientID `
    -Tenant $appConfig.Tenant `
    -CertificatePath $CertificatePath `
    -CertificatePassword $cert

Get-PnPSiteTemplate `
    -Configuration $provisioningConfigPath `
    -Out $templateOutPath `
    -ExcludeHandlers SiteSecurity `
    -Force

Write-Host "✅ Template exported successfully!" -ForegroundColor Green
Write-Host "   File: $templateOutPath" -ForegroundColor Green

Disconnect-PnPOnline