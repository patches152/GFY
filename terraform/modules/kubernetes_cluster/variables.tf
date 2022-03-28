variable "aks_name" {
    type = string
}

variable "azure_region" {
    type = string
}

variable "resource_group" {
    type = string
}

variable "subnet_id" {
    type = string
}

variable "worker_pool_name" {
    type = string
}

# Can set different VM size for prod vs non-prod
variable "worker_pool_vm_size" {
    type = string
}

# Can set different node pool count for prod vs non-prod
variable "worker_pool_node_count" {
    type = string
}

variable "ingressip_name" {
    type = string
}
