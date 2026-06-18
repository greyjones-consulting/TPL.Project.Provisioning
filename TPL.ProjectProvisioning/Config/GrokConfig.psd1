@{
    # === Grok SharePoint Connector security (Marketing sites only) ===
    # This config is used by Grant-GrokConnectorReadAccess.ps1
    # The connector from console.x.ai can ONLY read these Marketing sites
    GrokConnectorAppId = '381c36a9-2187-4773-8f2f-67bf074b6c76'

    MarketingSites     = @(
        "https://greyjonescoza.sharepoint.com/sites/Marketing",
        "https://greyjonescoza.sharepoint.com/sites/Marketing-LeadsAndTenders",   # private channel
        "https://greyjonescoza.sharepoint.com/sites/Marketing-SocialMedia",      # private channel
        "https://greyjonescoza.sharepoint.com/sites/Marketing-Transmittals"      # private channel
    )
}