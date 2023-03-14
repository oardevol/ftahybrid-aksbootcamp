$clusterName="wld01-cluster"
$subscriptionId = "f89ca1d5-8a0f-413e-aa15-8d22bf52c8f6"

# Create cluster with network
$vnet = New-AksHciClusterNetwork -name $clusterName -vswitchName "InternalNAT" -gateway "192.168.0.1" -dnsServers "192.168.0.1" -ipAddressPrefix "192.168.0.0/16" -vipPoolStart "192.168.1.150" -vipPoolEnd "192.168.1.250" -k8sNodeIpPoolStart "192.168.1.3" -k8sNodeIpPoolEnd "192.168.1.149"
New-AksHciCluster -name $clusterName -nodePoolName linuxnodepool -controlPlaneNodeCount 1 -nodeCount 1 -osType linux -vnet $vnet

# Create cluster in mgmt network
New-AksHciCluster -name $clusterName -nodePoolName linuxnodepool -controlPlaneNodeCount 1 -nodeCount 1 -osType linux

# View cluster resources
Get-AksHciCluster
Get-AksHciNodePool -clusterName $clusterName

# Add nodePool
New-AksHciNodePool -clusterName $clusterName -name windowsnodepool -count 1 -osType windows

# Scale nodePool
Set-AksHciNodePool -clusterName $clusterName -name linuxnodepool -count 2
# Scale control controlPlane
Set-AksHciCluster –Name $clusterName -controlPlaneNodeCount 3

# Sign in to Azure
Connect-AzAccount
Set-AzContext -Subscription $subscriptionId

# Integrate your target cluster with Azure Arc
Enable-AksHciArcConnection -name $clusterName