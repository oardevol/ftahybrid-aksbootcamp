# Variables used in this script, defined in ../env.ps1
# $subscriptionId, $tenenantId, $resourceGroup

# Sign in to Azure
Connect-AzAccount -Tenant $tenenantId
Set-AzContext -Subscription $subscriptionId

# Check if resource providers are registered and register if not
if ((Get-AzResourceProvider -ProviderNamespace Microsoft.Kubernetes).RegistrationState -ne "Registered") {
    Register-AzResourceProvider -ProviderNamespace Microsoft.Kubernetes
}
if ((Get-AzResourceProvider -ProviderNamespace Microsoft.KubernetesConfiguration).RegistrationState -ne "Registered") {
   Register-AzResourceProvider -ProviderNamespace Microsoft.KubernetesConfiguration
}

# Verify that provider are registered in the subscription
Get-AzResourceProvider -ProviderNamespace Microsoft.Kubernetes
Get-AzResourceProvider -ProviderNamespace Microsoft.KubernetesConfiguration

# Initialize node. Run checks on every physical node to see if all requirements are satisfied to install AKS hybrid.
Initialize-AksHciNode

# Create folders in V: drive
New-Item -Path "V:\" -Name "AKS-HCI" -ItemType "directory" -Force
New-Item -Path "V:\AKS-HCI\" -Name "Images" -ItemType "directory" -Force
New-Item -Path "V:\AKS-HCI\" -Name "WorkingDir" -ItemType "directory" -Force
New-Item -Path "V:\AKS-HCI\" -Name "Config" -ItemType "directory" -Force

# Create network
$vnet = New-AksHciNetworkSetting -name "mgmtvnet" -vSwitchName "InternalNAT" -gateway "192.168.0.1" -dnsservers "192.168.0.1" `
    -ipaddressprefix "192.168.0.0/16" -k8snodeippoolstart "192.168.0.3" -k8snodeippoolend "192.168.0.149" `
    -vipPoolStart "192.168.0.150" -vipPoolEnd "192.168.0.250"

# Configure aks host (use specific version if you're planning to deploy Arc Resource Bridge)
Set-AksHciConfig -vnet $vnet -imageDir "V:\AKS-HCI\Images" -workingDir "V:\AKS-HCI\WorkingDir" `
   -cloudConfigLocation "V:\AKS-HCI\Config" -Verbose -version "1.0.13.10907"

Set-AksHciRegistration -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroup

# Install AKS host
Install-AksHci