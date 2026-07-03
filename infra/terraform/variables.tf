locals {
  repositories = [
    "spring-petclinic-admin-server",
    "spring-petclinic-api-gateway",
    "spring-petclinic-config-server",
    "spring-petclinic-customers-service",
    "spring-petclinic-discovery-server",
    "spring-petclinic-genai-service",
    "spring-petclinic-vets-service",
    "spring-petclinic-visits-service",
  ]
}

variable "deploy_account" {
  type        = string
  description = "AWS account for deploy resources"
}

variable "kubernetes_host" {
  type        = string
  description = "The API server endpoint (host URL) of the target Kubernetes cluster."
}

variable "client_certificate" {
  type        = string
  description = "The PEM-encoded client certificate used to authenticate to the Kubernetes API server."
}

variable "client_key" {
  type        = string
  description = "The PEM-encoded private key corresponding to the client certificate for Kubernetes authentication."
}

variable "cluster_ca_certificate" {
  type        = string
  description = "The PEM-encoded CA certificate that verifies the Kubernetes API server's certificate."
}

variable "argocd_url" {
  type        = string
  description = "Base URL of the Argo CD instance (e.g., https://argocd.example.com)."
}

variable "argocd_token" {
  type        = string
  description = "API token used by Terraform to authenticate with the Argo CD instance."
  sensitive   = true
}

variable "github_pat" {
  type        = string
  description = "PAT Github token for get the repository"
  sensitive   = true
}

variable "vault_url" {
  type        = string
  description = "Base URL of the HashiCorp Vault instance to connect to (e.g., https://vault.example.com)."
}

variable "vault_token" {
  type        = string
  description = "Authentication token used by Terraform to access the Vault instance."
  sensitive   = true
}

variable "portainer_endpoint" {
  type        = string
  description = "Base URL of the Portainer instance where stacks or containers will be deployed (e.g., https://portainer.example.com)."
}

variable "portainer_api_key" {
  type        = string
  description = "API key used by Terraform to authenticate with the Portainer instance."
  sensitive   = true
}
