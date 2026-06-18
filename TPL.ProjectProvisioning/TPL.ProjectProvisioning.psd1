@{
    ModuleVersion     = '1.0.3'
    GUID              = '2cd86880-7b6b-423e-8729-d9534efdcd79'
    Author            = 'Blake Jones'
    CompanyName       = 'GreyJones (PTY) Ltd.'
    Copyright         = '(c) 2026 GreyJones. All rights reserved.'
    Description       = 'Professional PowerShell module for provisioning standardised Transnet Pipelines Microsoft Teams project sites, channels, and SharePoint customisations.'
    RootModule        = 'TPL.ProjectProvisioning.psm1'
    FunctionsToExport = @('New-ProjectTeam', 'Invoke-ChannelSitesProvisioning', 'Sync-ProjectDataToLists', 'Sync-AllProjectDataToLists', 'New-ProjectDocumentSets', 'Grant-GrokAppSiteAccess', 'Grant-GrokConnectorReadAccess')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PowerShellVersion = '5.1'
}