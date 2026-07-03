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
    portainer = {
      source  = "portainer/portainer"
      version = "1.13.0"
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

provider "vault" {
  address = var.vault_url
  token   = var.vault_token
}

provider "portainer" {
  endpoint = var.portainer_endpoint
  api_key  = var.portainer_api_key
}
