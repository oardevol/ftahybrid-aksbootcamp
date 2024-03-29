# Variables used in this script, defined in ../env.ps1
# $clusterName

# Enable monitoring (Prometheus) to an existing cluster
Install-AksHciMonitoring -Name $clusterName -storageSizeGB 100 -retentionTimeHours 240

# Deploy grafana
kubectl apply -f https://raw.githubusercontent.com/microsoft/AKS-HCI-Apps/main/Monitoring/data-source.yaml
kubectl apply -f https://raw.githubusercontent.com/microsoft/AKS-HCI-Apps/main/Monitoring/dashboards.yaml
kubectl apply -f https://raw.githubusercontent.com/microsoft/AKS-HCI-Apps/main/Monitoring/dashboards-new.yaml
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana --version 6.11.0 --set nodeSelector."kubernetes\.io/os"=linux --set sidecar.dashboards.enabled=true --set sidecar.datasources.enabled=true -n monitoring

# Connect to grafana
$secret=kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}"
$secret=[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($secret))
$podName=kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}"
kubectl --namespace monitoring port-forward $podName 3000

# connect to http://localhost:3000 
# user admin, password $secret

