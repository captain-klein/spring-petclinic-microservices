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

resource "aws_ecr_lifecycle_policy" "petclinic" {
  for_each = aws_ecr_repository.petclinic

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = "pet-clinic"
  }
}

resource "vault_generic_secret" "pet_clinic" {
  path         = "workloads/pet_clinic"
  disable_read = true
  data_json = jsonencode(
    {
      "foo"   = "bar",
      "pizza" = "cheese"
    }
  )
  lifecycle {
    ignore_changes = [
      data_json,
    ]
  }
}

resource "argocd_application" "deploy" {
  metadata {
    name      = "pet-clinic"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/part-of" = "homelab-apps"
    }
  }

  spec {
    project = "lab-talos-workloads"

    destination {
      server    = "https://192.168.50.180:6443"
      namespace = kubernetes_namespace_v1.app.metadata[0].name
    }

    source {
      repo_url        = argocd_repository.repository.repo
      path            = "chart/petclinic"
      target_revision = "PET-02"
    }
  }
}

output "repository_urls" {
  value = {
    for name, repo in aws_ecr_repository.petclinic :
    name => repo.repository_url
  }
}

resource "kubernetes_manifest" "pet_clinic" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = kubernetes_namespace_v1.app.metadata[0].name
      namespace = kubernetes_namespace_v1.app.metadata[0].name
    }
    spec = {
      secretStoreRef = { name = "vault-dir-workloads", kind = "ClusterSecretStore" }
      target         = { name = "${kubernetes_namespace_v1.app.metadata[0].name}-env", creationPolicy = "Owner" }
      data = [
        {
          secretKey = "db-host"
          remoteRef = {
            key      = "workloads/data/pet_clinic"
            property = "MYSQL_HOST"
          }
        },
        {
          secretKey = "db-dbname"
          remoteRef = {
            key      = "workloads/data/pet_clinic"
            property = "MYSQL_DATABASE"
          }
        },
        {
          secretKey = "db-username"
          remoteRef = {
            key      = "workloads/data/pet_clinic"
            property = "MYSQL_USER"
          }
        },
        {
          secretKey = "db-password"
          remoteRef = {
            key      = "workloads/data/pet_clinic"
            property = "MYSQL_PASSWORD"
          }
        },
        {
          secretKey = "SPRING_PROFILES_ACTIVE"
          remoteRef = {
            key      = "workloads/data/pet_clinic"
            property = "SPRING_PROFILES_ACTIVE"
          }
        },
        {
          secretKey = "SPRING_DATASOURCE_URL"
          remoteRef = {
            key      = "workloads/data/pet_clinic"
            property = "SPRING_DATASOURCE_URL"
          }
        },
        {
          secretKey = "SPRING_DATASOURCE_USERNAME"
          remoteRef = {
            key      = "workloads/data/pet_clinic"
            property = "MYSQL_USER"
          }
        },
        {
          secretKey = "SPRING_DATASOURCE_PASSWORD"
          remoteRef = {
            key      = "workloads/data/pet_clinic"
            property = "MYSQL_PASSWORD"
          }
        },
      ]
    }
  }
}

///

data "vault_kv_secret_v2" "petc_clinic" {
  mount = "workloads"
  name  = "pet_clinic"
}

resource "portainer_stack" "db" {
  name                          = "casa-pet-clinic-db"
  deployment_type               = "standalone"
  method                        = "repository"
  endpoint_id                   = 3
  repository_url                = "https://github.com/captain-klein/spring-petclinic-microservices.git"
  repository_reference_name     = "refs/heads/PET-02"
  file_path_in_repository       = "docker/docker-compose-db.yaml"
  tlsskip_verify                = false
  pull_image                    = true
  git_repository_authentication = false

  env {
    name  = "MYSQL_ROOT_PASSWORD"
    value = data.vault_kv_secret_v2.petc_clinic.data["MYSQL_ROOT_PASSWORD"]
  }

  env {
    name  = "MYSQL_DATABASE"
    value = data.vault_kv_secret_v2.petc_clinic.data["MYSQL_DATABASE"]
  }

  env {
    name  = "MYSQL_USER"
    value = data.vault_kv_secret_v2.petc_clinic.data["MYSQL_USER"]
  }

  env {
    name  = "MYSQL_PASSWORD"
    value = data.vault_kv_secret_v2.petc_clinic.data["MYSQL_PASSWORD"]
  }
}
