# ====================== REUSABLE WAIT FUNCTION ======================
function Wait-ForChannelSite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$CertificatePath
    )

    $timeout = 600          # Increased to 10 minutes - channel sites can take longer
    $elapsed = 0
    $interval = 5          # Check every 10 seconds instead of 5 (less aggressive)
    $siteReady = $false

    # Get module root reliably
    $ModuleRoot = $MyInvocation.MyCommand.Module.ModuleBase
    $configPath = Join-Path -Path $ModuleRoot -ChildPath "Config\AppConfig.psd1"
    $appConfig = Import-PowerShellDataFile -Path $configPath

    $cert = $appConfig.CertificatePassword
    $cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

    Write-Verbose "Waiting for site to become ready: $Url"
    Write-Host "Waiting for channel site to provision..." -ForegroundColor Yellow

    do {
        Start-Sleep -Seconds $interval
        $elapsed += $interval

        try {
            # Always start with a fresh connection attempt
            Connect-PnPOnline `
                -Url $Url `
                -ClientId $appConfig.ClientID `
                -Tenant $appConfig.Tenant `
                -CertificatePath $CertificatePath `
                -CertificatePassword $cert `
                -ErrorAction Stop

            $null = Get-PnPSite -ErrorAction Stop
            $siteReady = $true

            Write-Host "✅ Site is now ready: $Url" -ForegroundColor Green
            Write-Verbose "Site is now ready: $Url"
        }
        catch {
            Write-Verbose "Site not ready yet (attempt $elapsed seconds): $($_.Exception.Message)"
            # Disconnect any half-broken connection
            Disconnect-PnPOnline -ErrorAction SilentlyContinue
        }

        if ($elapsed -ge $timeout) {
            throw "Timed out waiting for site: $Url after $timeout seconds"
        }
    } while (-not $siteReady)

    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}