# Power down VMs on your Hyper-V host
Get-VM | Stop-VM -Force

# Update AksHci to latest version
Update-Module -Name AksHci -Force -AcceptLicense -Verbose

# Get VMs network configuration
Get-NetAdapter
Get-NetNat