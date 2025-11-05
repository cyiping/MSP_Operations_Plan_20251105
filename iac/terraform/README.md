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
