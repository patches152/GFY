#### Params ####

# ingress params
$Namespace          = '#{Namespace}'
$ReplicaCount       = '#{ReplicaCount}'
$LoadBalancerIP     = $OctopusParameters["Octopus.Action[Apply Terraform].Output.TerraformValueOutputs[ingress_ip]"]
$AzureDNSLabelName  = OctopusParameters["Octopus.Action[Apply Terraform].Output.TerraformValueOutputs[dns_name]"]
$kubeConfig         = "C:\BuildTools\kubeconfig\config"

#acr params
$DockerServer   = '#{DockerServer}'
$DockerUsername = "#{Dockerusername}"
$DockerPassword = '#{DockerPassword}'
$DockerEmail    = '#{DockerEmail}'

# cert manager params
$CertManagerVersion = '#{CertManagerVersion}'

# new relic params
$releaseName        = '#{releaseName}'
$namespace          = '#{namespace}'
$newrelicLicenseKey = '#{newrelicLicenseKey}'
$clusterName        = '#{clusterName}'


#### Azure Setup ####

# log into azure
az login --service-principal --username #{ServicePrincipal_ID} --password #{ServicePrincipalKey} --tenant #{AzureTenantID}
az account set --subscription "default"

# set k8s local config to use remote aks as cluster
az aks get-credentials --resource-group $OctopusParameters["Octopus.Action[Apply Terraform].Output.TerraformValueOutputs[resource_group_name]"] --name $OctopusParameters["Octopus.Action[Apply Terraform].Output.TerraformValueOutputs[aks_cluster_name]"] --file C:\BuildTools\kubeconfig\config --overwrite-existing


#### Ingress Controller Setup ####

# Create a namespace for ingress controller
& kubectl apply --filename ./nginxNamespace.yaml --kubeconfig $kubeConfig

# Add the ingress-nginx repository
& helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --kubeconfig $kubeConfig
& helm repo update --kubeconfig $kubeConfig

# Need to set the nodeSelectors to use only linux in a Windows cluster
# Provide this command with the value of Static IP created earlier
& helm install nginx-ingress ingress-nginx/ingress-nginx --namespace $Namespace --set controller.replicaCount=$ReplicaCount --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux --set controller.service.loadBalancerIP=$LoadBalancerIP --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$AzureDNSLabelName  --kubeconfig $kubeConfig


#### Azure Container Registry Setup ####

# Create cluster secret for pulling from Azure Container Registry

& kubectl create secret docker-registry dockersecret --docker-server $DockerServer --docker-username=$DockerUsername --docker-password p$DockerPassword --docker-email $DockerEmail --kubeconfig $kubeConfig


#### Certificate Manager Setup ####

# Create Namespace for Certificate Manager
& kubectl apply --filename ./certManagerNamespace.yaml --kubeconfig $kubeConfig

# Label the ingress-basic namespace to disable resource validation
& kubectl label namespace cert-manager cert-manager.io/disable-validation=true --kubeconfig $kubeConfig

# Add the Jetstack Helm repository
& helm repo add jetstack https://charts.jetstack.io --kubeconfig $kubeConfig

# Update the local Helm chart repository cache
& helm repo update --kubeconfig $kubeConfig

# Cert manager manifest for Kubernetes 1.16+
& kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/$CertManagerVersion/cert-manager.yaml --kubeconfig $kubeConfig
# Wait for cert-manager resources to be created to connect the cluster wide issuer
Start-Sleep -Seconds 30

# Create the Cluster Wide Issuer via .yaml
& kubectl apply --filename ./cluster-issuer.yaml --namespace cert-manager --kubeconfig $kubeConfig


#### New Relic Setup ####

# Install New Relic via helm 
helm upgrade --install $releaseName newrelic/nri-bundle -f ./newrelic.yaml --set global.licenseKey=$newrelicLicenseKey --set global.cluster=$clusterName --namespace=$namespace --set infrastructure.enabled=true --set prometheus.enabled=true --set webhook.enabled=true --set ksm.enabled=true --set kubeEvents.enabled=true --set logging.enabled=true
