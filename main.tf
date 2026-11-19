terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "local_dev" {
  name           = "k8s"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    node {
      role = "worker"
    }
  }
}

# connect kubernetes provider to the kind cluster
provider "kubernetes" {
  host                   = kind_cluster.local_dev.endpoint
  client_certificate     = kind_cluster.local_dev.client_certificate
  client_key             = kind_cluster.local_dev.client_key
  cluster_ca_certificate = kind_cluster.local_dev.cluster_ca_certificate
}

# Connect the Helm provider to your new Kind cluster
provider "helm" {
  kubernetes {
    host                   = kind_cluster.local_dev.endpoint
    client_certificate     = kind_cluster.local_dev.client_certificate
    client_key             = kind_cluster.local_dev.client_key
    cluster_ca_certificate = kind_cluster.local_dev.cluster_ca_certificate
  }
}

# Install the Strimzi Operator
resource "helm_release" "strimzi" {
  name             = "strimzi-kafka-operator"
  repository       = "oci://quay.io/strimzi-helm"
  chart            = "strimzi-kafka-operator"
  namespace        = "kafka"
  create_namespace = true
  version          = "1.3.1"
  depends_on = [kind_cluster.local_dev]
}
