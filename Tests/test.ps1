# Load configs (same pattern as your other module functions)
$appConfig = Import-PowerShellDataFile -Path "$PSScriptRoot/../Config/AppConfig.psd1"
$appConfig.CertificatePath = Join-Path -Path $PSScriptRoot -ChildPath $appConfig.CertificatePath
$CertificatePath = $appConfig.CertificatePath
$syncConfig = Import-PowerShellDataFile -Path "$PSScriptRoot/../Config/ListSyncConfig.psd1"

$cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force


$siteUrl = "https://greyjonescoza.sharepoint.com/sites/ProjectPipeline-Database"
# ====================== GET SOURCE DATA ======================
Connect-PnPOnline -Url $siteUrl `
    -ClientId $appConfig.ClientID `
    -Tenant $appConfig.Tenant `
    -CertificatePath $CertificatePath `
    -CertificatePassword $cert `
    -ErrorAction Stop

Enable-PnPFeature -Identity 73ef14b1-13a9-416b-a9b5-ececa2b0604c -Scope Site -Force
Write-Host "Added Feature" -ForegroundColor Green