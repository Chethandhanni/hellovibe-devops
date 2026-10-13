
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

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Deploy the HelloVibe API to Dev
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

# Deploy the HelloVibe API to Production
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

  depends_on = [
    helm_release.dev
  ]
}

# Deploy Prometheus, Grafana and Alertmanager
resource "helm_release" "monitoring" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = kubernetes_namespace_v1.monitoring.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      grafana = {
        enabled = true
      }

      alertmanager = {
        enabled = true
      }

      prometheus = {
        prometheusSpec = {
          retention = "7d"

          # Allow custom PrometheusRule resources to be discovered.
          ruleSelectorNilUsesHelmValues          = false
          ruleNamespaceSelectorNilUsesHelmValues = false
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]
}

# Alert when fewer than two production replicas are available
resource "kubernetes_manifest" "hellovibe_alert" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"

    metadata = {
      name      = "hellovibe-alerts"
      namespace = "monitoring"

      labels = {
        release = "kube-prometheus-stack"
      }
    }

    spec = {
      groups = [
        {
          name = "hellovibe.production"

          rules = [
            {
              alert = "HelloVibeProductionReplicasLow"

              expr = "kube_deployment_status_replicas_available{namespace=\"prod\",deployment=\"hellovibe-api\"} < 2"

              for = "1m"

              labels = {
                severity = "critical"
              }

              annotations = {
                summary     = "HelloVibe production replicas are below 2"
                description = "Production has fewer than two available replicas."
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    helm_release.monitoring,
    helm_release.prod
  ]
}