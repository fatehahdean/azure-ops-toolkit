# azure-ops-toolkit

PowerShell scripts for day-to-day Azure operations: waste detection, resource inventory, tag governance, and VM reporting. All scripts are tested against a live Azure subscription (screenshots below).

## Why this exists

Cloud environments accumulate waste and drift: unattached disks that keep billing, resources missing ownership tags, VMs left running overnight. These scripts automate the checks a cloud operations or advisory analyst would run before a cost or governance review.

## Scripts

| Script | Purpose |
|---|---|
| `Get-OrphanedResources.ps1` | Finds unattached disks, unused public IPs, and empty resource groups — resources that cost money or clutter the subscription without doing work |
| `Export-ResourceInventory.ps1` | Exports every resource (with tags and locations) to CSV, plus a count-by-type summary — a baseline for audits and cost discussions |
| `Get-TagAudit.ps1` | Checks all resources against required tags (default: `owner`, `env`) and reports a compliance percentage — supports custom tag lists |
| `Get-VmStatusReport.ps1` | Reports each VM's power state, size, and OS, and flags running VMs that may be incurring unnecessary compute charges |

All scripts include comment-based help (`Get-Help ./ScriptName.ps1 -Full`), parameter validation, and optional CSV export.

## Requirements

- [Az PowerShell module](https://learn.microsoft.com/powershell/azure/install-azure-powershell) (pre-installed in Azure Cloud Shell)
- An authenticated session: `Connect-AzAccount`
- Reader access to the target subscription

## Usage

```powershell
# Find waste
./Get-OrphanedResources.ps1 -ExportCsv

# Full inventory
./Export-ResourceInventory.ps1 -OutputPath ./inventory.csv

# Tag governance check with custom required tags
./Get-TagAudit.ps1 -RequiredTags owner,env,costcenter -ExportCsv

# VM power state report
./Get-VmStatusReport.ps1
```

## Sample output

### Orphaned resource detection
Found two empty resource groups left behind after project teardowns:

![Orphaned resources output](screenshots/orphaned-resources.png)

### Resource inventory
Six resources across the subscription, grouped by type:

![Inventory output](screenshots/inventory.png)

### Tag audit
The audit caught a real finding: resources deployed via Bicep without `owner`/`env` tags — 0% compliance, exactly the kind of drift this script exists to catch:

![Tag audit output](screenshots/tag-audit.png)

### VM status report
One running VM detected, with the cost warning triggered:

![VM status output](screenshots/vm-status.png)

## Notes from building this

- **SKU capacity restrictions are real**: `Standard_B1s` was unavailable in Southeast Asia for my subscription. `az vm list-skus` with the Restrictions column is the fastest way to find what you can actually deploy.
- **ARM vs x64 matters**: sizes with a `p` (e.g. `B2pls_v2`) are ARM-based — they need an `arm64` image variant or deployment fails with an architecture mismatch.
- **Cloud Shell without mounted storage is ephemeral**: files vanish between sessions. Cloning from GitHub each session is a clean workaround.

## Author

Fatehah Burhannudin — [github.com/fatehahdean](https://github.com/fatehahdean)
