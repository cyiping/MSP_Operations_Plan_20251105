/*
  helm_prometheus_example.tf

  範例：使用 Terraform 的 Helm provider 將 kube-prometheus-stack 部署到已存在的 Kubernetes 叢集。

  注意：這只是範例模版，實際使用時請調整 provider 的設定、kubeconfig 路徑、values 與 secrets 的管理方式（不要把密碼寫進 repo）。

  參考步驟：
  1) 確保你能用 kubectl 存取目標叢集 (kubeconfig)
  2) 在含有 Terraform 的工作目錄執行 `terraform init`、`terraform plan`、`terraform apply`

  你可以把此檔放在 iac/terraform/ 並以 `terraform apply` 套用（需先設定 provider、kubeconfig、或在 CI 中注入憑證）
*/

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "prom_values_file" {
  description = "Optional values.yaml path to customize the chart"
  type        = string
  default     = "../poc/prometheus-cloud/values-cloud.yaml"
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # 指定 values 檔案（可用 local file 或直接在 values 塊中覆寫）
  values = [file(var.prom_values_file)]

  # 註：在生產環境請使用更嚴謹的版本鎖定與 values 管理；若使用敏感參數，請透過 Vault / SOPS 或 Terraform Cloud variables 注入
  timeout = 600
}
