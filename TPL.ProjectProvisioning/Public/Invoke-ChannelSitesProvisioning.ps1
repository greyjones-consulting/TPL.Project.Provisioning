function Invoke-ChannelSitesProvisioning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$ProjectCode,

        [Parameter(Mandatory)]
        [string]$ProjectName,

        [Parameter(Mandatory)]
        [string]$MainTeamSiteUrl
    )

    # ====================== DEBUG MODE ======================
    # Set to $true to run ONLY the RFI channel (much faster for testing)
    # Set to $false when you want to run the full provisioning again
    $debugRfiOnly = $false

    Write-Verbose "Starting channel sites provisioning for project $ProjectCode - $ProjectName"

    # ====================== LOAD CENTRALISED CONFIGURATION ======================
    $appConfig = Import-PowerShellDataFile -Path "$PSScriptRoot/../Config/AppConfig.psd1"
    $contentConfig = Import-PowerShellDataFile -Path "$PSScriptRoot/../Config/ContentTypeMapping.psd1"

    # ====================== FIX LOGO PATH (this is the important part) ======================
    # Resolve the relative path from AppConfig into a full absolute path
    $appConfig.LogoPath = Join-Path -Path $PSScriptRoot -ChildPath "../../Data/Templates/projectSiteTemplates/SiteAssets/clientLogo.png"
    $appConfig.RFITemplatePath = Join-Path -Path $PSScriptRoot -ChildPath "../../Data/Templates/projectSiteTemplates/template_source_team_RFI_v1001.xml"
    $appConfig.CertificatePath = Join-Path -Path $PSScriptRoot -ChildPath "../../PnP/PnpCert.pfx"
    $CertificatePath = $appConfig.CertificatePath

    # Load ViewDefinitions as JSON (simple & reliable)
    $viewConfigPath = "$PSScriptRoot\..\Config\ViewDefinitions.psd1"
    if (Test-Path $viewConfigPath) {
        $rawContent = Get-Content $viewConfigPath -Raw
        $jsonStart = $rawContent.IndexOf('{')   # skip the header comments
        $jsonData = $rawContent.Substring($jsonStart)
        $viewConfig = $jsonData | ConvertFrom-Json -AsHashtable
        Write-Verbose "Loaded view definitions from $viewConfigPath"
    }
    else {
        Write-Warning "ViewDefinitions.psd1 not found. Run Prepare-ViewDefinitions.ps1 first."
        $viewConfig = @{}
    }

    $cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

    # Normalise project name for channel URLs
    $projectNameUrl = $ProjectName -replace '\s*\|\s*', '' -replace '\s+', ''

    # ====================== ONE UNIFIED LOOP FOR EVERY CHANNEL ======================
    $channelsToProcess = @(
        @{ ConfigKey = 'ProjectDocuments'; TargetUrl = $MainTeamSiteUrl; WaitForSite = $false }
        @{ ConfigKey = 'CommercialDocuments'; UrlSuffix = "$projectNameUrl-CommercialDocuments"; WaitForSite = $true }
        @{ ConfigKey = 'TransmittalsProject'; UrlSuffix = "$projectNameUrl-Transmittals-Project"; WaitForSite = $true }
        @{ ConfigKey = 'TransmittalsCommercial'; UrlSuffix = "$projectNameUrl-Transmittals-Commercial"; WaitForSite = $true }
        @{ ConfigKey = 'RequestForInformation'; UrlSuffix = "$projectNameUrl-RequestforInformation"; WaitForSite = $true }
        @{ ConfigKey = 'SurveyData'; UrlSuffix = "$projectNameUrl-SurveyData"; WaitForSite = $true }
    )

    # === DEBUG: Skip everything except RFI ===
    if ($debugRfiOnly) {
        $channelsToProcess = @(
            @{ ConfigKey = 'RequestForInformation'; UrlSuffix = "$projectNameUrl-RequestforInformation"; WaitForSite = $true }
        )
        Write-Host "DEBUG MODE: Running ONLY the RequestForInformation channel" -ForegroundColor Magenta
    }

    foreach ($channel in $channelsToProcess) {
        $chanConfig = $contentConfig.ChannelConfigurations[$channel.ConfigKey]

        # Determine URL (main site already known, others built from suffix)
        $targetUrl = if ($channel.TargetUrl) { $channel.TargetUrl } else { "$($contentConfig.ChannelBaseUrl)$($channel.UrlSuffix)" }

        Write-Host "Processing $($channel.ConfigKey) channel: $targetUrl" -ForegroundColor Cyan

        if ($channel.WaitForSite) {
            Wait-ForChannelSite `
                -Url $targetUrl `
                -CertificatePath $CertificatePath
            Start-Process $targetUrl
        }

        $null = Connect-PnPOnline `
            -Url $targetUrl `
            -ClientId $appConfig.ClientID `
            -Tenant $appConfig.Tenant `
            -CertificatePath $appConfig.CertificatePath `
            -CertificatePassword $cert

        Add-PnPHubSiteAssociation -Site $targetUrl -HubSite $appConfig.HubSiteUrl
        Enable-PnPFeature -Identity $appConfig.SPTaxonomyFeatureId -Scope Site
        Enable-PnPFeature -Identity $appConfig.DocSetFeatureId -Scope Site

        # ====================== NEW: CREATE DOCUMENT LIBRARY ======================
        # This runs for every channel (main site + separate channel sites)
        # Uses the exact config already have in ContentTypeMapping.psd1
        if ($chanConfig.LibraryName) {
            $libName = $chanConfig.LibraryName

            # Check first = idempotent script (safe to re-run)
            $existingLib = Get-PnPList -Identity $libName -ErrorAction SilentlyContinue

            if (-not $existingLib) {
                Write-Host "Creating new document library: $libName" -ForegroundColor Green

                $null = New-PnPList `
                    -Title $libName `
                    -Template DocumentLibrary `
                    -OnQuickLaunch `
                    -EnableVersioning

                Write-Host "✓ Document library '$libName' created successfully" -ForegroundColor Green
            }
            else {
                Write-Verbose "Library '$libName' already exists - skipping creation"
            }
        }
        # =====================================================================

        # === Content types & library settings from config ===
        # Pull every content type from the hub to the site
        foreach ($ctKey in $chanConfig.ContentTypeKeys) {
            Add-PnPContentTypesFromContentTypeHub -ContentTypes $contentConfig.$ctKey
        }

        if ($chanConfig.LibraryName) {
            Set-PnPList `
                -Identity $chanConfig.LibraryName `
                -EnableContentTypes $true `
                -EnableFolderCreation $chanConfig.EnableFolderCreation `
                -OpenDocumentsMode ClientApplication `
                -ErrorAction Stop

            # Small pause after enabling content types on the library
            Start-Sleep -Seconds 3

            # === NEW: Add EVERY content type to the library (not just the default) ===
            foreach ($ctKey in $chanConfig.ContentTypeKeys) {
                $ctId = $contentConfig.$ctKey
                Write-Verbose "Adding content type $ctKey ($ctId) to library $($chanConfig.LibraryName)"

                Add-PnPContentTypeToList -List $chanConfig.LibraryName -ContentType $ctId

                Start-Sleep -Seconds 2   # Give SharePoint time between each one
            }

            # Now set the default one (we already have this logic)
            Start-Sleep -Seconds 3
            Set-PnPDefaultContentTypeToList `
                -List $chanConfig.LibraryName `
                -ContentType $chanConfig.DefaultContentTypeName
        }
        Set-PnPSite -LogoFilePath $appConfig.LogoPath

        # === Views from config (using pre-captured name + fields + settings from template) ===
        if ($chanConfig.ViewNames.Count -gt 0) {

            $channelViews = $viewConfig[$channel.ConfigKey]   # e.g. ProjectDocuments, SurveyData, etc.

            if (-not $channelViews) {
                Write-Warning "No stored view definitions found for channel: $($channel.ConfigKey)"
            }
            else {
                foreach ($viewName in $chanConfig.ViewNames) {

                    $viewData = $channelViews[$viewName]

                    if ($viewData) {

                        Write-Host "  Creating/Applying view: $viewName" -ForegroundColor Green

                        # Remove the view first if it already exists (makes re-running safe and clean)
                        $existingView = Get-PnPView -List $chanConfig.LibraryName -Identity $viewName -ErrorAction SilentlyContinue
                        if ($existingView) {
                            Remove-PnPView -List $chanConfig.LibraryName -Identity $viewName -Force
                            Write-Verbose "Removed existing view '$viewName' before recreating"
                        }

                        # Create the view with fields and the most important settings
                        $null = Add-PnPView `
                            -List $chanConfig.LibraryName `
                            -Title $viewName `
                            -Fields $viewData.Fields `
                            -Query $viewData.Settings.ViewQuery `
                            -RowLimit $viewData.Settings.RowLimit `
                            -Paged:$viewData.Settings.Paged `
                            -Aggregations $viewData.Settings.Aggregations `
                            -ErrorAction Stop

                        # Apply additional display settings
                        $setValues = @{}
                        if ($viewData.Settings.Scope) { $setValues['Scope'] = $viewData.Settings.Scope }
                        if ($viewData.Settings.Toolbar) { $setValues['Toolbar'] = $viewData.Settings.Toolbar }
                        if ($viewData.Settings.JSLink) { $setValues['JSLink'] = $viewData.Settings.JSLink }
                        if ($viewData.Settings.ViewType) { $setValues['ViewType'] = $viewData.Settings.ViewType }

                        if ($setValues.Count -gt 0) {
                            Set-PnPView `
                                -List $chanConfig.LibraryName `
                                -Identity $viewName `
                                -Values $setValues `
                                -ErrorAction SilentlyContinue
                        }

                        Write-Verbose "Applied view '$viewName' with $($viewData.Fields.Count) fields + settings"
                    }
                    else {
                        Write-Warning "View '$viewName' not found in stored definitions for $($channel.ConfigKey)"
                    }
                }

                # Set the default view
                if ($chanConfig.DefaultView) {
                    Set-PnPView `
                        -List $chanConfig.LibraryName `
                        -Identity $chanConfig.DefaultView `
                        -Values @{ DefaultView = $true } `
                        -ErrorAction SilentlyContinue
                }
            }
        }

        # === RFI special handling ===
        if ($channel.ConfigKey -eq 'RequestForInformation') {

            try {
                Invoke-PnPSiteTemplate -Path $appConfig.RFITemplatePath -ErrorAction Stop
                Write-Host "✅ RFI template applied successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "ERROR applying RFI template:" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                Write-Host $_.Exception.InnerException.Message -ForegroundColor Red   # extra detail if available
            }
        }

        Disconnect-PnPOnline
        Write-Verbose "Finished $($channel.ConfigKey)"
    }

    Write-Verbose "Channel sites provisioning for $ProjectCode completed."
}