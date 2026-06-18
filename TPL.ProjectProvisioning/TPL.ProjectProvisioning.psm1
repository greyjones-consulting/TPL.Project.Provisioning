# GreyJones.ProjectProvisioning.psm1

# Dot-source all Public functions (visible commands)
Get-ChildItem -Path $PSScriptRoot\Public -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

# Dot-source all Private functions (internal helpers only)
Get-ChildItem -Path $PSScriptRoot\Private -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

# Export only the public functions
Export-ModuleMember -Function *   # or list them explicitly in the .psd1 manifest

Write-Verbose "TPL.ProjectProvisioning module loaded successfully."