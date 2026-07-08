<#
.SYNOPSIS
    Finds orphaned (unused but billable) resources in an Azure subscription.

.DESCRIPTION
    Scans the current subscription for three types of waste:
      1. Unattached managed disks  - disks not connected to any VM
      2. Unused public IP addresses - IPs not associated with anything
      3. Empty resource groups      - groups containing zero resources

    Results are shown in the console. Use -ExportCsv to also save a CSV report.

.PARAMETER ExportCsv
    Optional. If provided, saves results to OrphanedResources.csv
    in the current folder.

.EXAMPLE
    ./Get-OrphanedResources.ps1

.EXAMPLE
    ./Get-OrphanedResources.ps1 -ExportCsv

.NOTES
    Author : Fatehah
    Requires: Az PowerShell module, logged in via Connect-AzAccount
#>

param(
    [switch]$ExportCsv
)

# --- Check we are logged in to Azure ---
$context = Get-AzContext
if (-not $context) {
    Write-Error "Not logged in. Run Connect-AzAccount first."
    exit 1
}

Write-Host "Scanning subscription: $($context.Subscription.Name)" -ForegroundColor Cyan
Write-Host ""

$findings = @()

# --- 1. Unattached managed disks ---
Write-Host "[1/3] Checking for unattached disks..." -ForegroundColor Yellow
$disks = Get-AzDisk | Where-Object { $_.DiskState -eq 'Unattached' }
foreach ($disk in $disks) {
    $findings += [PSCustomObject]@{
        Type          = 'Unattached Disk'
        Name          = $disk.Name
        ResourceGroup = $disk.ResourceGroupName
        Detail        = "$($disk.DiskSizeGB) GB, SKU: $($disk.Sku.Name)"
    }
}
Write-Host "    Found: $($disks.Count)"

# --- 2. Unused public IP addresses ---
Write-Host "[2/3] Checking for unused public IPs..." -ForegroundColor Yellow
$ips = Get-AzPublicIpAddress | Where-Object { -not $_.IpConfiguration }
foreach ($ip in $ips) {
    $findings += [PSCustomObject]@{
        Type          = 'Unused Public IP'
        Name          = $ip.Name
        ResourceGroup = $ip.ResourceGroupName
        Detail        = "IP: $($ip.IpAddress), SKU: $($ip.Sku.Name)"
    }
}
Write-Host "    Found: $($ips.Count)"

# --- 3. Empty resource groups ---
Write-Host "[3/3] Checking for empty resource groups..." -ForegroundColor Yellow
$emptyGroups = 0
foreach ($rg in Get-AzResourceGroup) {
    $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
    if ($resources.Count -eq 0) {
        $emptyGroups++
        $findings += [PSCustomObject]@{
            Type          = 'Empty Resource Group'
            Name          = $rg.ResourceGroupName
            ResourceGroup = '-'
            Detail        = "Location: $($rg.Location)"
        }
    }
}
Write-Host "    Found: $emptyGroups"
Write-Host ""

# --- Results ---
if ($findings.Count -eq 0) {
    Write-Host "No orphaned resources found. Subscription is clean." -ForegroundColor Green
}
else {
    Write-Host "Total orphaned resources: $($findings.Count)" -ForegroundColor Red
    $findings | Format-Table -AutoSize

    if ($ExportCsv) {
        $findings | Export-Csv -Path "OrphanedResources.csv" -NoTypeInformation
        Write-Host "Report saved to OrphanedResources.csv" -ForegroundColor Green
    }
}
