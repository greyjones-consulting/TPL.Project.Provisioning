[CmdletBinding()]
param()

$TargetUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegisterTest1"

Write-Host "=== Apply CDR Home Page ===" -ForegroundColor Cyan
Write-Host "Target: $TargetUrl" -ForegroundColor Yellow

## ====================== LOAD CONFIG ======================
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent          # TPL.ProjectProvisioning
$repoRoot = Split-Path -Path $moduleRoot -Parent            # Repository root

$appConfigPath = Join-Path $repoRoot "TPL.ProjectProvisioning\Config\AppConfig.psd1"

$appConfig = Import-PowerShellDataFile -Path $appConfigPath

# ====================== RESOLVE CERTIFICATE PATH ======================
$appConfig.CertificatePath = Join-Path $repoRoot $appConfig.CertificatePath
$cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

# Connect
Connect-PnPOnline -Url $TargetUrl `
    -ClientId $appConfig.ClientID `
    -Tenant $appConfig.Tenant `
    -CertificatePath $appConfig.CertificatePath `
    -CertificatePassword $cert

# Apply the exported home page as LandingPage.aspx (more reliable)
$importPath = Join-Path $moduleRoot "..\Data\Templates\projectSiteTemplates\HomePage.json"

Add-PnPClientSidePage `
    -Path $importPath `
    -Name "LandingPage" `
    -Publish

# Set LandingPage.aspx as the default home page
Set-PnPHomePage -RootFolderRelativeUrl "SitePages/LandingPage.aspx"

Write-Host "✅ Home page applied and set as default." -ForegroundColor Green

Disconnect-PnPOnline