[CmdletBinding()]
param(
    [string]$SourceUrl = "https://greyjonescoza.sharepoint.com/sites/10080-TPL-Project-Template-Contractor-Documentation-Register"
)

Write-Host "=== Export Contractor Documentation Register Template (Config-driven) ===" -ForegroundColor Cyan

Import-Module PnP.PowerShell -RequiredVersion 3.1.0 -Force

# Load AppConfig (same pattern as your other scripts)
$configPath = Join-Path $PSScriptRoot "..\..\TPL.ProjectProvisioning\Config\AppConfig.psd1"
$appConfig = Import-PowerShellDataFile $configPath

if ($appConfig.CertificatePath -and -not [System.IO.Path]::IsPathRooted($appConfig.CertificatePath)) {
    $appConfig.CertificatePath = Join-Path $PSScriptRoot $appConfig.CertificatePath
}
$cert = ConvertTo-SecureString $appConfig.CertificatePassword -AsPlainText -Force

# Paths to config + output
$provisioningConfigPath = Join-Path $PSScriptRoot "..\Data\Templates\ProvisioningConfigs\ContractorDocumentationRegister.config.json"
$templateOutPath = Join-Path $PSScriptRoot "..\Data\Templates\projectSiteTemplates\ContractorDocumentationRegister_v1.xml"

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

Write-Host "✅ Template exported successfully using config file!" -ForegroundColor Green
Write-Host "   Output: $templateOutPath" -ForegroundColor Green

Disconnect-PnPOnline