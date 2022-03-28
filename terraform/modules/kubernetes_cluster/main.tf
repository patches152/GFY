resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.azure_region
  resource_group_name = var.resource_group
  dns_prefix          = var.aks_name
  kubernetes_version  = "1.19.11"

  default_node_pool {
    name           = "primarynodes"
    node_count     = 2
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = var.subnet_id
    max_pods       = 110
  }

  # Use SystemAssigned for managed user instead of Service Principal
  identity {
    type = "SystemAssigned"
  }

  #service_principal {
  #    client_id     = var.client_id
  #    client_secret = var.client_secret
  #}

  # When using kubenet the network profile is in its own zone avoiding overlaps
  network_profile {
    network_plugin     = "kubenet"
    load_balancer_sku  = "Standard"
    docker_bridge_cidr = "172.22.0.1/16"
    pod_cidr           = "172.21.0.0/16"
    service_cidr       = "172.20.0.0/16"
    dns_service_ip     = "172.20.0.10"
  }

  role_based_access_control {
      enabled = "true"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = var.worker_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.worker_pool_vm_size
  node_count            = var.worker_pool_node_count
  max_pods              = 110
  mode                  = "User"
  os_type               = "Linux"
  vnet_subnet_id        = var.subnet_id

  depends_on            = [azurerm_kubernetes_cluster.aks]
}

# IP Information for auto-created IP for the cluster
data "azurerm_public_ip" "outboundip" {
  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
}

# Create public ingress IP in the backend resource group
resource "azurerm_public_ip" "ingressip" {
  name                    = var.ingressip_name
  resource_group_name     = azurerm_kubernetes_cluster.aks.node_resource_group
  location                = var.azure_region
  allocation_method       = "Static"
  sku                     = "Standard"
  ip_version              = "IPv4"
  idle_timeout_in_minutes = 4
}
