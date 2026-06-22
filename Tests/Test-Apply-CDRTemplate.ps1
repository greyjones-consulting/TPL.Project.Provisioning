Write-Host "=== Test Apply CDR Template ===" -ForegroundColor Cyan

$TargetSiteUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegisterTest1"

# ====================== LOAD CONFIG ======================
$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$appConfigPath = Join-Path $repoRoot "TPL.ProjectProvisioning/Config/AppConfig.psd1"

$appConfig = Import-PowerShellDataFile -Path $appConfigPath

# Resolve Certificate Path
$appConfig.CertificatePath = Join-Path $repoRoot $appConfig.CertificatePath
$CertificatePath = $appConfig.CertificatePath

$cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

# ====================== TEMPLATE PATH ======================
$templatePath = Join-Path $repoRoot "Data/Templates/projectSiteTemplates/ContractorDocumentationRegister_v1.xml"

if (-not (Test-Path $templatePath)) {
    Write-Error "Template not found at: $templatePath"
    exit 1
}

Write-Host "Using Template: $templatePath" -ForegroundColor Yellow

# ====================== CONNECT ======================
if (-not $TargetSiteUrl) {
    Write-Host "Please provide the target site URL as a parameter." -ForegroundColor Red
    Write-Host "Example:" -ForegroundColor Yellow
    Write-Host ".\Scripts\Test-Apply-CDRTemplate.ps1 -TargetSiteUrl 'https://greyjonescoza.sharepoint.com/sites/XXXX-Contractor-Documentation-Register-Test1'" -ForegroundColor Yellow
    exit 1
}

Write-Host "Connecting to: $TargetSiteUrl" -ForegroundColor Yellow

Connect-PnPOnline -Url $TargetSiteUrl `
    -ClientId $appConfig.ClientID `
    -Tenant $appConfig.Tenant `
    -CertificatePath $CertificatePath `
    -CertificatePassword $cert

# ====================== APPLY TEMPLATE ======================
Write-Host "Applying CDR template..." -ForegroundColor Cyan

try {
    Invoke-PnPSiteTemplate -Path $templatePath `
        -Handlers Lists `
        -Verbose
    Write-Host "✅ First CDR Template applied successfully!" -ForegroundColor Green
    Invoke-PnPSiteTemplate -Path $templatePath `
        -Handlers Lists `
        -Verbose
    Write-Host "✅ CDR Template applied successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to apply template: $($_.Exception.Message)"
}
finally {
    Disconnect-PnPOnline
}