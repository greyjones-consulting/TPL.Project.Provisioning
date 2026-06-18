<#
.SYNOPSIS
    Entry-point script for provisioning GreyJones project teams.

.DESCRIPTION
    Performs safety checks, reads the Excel data, and calls the clean module functions.
    All actual provisioning logic now lives in the module.
#>

[CmdletBinding()]
param()

# ====================== SAFETY CHECKS ======================
Write-Host "Have you updated the client logo? (y/n)" -ForegroundColor Yellow
$answer1 = Read-Host
if ($answer1 -notmatch '^(y|yes)$') {
    Write-Host "Operation cancelled." -ForegroundColor Red
    exit
}

Write-Host "Have you input the project data in the excel document? (y/n)" -ForegroundColor Yellow
$answer2 = Read-Host
if ($answer2 -notmatch '^(y|yes)$') {
    Write-Host "Operation cancelled." -ForegroundColor Red
    exit
}

Write-Host "Creating project..." -ForegroundColor Green

# ====================== IMPORT THE PROVISIONING MODULE ======================
$modulePath = Join-Path $PSScriptRoot "..\GreyJones.ProjectProvisioning\GreyJones.ProjectProvisioning.psd1"
Import-Module $modulePath -Force -ErrorAction Stop

# ====================== LOAD EXCEL DATA (moved to new Data folder) ======================
$excelPath = Join-Path $PSScriptRoot "..\Data\projectCodeArray.xlsx"

if (-not (Test-Path $excelPath)) {
    Write-Host "Excel file not found at path: $excelPath" -ForegroundColor Red
    exit
}

$data = Import-Excel -Path $excelPath -WorksheetName "projectCodes"

# ====================== PROCESS EACH PROJECT ======================
foreach ($row in $data) {

    $projectCode = $row.ProjectCode
    $projectName = $row.ProjectName
    $description = $row.Description

    # Fixed values (you can later make these parameters or move to Config)
    $owner = "blakej@greyjones.co.za"
    $members = @()                     # Empty array – add emails here if needed
    $channelOwner = "blakej@greyjones.co.za"

    Write-Host "Provisioning Team for: $projectCode - $projectName - $description" -ForegroundColor Cyan

    # === Call the new module functions ===
    $mainTeamSiteUrl = New-ProjectTeam `
        -ProjectCode $projectCode `
        -ProjectName $projectName `
        -Description $description `
        -Owner $owner `
        -Members $members `
        -ChannelOwner $channelOwner `
        -Verbose

    Write-Host "Returned value from New-ProjectTeam: '$mainTeamSiteUrl'" -ForegroundColor Cyan
    Write-Host "Type of returned value: $($mainTeamSiteUrl.GetType().FullName)" -ForegroundColor Cyan   # This will show if it's null or string[]

    Invoke-ChannelSitesProvisioning `
        -ProjectCode $projectCode `
        -ProjectName $projectName `
        -MainTeamSiteUrl $mainTeamSiteUrl `
        -Verbose

    Write-Host "Completed: $projectCode - $projectName" -ForegroundColor Green
    Write-Host "-------------------------------------------------------------------------------------------------------------" -ForegroundColor Blue
}

# ====================== CLEAN UP ======================
Disconnect-MicrosoftTeams
Write-Host "All projects processed successfully." -ForegroundColor Green