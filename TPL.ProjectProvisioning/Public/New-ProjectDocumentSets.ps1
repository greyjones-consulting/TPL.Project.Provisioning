function New-ProjectDocumentSets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectCode
    )

    Write-Host "=== Processing Document Sets for project $ProjectCode ===" -ForegroundColor Cyan

    # ====================== LOAD CONFIGS ======================
    $appConfig = Import-PowerShellDataFile -Path "$PSScriptRoot/../Config/AppConfig.psd1"
    $dsConfig = Import-PowerShellDataFile -Path "$PSScriptRoot/../Config/DocumentSetConfig.psd1"

    $appConfig.CertificatePath = Join-Path -Path $PSScriptRoot -ChildPath $appConfig.CertificatePath
    $cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

    # ====================== GET SOURCE DATA ======================
    Connect-PnPOnline -Url $dsConfig.SourceList.Url `
        -ClientId $appConfig.ClientID `
        -Tenant $appConfig.Tenant `
        -CertificatePath $appConfig.CertificatePath `
        -CertificatePassword $cert `
        -ErrorAction Stop

    $sourceItem = Get-PnPListItem -List $dsConfig.SourceList.ListName `
        -Query "<View><Query><Where><Eq><FieldRef Name='$($dsConfig.SourceList.MatchField)'/><Value Type='Text'>$ProjectCode</Value></Eq></Where></Query></View>"

    if (-not $sourceItem) {
        Write-Error "Project $ProjectCode not found in Projects_SourceOfTruth."
        Disconnect-PnPOnline
        return
    }

    $shortName = $sourceItem['field_6']
    if (-not $shortName) {
        Write-Error "Shortname (field_6) is empty for project $ProjectCode."
        Disconnect-PnPOnline
        return
    }

    Disconnect-PnPOnline

    # ====================== CLEAN VALUE HELPER ======================
    function Get-CleanValue {
        param($rawValue)
        if ($null -eq $rawValue) { return $null }
        if ($rawValue -is [Microsoft.SharePoint.Client.FieldLookupValue]) {
            return $rawValue.LookupValue
        }
        if ($rawValue -match '^\d+;#(.+)$') {
            return $Matches[1]
        }
        return $rawValue
    }

    # ====================== PROCESS BOTH LIBRARIES ======================
    foreach ($libKey in $dsConfig.Libraries.Keys) {
        $lib = $dsConfig.Libraries[$libKey]
        Write-Host "  → $($lib.LibraryName) → '$shortName'" -ForegroundColor Cyan

        Connect-PnPOnline -Url $lib.SiteUrl `
            -ClientId $appConfig.ClientID `
            -Tenant $appConfig.Tenant `
            -CertificatePath $appConfig.CertificatePath `
            -CertificatePassword $cert `
            -ErrorAction Stop

        $folderUrl = "$($lib.LibraryName)/$shortName"

        # Create if it doesn't exist
        if (-not (Get-PnPFolder -Url $folderUrl -ErrorAction SilentlyContinue)) {
            Write-Host "    Creating new Document Set..." -ForegroundColor Green
            $null = Add-PnPDocumentSet -List $lib.LibraryName -ContentType $lib.ContentTypeName -Name $shortName
            Start-Sleep -Seconds 8
        }
        else {
            Write-Host "    Updating existing Document Set..." -ForegroundColor Yellow
        }

        # Get Document Set item
        $folder = Get-PnPFolder -Url $folderUrl -Includes ListItemAllFields -ErrorAction SilentlyContinue
        if (-not $folder -or -not $folder.ListItemAllFields) {
            Write-Error "    Could not access Document Set '$shortName'."
            Disconnect-PnPOnline
            continue
        }

        $docSetItem = $folder.ListItemAllFields

        # Build values using friendly mapping
        $values = @{}
        foreach ($targetField in $lib.ColumnMappings.Keys) {
            $friendlyKey = $lib.ColumnMappings[$targetField]
            $internalSource = $dsConfig.SourceColumns[$friendlyKey]
            $values[$targetField] = Get-CleanValue $sourceItem[$internalSource]
        }

        # Write to Document Set
        Set-PnPListItem -List $lib.LibraryName -Identity $docSetItem.Id -Values $values | Out-Null

        Write-Host "    ✓ Metadata updated successfully" -ForegroundColor Green

        Disconnect-PnPOnline
    }

    Write-Host "=== Completed Document Sets for project $ProjectCode ===`n" -ForegroundColor Green
}