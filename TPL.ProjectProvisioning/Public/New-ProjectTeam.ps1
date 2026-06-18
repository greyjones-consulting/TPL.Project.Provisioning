function New-ProjectTeam {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$ProjectCode,

        [Parameter(Mandatory)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string]$Owner,

        [Parameter(Mandatory = $false)]
        [string[]]$Members = @(),

        [Parameter(Mandatory)]
        [string]$ChannelOwner
    )

    Write-Verbose "Starting team provisioning for project $ProjectCode - $ProjectName"

    # ====================== LOAD CENTRALISED CONFIGURATION ======================
    $appConfig = Import-PowerShellDataFile -Path "$PSScriptRoot\..\Config\AppConfig.psd1"
    $teamTemplate = Import-PowerShellDataFile -Path "$PSScriptRoot\..\Config\TeamTemplate.psd1"

    # Resolve paths once (makes script more robust)
    $appConfig.LogoPath = Join-Path -Path $PSScriptRoot -ChildPath $appConfig.LogoPath
    $appConfig.ProjectTemplatePath = Join-Path -Path $PSScriptRoot -ChildPath $appConfig.ProjectTemplatePath
    $appConfig.CertificatePath = Join-Path -Path $PSScriptRoot -ChildPath $appConfig.CertificatePath
    $CertificatePath = $appConfig.CertificatePath
    $TeamsLogoPath = $appConfig.LogoPath

    $cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force
    $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($appConfig.CertificatePath, $cert)

    # ====================== DEFAULT DESCRIPTION ======================
    if ([String]::IsNullOrWhiteSpace($Description)) {
        $Description = $teamTemplate.DefaultDescriptionTemplate -f $ProjectName, $ProjectCode
    }

    # ====================== CONNECT TO TEAMS ======================
    $null = Connect-MicrosoftTeams `
        -ApplicationId $appConfig.ClientID `
        -TenantId $appConfig.Tenant `
        -Certificate $certificate `
        -ErrorAction Stop
    Write-Verbose "Connected to Microsoft Teams"

    # ====================== CREATE TEAM (only if it does not exist) ======================
    $existingTeamID = Get-Team | Where-Object { $_.MailNickName -eq $ProjectCode }

    if ($null -eq $existingTeamID) {
        Write-Verbose "Creating new Microsoft Team..."
        $newTeam = New-Team `
            -MailNickName $ProjectCode `
            -Owner $Owner `
            -DisplayName $ProjectName `
            -Description $Description `
            -AllowAddRemoveApps $false `
            -AllowCreatePrivateChannels $true `
            -AllowCreateUpdateChannels $false `
            -AllowCreateUpdateRemoveConnectors $false `
            -AllowCreateUpdateRemoveTabs $false `
            -AllowDeleteChannels $false

        Write-Host "Created New Microsoft Team with Project Code: $($newTeam.MailNickName)" -ForegroundColor Green

        # ====================== CREATE DEFAULT CHANNELS FROM TEMPLATE ======================
        Write-Verbose "Creating default channels from template..."
        foreach ($ch in $teamTemplate.DefaultChannels) {
            $addOwner = $false

            # Shared and Private channels both need an owner
            if ($ch.MembershipType -in @('Private', 'Shared')) {
                $addOwner = $true
            }

            $null = New-TeamChannel -GroupId $newTeam.GroupId `
                -DisplayName $ch.DisplayName `
                -Description $ch.Description `
                -MembershipType $ch.MembershipType `
                -Owner:($addOwner ? $ChannelOwner : $null)

            Write-Verbose "Created channel: $($ch.DisplayName) (Type: $($ch.MembershipType))"
        }

        # ====================== ADD OWNERS & MEMBERS ======================
        if ($Owner) { $Owner | ForEach-Object { $null = Add-TeamUser -Role Owner -User $_ -GroupId $newTeam.GroupId } }
        if ($Members) { $Members | ForEach-Object { $null = Add-TeamUser -Role Member -User $_ -GroupId $newTeam.GroupId } }

        Start-Sleep -Seconds 5

        # Store the GroupId so we can get the site URL later (works for both new and existing teams)
        $teamGroupId = $newTeam.GroupId

        # ====================== SET MICROSOFT TEAMS LOGO ======================
        if (Test-Path $TeamsLogoPath) {
            try {
                Write-Verbose "Updating Microsoft Teams team picture (logo)..."

                $null = Set-TeamPicture `
                    -GroupId $teamGroupId `
                    -ImagePath $TeamsLogoPath `
                    -ErrorAction Stop

                Write-Host "✅ Microsoft Teams logo updated successfully for project $ProjectCode" -ForegroundColor Green
            }
            catch {
                Write-Warning "Could not update Teams logo: $($_.Exception.Message)"
                # We don't want a logo issue to stop the whole team creation
            }
        }
        else {
            Write-Warning "Teams logo file not found at: $TeamsLogoPath"
        }
        # =====================================================================
    }

    else {
        # Team already exists → still return the URL
        Write-Verbose "Team $ProjectCode already exists. Retrieving existing site URL..."
        # Store the GroupId so we can get the site URL later
        $teamGroupId = $existingTeamID.GroupId

        # ====================== SET MICROSOFT TEAMS LOGO ======================
        if (Test-Path $TeamsLogoPath) {
            try {
                Write-Verbose "Updating Microsoft Teams team picture (logo)..."

                Set-TeamPicture `
                    -GroupId $teamGroupId `
                    -ImagePath $TeamsLogoPath `
                    -ErrorAction Stop

                Write-Host "✅ Microsoft Teams logo updated successfully for project $ProjectCode" -ForegroundColor Green
            }
            catch {
                Write-Warning "Could not update Teams logo: $($_.Exception.Message)"
                # We don't want a logo issue to stop the whole team creation
            }
        }
        else {
            Write-Warning "Teams logo file not found at: $TeamsLogoPath"
        }
        # =====================================================================


    }

    # ====================== GET MAIN TEAM SITE URL (Always runs - for new AND existing teams) ======================
    Write-Verbose "Retrieving main team site URL using PnP..."

    $null = Connect-PnPOnline -Url $appConfig.AdminUrl `
        -ClientId $appConfig.ClientID `
        -Tenant $appConfig.Tenant `
        -CertificatePath $CertificatePath `
        -CertificatePassword $cert `
        -ErrorAction Stop

    $msGroup = Get-PnPMicrosoft365Group -IncludeSiteUrl -Identity $teamGroupId
    $mainTeamSiteUrl = [string]$msGroup.SiteUrl

    # Safety check - prevents returning $null (fixes your error)
    if ([string]::IsNullOrWhiteSpace($mainTeamSiteUrl)) {
        Write-Error "Failed to retrieve SiteUrl for team $ProjectCode. GroupId: $teamGroupId" -ErrorAction Stop
    }

    Write-Verbose "Main team site URL retrieved successfully: $mainTeamSiteUrl"

    # ====================== APPLY PROJECT SITE TEMPLATE TO MAIN TEAM HOMEPAGE ======================
    if (Test-Path $appConfig.ProjectTemplatePath) {
        try {
            Write-Host "Applying custom project site template to main team site..." -ForegroundColor Cyan

            Wait-ForChannelSite `
                -Url $mainTeamSiteUrl `
                -CertificatePath $CertificatePath
            # Re-connect to the actual team site (required for Invoke-PnPSiteTemplate)

            $null = Connect-PnPOnline `
                -Url $mainTeamSiteUrl `
                -ClientId $appConfig.ClientID `
                -Tenant $appConfig.Tenant `
                -CertificatePath $CertificatePath `
                -CertificatePassword $cert `
                -ErrorAction Stop

            Invoke-PnPSiteTemplate `
                -Path $appConfig.ProjectTemplatePath `
                -ErrorAction Stop

            Write-Host "✅ Project site template applied successfully to $mainTeamSiteUrl" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not apply project site template: $($_.Exception.Message)"
            # Do not stop the whole script – the team is still created successfully
        }
    }
    else {
        Write-Warning "Project template file not found at: $($appConfig.ProjectTemplatePath)"
    }
    # =====================================================================

    # ====================== SYNC PROJECT DATA TO DISTRIBUTION LISTS ======================
    # This runs automatically every time a new team is created
    Write-Host "Syncing project data to Marketing, HR and Project Pipeline lists..." -ForegroundColor Cyan
    Sync-ProjectDataToLists -ProjectCode $ProjectCode -Verbose

    # Return ONLY the clean URL string
    return $mainTeamSiteUrl
}