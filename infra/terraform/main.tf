terraform {
  cloud {
    organization = "showoff"
    workspaces {
      name = "pet-clinic"
    }
  }

  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.11.0"
    }
  }
}

provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::${var.deploy_account}:role/TerraformAssumeRole"
  }
  default_tags {
    tags = {
      IaC = "Terraform"
    }
  }
}

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

provider "kubernetes" {
  host                   = var.kubernetes_host
  client_certificate     = base64decode(var.client_certificate)
  client_key             = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

provider "argocd" {
  server_addr = var.argocd_url
  auth_token  = var.argocd_token
}


resource "argocd_repository" "repository" {
  repo     = "https://github.com/captain-klein/spring-petclinic-microservices.git"
  username = "git"
  password = var.github_pat
  name     = "pet-clinic"
  type     = "git"
}

resource "aws_ecr_repository" "petclinic" {
  for_each = toset(local.repositories)

  name                 = each.key
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = "pet-clinic"
  }
}

output "repository_urls" {
  value = {
    for name, repo in aws_ecr_repository.petclinic :
    name => repo.repository_url
  }
}
