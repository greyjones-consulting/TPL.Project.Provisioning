[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$Lists
)

$SourceUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegister"
$TargetUrl = "https://greyjonescoza.sharepoint.com/sites/10080TPLProjectTemplate-ContractorDocumentationRegisterTest1"

Write-Host "=== Import CDR List Data ===" -ForegroundColor Cyan
Write-Host "Source: $SourceUrl" -ForegroundColor Yellow
Write-Host "Target: $TargetUrl" -ForegroundColor Yellow

# ====================== LOAD CONFIG ======================
$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$appConfigPath = Join-Path $repoRoot "TPL.ProjectProvisioning\Config\AppConfig.psd1"
$syncConfigPath = Join-Path $repoRoot "TPL.ProjectProvisioning\Config\ListSyncConfig.psd1"

$appConfig = Import-PowerShellDataFile -Path $appConfigPath
$syncConfig = Import-PowerShellDataFile -Path $syncConfigPath

$appConfig.CertificatePath = Join-Path $repoRoot $appConfig.CertificatePath
$cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

# Use config if no lists specified
if (-not $Lists) {
    $Lists = $syncConfig.CDRReferenceLists.Keys
}

# ====================== CONNECT ======================
$sourceConnection = Connect-PnPOnline -Url $SourceUrl -ClientId $appConfig.ClientID -Tenant $appConfig.Tenant -CertificatePath $appConfig.CertificatePath -CertificatePassword $cert -ReturnConnection
$targetConnection = Connect-PnPOnline -Url $TargetUrl -ClientId $appConfig.ClientID -Tenant $appConfig.Tenant -CertificatePath $appConfig.CertificatePath -CertificatePassword $cert -ReturnConnection

# ====================== PROCESS LISTS ======================
foreach ($listName in $Lists) {

    if (-not $syncConfig.CDRReferenceLists.ContainsKey($listName)) {
        Write-Warning "List '$listName' not found in ListSyncConfig.psd1. Skipping."
        continue
    }

    $fieldsToSync = $syncConfig.CDRReferenceLists[$listName].Fields

    Write-Host "`nProcessing: $listName (Fields: $($fieldsToSync -join ', '))" -ForegroundColor Cyan

    $sourceItems = Get-PnPListItem -List $listName -PageSize 5000 -Connection $sourceConnection

    if ($sourceItems.Count -eq 0) {
        Write-Host "No items found." -ForegroundColor Yellow
        continue
    }

    # Load existing items from target for matching
    $targetItems = Get-PnPListItem -List $listName -PageSize 5000 -Connection $targetConnection
    $existingByTitle = @{}
    foreach ($t in $targetItems) {
        if ($t["Title"]) { $existingByTitle[$t["Title"]] = $t }
    }

    $added = 0; $updated = 0

    foreach ($item in $sourceItems) {
        $values = @{}
        foreach ($field in $fieldsToSync) {
            $val = $item[$field]
            if ($null -ne $val -and $val.ToString().Trim() -ne "") {
                $values[$field] = $val
            }
        }

        if ($values.Count -eq 0) { continue }

        $title = $item["Title"]
        if ([string]::IsNullOrWhiteSpace($title)) { continue }

        try {
            if ($existingByTitle.ContainsKey($title)) {
                Set-PnPListItem -List $listName -Identity $existingByTitle[$title].Id -Values $values -Connection $targetConnection | Out-Null
                $updated++
            }
            else {
                Add-PnPListItem -List $listName -Values $values -Connection $targetConnection | Out-Null
                $added++
            }
        }
        catch {
            Write-Warning "Failed on '$title': $($_.Exception.Message)"
        }
    }

    Write-Host "✅ $listName → Added: $added | Updated: $updated" -ForegroundColor Green
}

Write-Host "`n✅ Import completed." -ForegroundColor Green