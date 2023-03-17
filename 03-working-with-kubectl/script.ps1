# Variables used in this script, defined in ../env.ps1
# $clusterName

# Get credentials for the cluster
Get-AksHciCredential -name $clusterName -Confirm:$false
# The credentials are stored in the kubeconfig file in the user's home directory
dir $env:USERPROFILE\.kube

# View all the resources in the cluster
kubectl get all

# Deploy a sample application
kubectl apply -f https://raw.githubusercontent.com/Azure/aks-hci/main/eval/yaml/azure-vote.yaml

