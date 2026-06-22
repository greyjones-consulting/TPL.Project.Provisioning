[CmdletBinding()]
param()

$SourceUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegister"

Write-Host "=== Export CDR Home Page ===" -ForegroundColor Cyan
Write-Host "Source: $SourceUrl" -ForegroundColor Yellow

## ====================== LOAD CONFIG ======================
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent          # TPL.ProjectProvisioning
$repoRoot = Split-Path -Path $moduleRoot -Parent            # Repository root

$appConfigPath = Join-Path $repoRoot "TPL.ProjectProvisioning\Config\AppConfig.psd1"

$appConfig = Import-PowerShellDataFile -Path $appConfigPath

# ====================== RESOLVE CERTIFICATE PATH ======================
$appConfig.CertificatePath = Join-Path $repoRoot $appConfig.CertificatePath
$cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

# Connect
Connect-PnPOnline -Url $SourceUrl `
    -ClientId $appConfig.ClientID `
    -Tenant $appConfig.Tenant `
    -CertificatePath $appConfig.CertificatePath `
    -CertificatePassword $cert

# Export the home page
$exportPath = Join-Path $moduleRoot "..\Data\Templates\projectSiteTemplates\HomePage.json"

Get-PnPClientSidePage -Identity "Home" -Out $exportPath -Force

Write-Host "✅ Home page exported to: $exportPath" -ForegroundColor Green

Disconnect-PnPOnline