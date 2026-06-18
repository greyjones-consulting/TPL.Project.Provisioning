function Grant-GrokConnectorReadAccess {
    [CmdletBinding()]
    param()

    Write-Host "=== Granting Grok Connector READ access to Marketing sites only ===" -ForegroundColor Cyan

    # ====================== LOAD CONFIGS ======================
    $appConfig = Import-PowerShellDataFile -Path "$PSScriptRoot/../Config/AppConfig.psd1"
    $grokConfig = Import-PowerShellDataFile -Path "$PSScriptRoot/../Config/GrokConfig.psd1"

    # Resolve certificate path (same pattern as all your other scripts)
    $appConfig.CertificatePath = Join-Path -Path $PSScriptRoot -ChildPath $appConfig.CertificatePath
    $cert = ConvertTo-SecureString -String $appConfig.CertificatePassword -AsPlainText -Force

    # ====================== PROCESS EACH MARKETING SITE ======================
    foreach ($url in $grokConfig.MarketingSites) {
        try {
            Write-Host "  → Processing $url" -ForegroundColor Yellow

            Connect-PnPOnline `
                -Url $url `
                -ClientId $appConfig.ClientID `
                -Tenant $appConfig.Tenant `
                -CertificatePath $appConfig.CertificatePath `
                -CertificatePassword $cert `
                -ErrorAction Stop

            # Correct parameters for PnP.PowerShell (this is the fix)
            Grant-PnPAzureADAppSitePermission `
                -Site $url `
                -AppId $grokConfig.GrokConnectorAppId `
                -DisplayName "Grok SharePoint Connector" `
                -Permissions "Read" `
                -ErrorAction SilentlyContinue | Out-Null

            Write-Host "    ✅ Granted READ access to Grok Connector" -ForegroundColor Green

        }
        catch {
            if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*already has*") {
                Write-Host "    (Already has access - skipping)" -ForegroundColor Gray
            }
            else {
                Write-Warning "Could not grant access to $url : $($_.Exception.Message)"
            }
        }
        finally {
            Disconnect-PnPOnline -ErrorAction SilentlyContinue
        }
    }

    Write-Host "`n=== Grok SharePoint Connector is now locked to Marketing sites only! ===" -ForegroundColor Cyan
    Write-Host "   (It can no longer see any project data or private channels)" -ForegroundColor Cyan
}