- 驗證 Meraki Webhook 可以送到 AWS Lambda / API Gateway，並轉換為 Prometheus 相容的 metrics 或推到後端 queue。
- 使用最小的監控堆疊（Prometheus + Grafana docker-compose）來觀察 metrics。

PoC 目標

- 驗證 Meraki Webhook 可以送到 (a) 本地 Lambda 模擬 handler 或 (b) 部署於 AWS 的 Lambda / API Gateway，然後轉換為 Prometheus 相容的 metrics 或推到後端 queue。
- 使用最小的監控堆疊（Prometheus + Grafana docker-compose）來觀察 metrics。

重要：預設情況下本範例不會連上 AWS，也不會將任何密鑰或憑證寫入程式碼。
所有可變參數（如 Meraki API endpoint / key、Prometheus Pushgateway URL）均以環境變數表示，請查看 `.env.example`。
- 驗證 Meraki Webhook 可以送到 AWS Lambda / API Gateway，並轉換為 Prometheus 相容的 metrics 或推到後端 queue。
- 使用最小的監控堆疊（Prometheus + Grafana docker-compose）來觀察 metrics。

內容

- `meraki_webhook_lambda.py`：Lambda 範例 handler（使用環境變數表示外部 API 與金鑰，若未設定則不會發出外部請求）
- `docker-compose.yml`：本機起 Prometheus + Grafana（PoC 用）

執行步驟（本地測試）

1. 本地啟動 Prometheus + Grafana：

   docker compose -f poc/docker-compose.yml up -d

2. 使用 ngrok 或類似工具將本地端/HTTP endpoint 暴露到外網以便 Meraki webhook 測試，或在 AWS 部署 API Gateway -> Lambda（若要部署到 AWS，請自行在具有 AWS 憑證的環境執行部署步驟；本 repo 預設不會主動連上 AWS）。

3. 在 Meraki Dashboard 建立 webhook 指向 PoC endpoint，發送測試事件。

4. 檢查 Prometheus / Grafana 是否收到或顯示測試資料。


Prometheus PoC: see `poc/prometheus-grafana-pocs.md`.
