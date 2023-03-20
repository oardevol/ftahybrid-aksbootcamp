# Variables used in this script, defined in ../env.ps1
# $subscriptionId, $tenantId, $resourceGroup

# We will spin up a new cluster
$rbacClusterName="wld02-cluster"

# Install az cli
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

# Sign in to Azure
Connect-AzAccount -Tenant $tenantId
Set-AzContext -Subscription $subscriptionId

az login --tenant $tenantId
az account set --subscription $subscriptionId

# Create server app
$SERVER_APP_ID=az ad app create --display-name "${rbacClusterName}Server" --identifier-uris "api://${tenantId}/${rbacClusterName}" --query appId -o tsv
Set-Content -Path "oauth2-permissions.json" -Value "{ `
    ""oauth2PermissionScopes"": [ `
        { `
            ""adminConsentDescription"": ""Sign in and read user profile"", `
            ""adminConsentDisplayName"": ""Sign in and read user profile"", `
            ""id"": ""${SERVER_APP_ID}"", `
            ""isEnabled"": true, `
            ""type"": ""User"", `
            ""userConsentDescription"": ""Sign in and read user profile"", `
            ""userConsentDisplayName"": ""Sign in and read user profile"", `
            ""value"": ""User.Read"" `
        } `
    ] `
    }"
az ad app update --id "${SERVER_APP_ID}" --set groupMembershipClaims=All
az ad app update --id ${SERVER_APP_ID} --set  api=@oauth2-permissions.json
az ad app update --id ${SERVER_APP_ID} --set  signInAudience=AzureADMyOrg
$SERVER_OBJECT_ID=az ad app show --id "${SERVER_APP_ID}" --query "id" -o tsv
az rest --method PATCH --headers "Content-Type=application/json" --uri https://graph.microsoft.com/v1.0/applications/${SERVER_OBJECT_ID}/ --body '{"api":{"requestedAccessTokenVersion": 1}}'

# Create Service Principal and grant permissions for server app
az ad sp create --id "${SERVER_APP_ID}"
$SERVER_APP_SECRET=az ad sp credential reset --id "${SERVER_APP_ID}"  --query password -o tsv 
az ad app permission add --id "${SERVER_APP_ID}" --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope
az ad app permission grant --id "${SERVER_APP_ID}" --api 00000003-0000-0000-c000-000000000000 --scope User.Read

# Create client app and service principal
$CLIENT_APP_ID=az ad app create --display-name "${rbacClusterName}Client" --is-fallback-public-client --public-client-redirect-uris "api://${tenantId}/${rbacClusterName}client" --query appId -o tsv
az ad sp create --id "${CLIENT_APP_ID}"
$oAuthPermissionId=az ad app show --id "${SERVER_APP_ID}" --query "api.oauth2PermissionScopes[0].id" -o tsv
az ad app permission add --id "${CLIENT_APP_ID}" --api "${SERVER_APP_ID}" --api-permissions ${oAuthPermissionId}=Scope
$RESOURCE_APP_ID=az ad app show --id "${CLIENT_APP_ID}"  --query "requiredResourceAccess[0].resourceAppId" -o tsv
az ad app permission grant --id "${CLIENT_APP_ID}" --api "${RESOURCE_APP_ID}" --scope User.Read
az ad app update --id ${CLIENT_APP_ID} --set  signInAudience=AzureADMyOrg
$CLIENT_OBJECT_ID=az ad app show --id "${CLIENT_APP_ID}" --query "id" -o tsv
az rest --method PATCH --headers "Content-Type=application/json" --uri https://graph.microsoft.com/v1.0/applications/${CLIENT_OBJECT_ID}/ --body '{"api":{"requestedAccessTokenVersion": 1}}'

Set-Content -Path "accessCheck.json" -Value "{ `
    ""Name"": ""Custom Read authorization"",
    ""IsCustom"": true,
    ""Description"": ""Read authorization"",
    ""Actions"": [""Microsoft.Authorization/*/read""],
    ""NotActions"": [],
    ""DataActions"": [],
    ""NotDataActions"": [],
    ""AssignableScopes"": [
      ""/subscriptions/${subscriptionId}""
      ]
    }"
$ROLE_ID=az role definition create --role-definition ./accessCheck.json --query id -o tsv
az role assignment create --role "${ROLE_ID}" --assignee "${SERVER_APP_ID}" --scope /subscriptions/${subscriptionId}

# Create cluster
$sp=az ad sp create-for-rbac --role "Kubernetes Cluster - Azure Arc Onboarding" --scopes /subscriptions/${subscriptionId} | ConvertFrom-Json
$PWord = ConvertTo-SecureString -String $sp.password -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sp.appId, $PWord

New-AksHciCluster -name $rbacClusterName -enableAzureRBAC -resourceGroup $resourceGroup `
    -credential $Credential -subscriptionID $subscriptionId -tenantId $tenantId `
    -nodePoolName linuxnodepoolwld02 -controlPlaneNodeCount 1 -nodeCount 1 -osType linux  `
    -appId $SERVER_APP_ID -appSecret $SERVER_APP_SECRET -aadClientId $CLIENT_APP_ID

