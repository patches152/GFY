output "ingress_ip" {
  value = azurerm_public_ip.ingressip.ip_address
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}