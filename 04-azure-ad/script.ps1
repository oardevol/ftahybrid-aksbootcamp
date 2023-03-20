# Variables used in this script, defined in ../env.ps1
# $subscriptionId, $tenantId, $resourceGroup

# Define variables
$group_name="aks-bootcamp-users"

# Login to az cli
az login --tenant $tenantId
az account set --subscription $subscriptionId

# Create Azure AD group
az ad group create --display-name $group_name --mail-nickname $group_name

# Add current user to group
$current_user_obj_id=(az ad signed-in-user show --query "id" -o tsv)
az ad group member add --group $group_name --member-id $current_user_obj_id

# Give user permissions to Arc enabled K8s permission
# Azure Arc Enabled Kubernetes Cluster User Role
# PORTAL

echo @"
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dev-user
  namespace: default
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
"@ > role-dev-namespace.yaml
kubectl apply -f role-dev-namespace.yaml

$group_obj_id=(az ad group show --group $group_name --query "id" -o tsv)

echo @"
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dev-user-access
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: dev-user
subjects:
- kind: Group
  namespace: default
  name: $($group_obj_id)
"@ > rolebinding-dev-namespace.yaml
kubectl apply -f rolebinding-dev-namespace.yaml

# Connect
az connectedk8s proxy -n $clusterName -g $resourceGroup 
