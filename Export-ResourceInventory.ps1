<#
.SYNOPSIS
    Exports a full inventory of all resources in the subscription to CSV.

.DESCRIPTION
    Lists every resource in the current subscription with its name, type,
    resource group, location, and tags. Useful as a baseline for audits,
    governance reviews, and cost discussions.

.PARAMETER OutputPath
    Optional. File path for the CSV report.
    Default: ResourceInventory.csv in the current folder.

.EXAMPLE
    ./Export-ResourceInventory.ps1

.EXAMPLE
    ./Export-ResourceInventory.ps1 -OutputPath ./reports/inventory.csv

.NOTES
    Author : Fatehah
    Requires: Az PowerShell module, logged in via Connect-AzAccount
#>

param(
    [string]$OutputPath = "ResourceInventory.csv"
)

# --- Check we are logged in to Azure ---
$context = Get-AzContext
if (-not $context) {
    Write-Error "Not logged in. Run Connect-AzAccount first."
    exit 1
}

Write-Host "Building inventory for subscription: $($context.Subscription.Name)" -ForegroundColor Cyan

# --- Collect all resources ---
$resources = Get-AzResource

if ($resources.Count -eq 0) {
    Write-Host "No resources found in this subscription." -ForegroundColor Yellow
    exit 0
}

$inventory = foreach ($res in $resources) {
    # Turn the tags hashtable into a readable string like "env=dev; owner=fatehah"
    $tagString = if ($res.Tags -and $res.Tags.Count -gt 0) {
        ($res.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; '
    }
    else {
        "(no tags)"
    }

    [PSCustomObject]@{
        Name          = $res.Name
        Type          = $res.ResourceType
        ResourceGroup = $res.ResourceGroupName
        Location      = $res.Location
        Tags          = $tagString
    }
}

# --- Show summary in console ---
Write-Host ""
Write-Host "Total resources: $($inventory.Count)" -ForegroundColor Green
Write-Host ""
Write-Host "Breakdown by type:" -ForegroundColor Cyan
$inventory | Group-Object Type | Sort-Object Count -Descending |
    Select-Object Count, Name | Format-Table -AutoSize

# --- Export to CSV ---
$inventory | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "Inventory saved to: $OutputPath" -ForegroundColor Green
