
variable "image_tag" {
  description = "Immutable container image tag to deploy"
  type        = string
  default     = "dev"
}

resource "kubernetes_namespace_v1" "dev" {
  metadata {
    name = "dev"
  }
}

resource "kubernetes_namespace_v1" "prod" {
  metadata {
    name = "prod"
  }
}

resource "helm_release" "dev" {
  name      = "hellovibe-api"
  chart     = "${path.module}/../../k8s/chart"
  namespace = kubernetes_namespace_v1.dev.metadata[0].name

  values = [
    file("${path.module}/../../k8s/environments/dev/values.yaml")
  ]

  set {
    name  = "image.tag"
    value = var.image_tag
  }
}

resource "helm_release" "prod" {
  name      = "hellovibe-api"
  chart     = "${path.module}/../../k8s/chart"
  namespace = kubernetes_namespace_v1.prod.metadata[0].name

  values = [
    file("${path.module}/../../k8s/environments/prod/values.yaml")
  ]

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  depends_on = [helm_release.dev]
}