$subscriptionID="c83e41ff-0233-46b3-9bb1-826cd887b446"
$resourceGroup="oardevol-hybrid"
$location="westeurope"
$resourceName="oardevol-bridge"
$workDirectory="V:\AKS-HCI\"
$vswitchname="InternalNAT"
$ipaddressprefix="192.168.0.0/16"
$gateway="192.168.0.1"
$dnsservers="192.168.0.1"
$vmIP="192.168.0.200"
$controlPlaneIP="192.168.0.201"

# register providers
az provider register --namespace Microsoft.Kubernetes --wait
az provider register --namespace Microsoft.ExtendedLocation --wait
az provider register --namespace Microsoft.ResourceConnector --wait
az provider register --namespace Microsoft.HybridContainerService --wait
az provider register --namespace Microsoft.HybridConnectivity --wait

az extension add -n k8s-extension
az extension add -n customlocation
az extension add -n arcappliance --version 0.2.27
az extension add -n hybridaks

Install-Module -Name ArcHci -Force -Confirm:$false -SkipPublisherCheck -AcceptLicense

New-ArcHciAksConfigFiles -subscriptionID $subscriptionID -location $location -resourceGroup $resourceGroup `
    -resourceName $resourceName -workDirectory $workDirectory -vnetName $vswitchname `
    -vswitchName $vswitchName -ipaddressprefix $ipaddressprefix -gateway $gateway -dnsservers $dnsservers `
    -controlPlaneIP $controlPlaneIP -k8snodeippoolstart $vmIP -k8snodeippoolend $vmIP

$configfile = $workDirectory+"\hci-appliance.yaml"
$appliancekubeconfig = $workDirectory+"\applianceconfig"

az arcappliance validate hci --config-file $configfile
az arcappliance prepare hci --config-file $configfile

az arcappliance deploy hci --config-file $configfile --outfile $appliancekubeconfig
az arcappliance create hci --config-file $configfile --kubeconfig $appliancekubeconfig
# Wait until connected
az arcappliance show --resource-group $resourceGroup --name $resourceName --query "status" -o tsv

# Install aks extension
$extensionName=$resourceName+"-ext"
az k8s-extension create --resource-group $resourceGroup --cluster-name $resourceName --cluster-type appliances `
    --name $extensionName --extension-type Microsoft.HybridAKSOperator `
    --config Microsoft.CustomLocation.ServiceAccount="default"   
# Wait for succeeded
az k8s-extension show --resource-group $resourceGroup --cluster-name $resourceName --cluster-type appliances `
    --name $extensionName --query "provisioningState" -o tsv

# Create custom location
$ArcResourceBridgeId=az arcappliance show --resource-group $resourceGroup --name $resourceName --query id -o tsv
$AKSClusterExtensionResourceId=az k8s-extension show --resource-group $resourceGroup --cluster-name $resourceName `
     --cluster-type appliances --name $extensionName --query id -o tsv

$customLocationName=$resourceName
az customlocation create --name $customLocationName --namespace "default" --host-resource-id $ArcResourceBridgeId --cluster-extension-ids $AKSClusterExtensionResourceId --resource-group $resourceGroup
# Wait for succeeded
az customlocation show --name $customLocationName --resource-group $resourceGroup --query "provisioningState" -o tsv
$customlocationID=az customlocation show --name $customLocationName --resource-group $resourceGroup --query "id" -o tsv


# Create AKS cluster
$clustervnetname = "oriol-bridge-vnet-01"
$vswitchname="InternalNAT"
$ipaddressprefix="192.168.0.0/16"
$gateway="192.168.0.1"
$dnsservers="192.168.0.1"
$vmPoolStart="192.168.0.205"
$vmPoolEnd="192.168.0.215"
$vipPoolStart="192.168.0.216"
$vipPoolEnd="192.168.0.225"

# Create aks hybrid vnet
New-KvaVirtualNetwork -name $clustervnetname -vswitchname $vswitchname `
    -ipaddressprefix $ipaddressprefix -gateway $gateway -dnsservers $dnsServers `
    -vippoolstart $vipPoolStart -vippoolend $vipPoolEnd `
    -k8snodeippoolstart $vmPoolStart -k8snodeippoolend $vmPoolEnd `
    -kubeconfig $appliancekubeconfig

# Link aks hybrid vnet to Azure vnet
az hybridaks vnet create -n $clustervnetname -g $resourceGroup --custom-location $customlocationID --moc-vnet-name $clustervnetname
$vnetId=az
hybridaks vnet show --name $clustervnetname --resource-group $resourceGroup --query "id" -o tsv

#download k8s vhd file, must be 1.21.9
Add-KvaGalleryImage -kubernetesVersion 1.21.9

# Create aks cluster, alternatively, use portal
az hybridaks create -n "oardevol-hybrid-aks-01" -g $resourceGroup --custom-location $customlocationID --vnet-ids $vnetId `
    --aad-admin-group-object-ids "59ed0a52-e018-4bcc-bdd5-ea81778405bf" --generate-ssh-keys
