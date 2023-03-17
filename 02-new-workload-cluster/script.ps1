# Variables used in this script, defined in ../env.ps1
# $workloadClusterName, $subscriptionId, $tenantId

# Create cluster with new network settings, so that the cluster can use different vipPoolStart and vipPoolEnd than the management cluster
$vnet = New-AksHciClusterNetwork -name $workloadClusterName -vswitchName "InternalNAT" -gateway "192.168.0.1" -dnsServers "192.168.0.1" -ipAddressPrefix "192.168.0.0/16" -vipPoolStart "192.168.1.150" -vipPoolEnd "192.168.1.250" -k8sNodeIpPoolStart "192.168.1.3" -k8sNodeIpPoolEnd "192.168.1.149"
New-AksHciCluster -name $workloadClusterName -nodePoolName linuxnodepool -controlPlaneNodeCount 1 -nodeCount 1 -osType linux -vnet $vnet

# We could also create a cluster with the default network settings by ommiting the -vnet parameter
# New-AksHciCluster -name $workloadClusterName -nodePoolName linuxnodepool -controlPlaneNodeCount 1 -nodeCount 1 -osType linux

# View cluster resources
Get-AksHciCluster
Get-AksHciNodePool -clusterName $workloadClusterName

# At this point you can work with kubectl against your k8s cluster
# See next module on how to get credentials and connect to the cluster

### Manage the cluster

# Add nodePool
New-AksHciNodePool -clusterName $workloadClusterName -name windowsnodepool -count 1 -osType windows

# Scale nodePool
Set-AksHciNodePool -clusterName $workloadClusterName -name linuxnodepool -count 2
# Scale controlPlane
Set-AksHciCluster –Name $workloadClusterName -controlPlaneNodeCount 3


### Integrate the workload cluster with Azure Arc

# Sign in to Azure
Connect-AzAccount -Tenant $tenantId
Set-AzContext -Subscription $subscriptionId

# Make the connection of the cluster with Azure Arc
Enable-AksHciArcConnection -name $workloadClusterName