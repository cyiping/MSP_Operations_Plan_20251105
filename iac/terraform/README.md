簡介


此目錄包含一組示範性的 Terraform 範本，用於快速建立 MSP PoC 所需的 AWS 基礎資源（VPC、EKS、RDS、S3 後端設定範例）。

重要：預設情況下此範例使用 local backend（參見 `backend.tf`），因此你可以在未配置 AWS 憑證的情況下查看與修改 TF 範本而不會自動連上 AWS。若要把狀態存放在 S3，請自行編輯 `backend.tf` 並提供已建立的 S3 bucket。

注意事項

- 這是骨架範例，真實上線前請調整資安設定、IAM 最小權限、Tag、以及資源大小。
- Terraform 狀態建議在團隊協作時使用 S3 後端並搭配 DynamoDB 鎖定；`backend.tf` 中有 S3 範例註解，啟用前請先建立 bucket。
- 若要在 AWS 部署：請在擁有正確權限的環境（本機或 CI）設定 AWS 憑證，並以 `terraform init`、`terraform plan`、`terraform apply` 執行。

安全提醒：

- repo 中的範例預設不包含任何實際憑證或密碼，敏感資訊請透過環境變數或 Secrets Manager / Vault 注入。
- `variables.tf` 提供 `deploy_to_aws` 與 `db_password` 等變數，預設 `deploy_to_aws = false`，以降低誤觸部署風險。

檔案列表

- provider.tf: AWS Provider
- backend.tf: S3 backend 範例（需提供 S3 bucket）
- variables.tf: 範例變數
- vpc.tf: VPC + Subnets + IGW
- eks.tf: EKS 範例（使用官方 module 建議）
- rds.tf: RDS 範例
- outputs.tf: 輸出

## Prometheus + Grafana PoC（與 IAC 的關聯）

若要在 infrastructure 層面部署 PoC 中的 Prometheus/Grafana，可參考 `poc/` 內的 values 檔與說明：

- `poc/prometheus-cloud/values-cloud.yaml`：示例 values，可整合至 Terraform 的 Helm release 模組（例如使用 Helm provider / helm_release）。
- `poc/prometheus-edge/values-edge.yaml`：示例 values（NodePort/hostPath），適用於 on-prem 或 edge 節點。

快速提示：在 Terraform 中可透過 `helm_release` 將 chart部署到 EKS，或先用 Terraform 建立 EKS 與 Storage（PV / StorageClass），再以 CI/CD（如 ArgoCD / Flux）套用 Helm release。

範例：使用 Terraform + Helm provider 部署 Prometheus（示例檔案）：

	- `iac/terraform/helm_prometheus_example.tf`：提供一個最小的 `helm_release` 範例，示範如何把 `kube-prometheus-stack` 部署到 `monitoring` namespace（請先確認 kubeconfig 與 provider 設定）。

使用建議：

- 開發/測試：可直接在本地執行 `terraform init && terraform apply`（需先設定 `kubeconfig`）。
- 團隊/生產：請把 Helm release 的 values 與敏感資訊（例如 Grafana admin 密碼）移到安全的 secrets 管理方案（Vault/ SOPS / Terraform Cloud secrets），並在 CI pipeline 中以環境變數注入。

GitOps (ArgoCD) 建議：

- 若偏好 GitOps 流程，可以把 HelmRelease 或 kustomize manifests 放在 Git repo，並讓 ArgoCD 同步到叢集。PoC 建議流程：先用 `iac/terraform/helm_prometheus_example.tf` 建立基礎 infra（EKS、StorageClass），再用 ArgoCD 去管理 Chart 的 lifecycle（HelmRelease CRD / Application）。

