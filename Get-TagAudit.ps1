<#
.SYNOPSIS
    Audits resources for missing required tags.

.DESCRIPTION
    Checks every resource in the subscription against a list of required
    tags (default: owner, env). Reports which resources are compliant and
    which are missing tags. Supports CSV export for governance reviews.

.PARAMETER RequiredTags
    Optional. Array of tag names every resource should have.
    Default: owner, env

.PARAMETER ExportCsv
    Optional. If provided, saves results to TagAudit.csv

.EXAMPLE
    ./Get-TagAudit.ps1

.EXAMPLE
    ./Get-TagAudit.ps1 -RequiredTags owner,env,costcenter -ExportCsv

.NOTES
    Author : Fatehah
    Requires: Az PowerShell module, logged in via Connect-AzAccount
#>

param(
    [string[]]$RequiredTags = @('owner', 'env'),
    [switch]$ExportCsv
)

# --- Check we are logged in to Azure ---
$context = Get-AzContext
if (-not $context) {
    Write-Error "Not logged in. Run Connect-AzAccount first."
    exit 1
}

Write-Host "Tag audit for subscription: $($context.Subscription.Name)" -ForegroundColor Cyan
Write-Host "Required tags: $($RequiredTags -join ', ')" -ForegroundColor Cyan
Write-Host ""

$resources = Get-AzResource
if ($resources.Count -eq 0) {
    Write-Host "No resources found in this subscription." -ForegroundColor Yellow
    exit 0
}

$results = foreach ($res in $resources) {
    $existingTags = if ($res.Tags) { $res.Tags.Keys } else { @() }
    $missing = $RequiredTags | Where-Object { $_ -notin $existingTags }

    [PSCustomObject]@{
        Name          = $res.Name
        Type          = $res.ResourceType
        ResourceGroup = $res.ResourceGroupName
        MissingTags   = if ($missing) { $missing -join ', ' } else { '-' }
        Compliant     = if ($missing) { 'No' } else { 'Yes' }
    }
}

# --- Summary ---
$compliant    = ($results | Where-Object Compliant -eq 'Yes').Count
$nonCompliant = ($results | Where-Object Compliant -eq 'No').Count
$percent      = [math]::Round(($compliant / $results.Count) * 100, 1)

Write-Host "Total resources : $($results.Count)"
Write-Host "Compliant       : $compliant" -ForegroundColor Green
Write-Host "Non-compliant   : $nonCompliant" -ForegroundColor Red
Write-Host "Compliance rate : $percent%"
Write-Host ""

$results | Sort-Object Compliant | Format-Table -AutoSize

if ($ExportCsv) {
    $results | Export-Csv -Path "TagAudit.csv" -NoTypeInformation
    Write-Host "Report saved to TagAudit.csv" -ForegroundColor Green
}
