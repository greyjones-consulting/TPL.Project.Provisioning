[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$Lists = @("TPL_Disciplines")
)

$SourceUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegister"
$TargetUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegisterTest1"

Write-Host "=== Import CDR List Data (Upsert) ===" -ForegroundColor Cyan

# Load Config
$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$appConfigPath = Join-Path $repoRoot "TPL.ProjectProvisioning\Config\AppConfig.psd1"
$appConfig = Import-PowerShellDataFile -Path $appConfigPath

$appConfig.CertificatePath = Join-Path $repoRoot $appConfig.CertificatePath
$cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

# Connect
$sourceConnection = Connect-PnPOnline -Url $SourceUrl -ClientId $appConfig.ClientID -Tenant $appConfig.Tenant -CertificatePath $appConfig.CertificatePath -CertificatePassword $cert -ReturnConnection
$targetConnection = Connect-PnPOnline -Url $TargetUrl -ClientId $appConfig.ClientID -Tenant $appConfig.Tenant -CertificatePath $appConfig.CertificatePath -CertificatePassword $cert -ReturnConnection

foreach ($listName in $Lists) {
    Write-Host "`nProcessing: $listName" -ForegroundColor Cyan

    $sourceItems = Get-PnPListItem -List $listName -PageSize 5000 -Connection $sourceConnection

    if ($sourceItems.Count -eq 0) {
        Write-Host "No items found." -ForegroundColor Yellow
        continue
    }

    # Get all existing items from target once (more reliable than CAML query)
    $targetItems = Get-PnPListItem -List $listName -PageSize 5000 -Connection $targetConnection
    $existingTitles = @{}
    foreach ($t in $targetItems) {
        if ($t["Title"]) {
            $existingTitles[$t["Title"]] = $t
        }
    }

    Write-Host "Processing $($sourceItems.Count) items..." -ForegroundColor Green

    $added = 0
    $updated = 0

    foreach ($item in $sourceItems) {
        $title = $item["Title"]
        $description = $item["field_1"]

        if ([string]::IsNullOrWhiteSpace($title)) { continue }

        $values = @{
            Title   = $title
            field_1 = $description
        }

        try {
            if ($existingTitles.ContainsKey($title)) {
                # Update existing
                Set-PnPListItem -List $listName -Identity $existingTitles[$title].Id -Values $values -Connection $targetConnection | Out-Null
                $updated++
            }
            else {
                # Add new
                Add-PnPListItem -List $listName -Values $values -Connection $targetConnection | Out-Null
                $added++
            }
        }
        catch {
            Write-Warning "Failed to process '$title': $($_.Exception.Message)"
        }
    }

    Write-Host "✅ Finished with $listName → Added: $added | Updated: $updated" -ForegroundColor Green
}

Write-Host "`n✅ Import completed." -ForegroundColor Green

Disconnect-PnPOnline
Disconnect-PnPOnline