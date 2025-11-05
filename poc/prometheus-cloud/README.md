Prometheus + Grafana PoC — Cloud Kubernetes

目標

- 在雲端 Kubernetes（例如 EKS/GKE/AKS）驗證 Prometheus 與 Grafana 的部署與基本監控流程。
- 使用 Helm 安裝 `kube-prometheus-stack`，並示範如何啟用持久化儲存、LoadBalancer 型 Grafana 與基本 alert。

設計重點

- Grafana service: LoadBalancer（雲端 LB 可直接取得外部 IP）。
- Prometheus、Alertmanager 使用預設 storageClass（雲端提供的 storage class）。
- 預先加入一個簡單的 alert rule（instance down）。
- 示例值放在 `values-cloud.yaml`。

部署步驟（假設已安裝 Helm 並且 kubeconfig 指向雲端 cluster）

1. 新增 Helm 倉庫並更新：

   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update

2. 建立 monitoring namespace：

   kubectl create namespace monitoring

3. 安裝（使用本目錄的 values）：

   helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring -f values-cloud.yaml

4. 驗證：

   kubectl -n monitoring get pods
   kubectl -n monitoring get svc grafana

   等待 Grafana service 顯示 EXTERNAL-IP，然後使用瀏覽器存取（或使用 `kubectl port-forward`）。

Grafana 預設帳密（kube-prometheus-stack）：
- 用 `kubectl get secret prometheus-grafana -n monitoring -o jsonpath=\"{.data.admin-password}\" | base64 --decode` 取得密碼，使用帳號 `admin` 登入。

注意事項與建議

- 在 production 或長期測試請換用正式的 PV（不是 ephemeral）並妥善設定 retention 與監控的資源限制。
- 若需跨叢集長期儲存，考慮使用 Thanos / Cortex / Mimir 或遠端 write。

部署自動化（Terraform / GitOps）

1) Terraform（Helm provider）

   - 我們在 `iac/terraform/helm_prometheus_example.tf` 提供一個簡單範例，示範如何透過 Terraform 的 `helm_release` 將 `kube-prometheus-stack` 安裝到 `monitoring` namespace。範例會讀取 `poc/prometheus-cloud/values-cloud.yaml` 作為 chart values。

   - 使用方式（本地測試）：

```bash
cd iac/terraform
terraform init
terraform apply -var="kubeconfig_path=$KUBECONFIG" -auto-approve
```

   - 注意：不要把密碼或敏感資訊寫進 repo；使用 Vault / SOPS / Terraform Cloud 等方式注入 secrets。

2) GitOps（ArgoCD）

   - 若採用 GitOps，建議把 HelmRelease（或 Helm chart 的 values 與 Application manifest）放到 Git repo，讓 ArgoCD 同步與管理 release lifecycle。
   - 優點：更容易回滾、審查與綁定分支/環境；缺點：需先做好 secrets 管理（SOPS / SealedSecrets / External Secrets Controller）。
