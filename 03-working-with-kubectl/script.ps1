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

### Working with kubectl
# If you want to familiarize yourself with kubect, see the following cheatsheet
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/
# Here are some examples

# View the application
kubectl get svc azure-vote-front --watch

# View the logs of the application
kubectl logs -l app=azure-vote-front

# Describe the application and the pods
kubectl describe svc azure-vote-front
kubectl describe pods -l app=azure-vote-front

# Attach to a pod (send exit command to disconnect)
$podName=$(kubectl get pods --selector=app=azure-vote-back --output=jsonpath="{.items..metadata.name}")
kubectl exec -it $podName -- /bin/sh

# View all namespaces
kubectl get ns

# View all pods in all namespaces
kubectl get pods --all-namespaces

# View services running in all namespaces
kubectl get svc --all-namespaces --sort-by=.metadata.name

# Connect to the AKS management cluster
$mgmtConfig="V:\AKS-HCI\WorkingDir\$(Get-AksHciVersion)\kubeconfig-mgmt"
kubectl --kubeconfig=$mgmtConfig get pods --all-namespaces
