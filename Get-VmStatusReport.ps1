<#
.SYNOPSIS
    Reports the power state, size, and OS of every VM in the subscription.

.DESCRIPTION
    Lists all virtual machines with their current power state (running,
    stopped, deallocated), VM size, OS type, and resource group. Flags
    running VMs so cost owners can spot machines left on by mistake.

.PARAMETER ExportCsv
    Optional. If provided, saves results to VmStatusReport.csv

.EXAMPLE
    ./Get-VmStatusReport.ps1

.EXAMPLE
    ./Get-VmStatusReport.ps1 -ExportCsv

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

Write-Host "VM status report for subscription: $($context.Subscription.Name)" -ForegroundColor Cyan
Write-Host ""

# -Status is needed to get the live power state
$vms = Get-AzVM -Status

if ($vms.Count -eq 0) {
    Write-Host "No virtual machines found in this subscription." -ForegroundColor Yellow
    exit 0
}

$report = foreach ($vm in $vms) {
    [PSCustomObject]@{
        Name          = $vm.Name
        ResourceGroup = $vm.ResourceGroupName
        PowerState    = $vm.PowerState
        Size          = $vm.HardwareProfile.VmSize
        OS            = $vm.StorageProfile.OsDisk.OsType
        Location      = $vm.Location
    }
}

# --- Summary ---
$running = ($report | Where-Object PowerState -like '*running*').Count
$stopped = $report.Count - $running

Write-Host "Total VMs : $($report.Count)"
Write-Host "Running   : $running" -ForegroundColor $(if ($running -gt 0) { 'Yellow' } else { 'Green' })
Write-Host "Stopped   : $stopped"
Write-Host ""

$report | Format-Table -AutoSize

if ($running -gt 0) {
    Write-Host "Note: running VMs incur compute charges. Deallocate any not in use." -ForegroundColor Yellow
}

if ($ExportCsv) {
    $report | Export-Csv -Path "VmStatusReport.csv" -NoTypeInformation
    Write-Host "Report saved to VmStatusReport.csv" -ForegroundColor Green
}
