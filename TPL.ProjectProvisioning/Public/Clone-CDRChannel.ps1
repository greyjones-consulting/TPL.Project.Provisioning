[CmdletBinding()]
param(
    [string]$SourceUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegister"
)

Write-Host "=== Export Contractor Documentation Register Template (Config-driven) ===" -ForegroundColor Cyan

# ====================== LOAD CENTRALISED CONFIGURATION ======================
$appConfig = Import-PowerShellDataFile -Path "$PSScriptRoot\\..\\Config\\AppConfig.psd1"

# Resolve paths (same pattern as New-ProjectTeam.ps1)
$appConfig.CertificatePath = Join-Path -Path $PSScriptRoot -ChildPath $appConfig.CertificatePath
$CertificatePath = $appConfig.CertificatePath

$cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

# ====================== PATHS FOR CDR ======================
$provisioningConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\\..\\Data\\Templates\\ProvisioningConfigs\\configFile_CDR.json"
$templateOutPath = Join-Path -Path $PSScriptRoot -ChildPath "..\\..\\Data\\Templates\\projectSiteTemplates\\ContractorDocumentationRegister_v1.xml"

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