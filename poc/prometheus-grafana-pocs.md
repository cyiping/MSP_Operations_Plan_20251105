Prometheus + Grafana PoCs (cloud vs edge)

概要

這份文件比較兩個 PoC（雲端與地端）在設計、部署與限制上的不同，並提出下一步建議。

1) 共同目標
- 快速在 Kubernetes 上部署 Prometheus + Grafana，用以收集與視覺化叢集與節點指標。
- 提供簡單 alert 規則與一個示範 Grafana dashboard。

2) 雲端 POC（目錄：`poc/prometheus-cloud/`）
- 優點：可直接使用雲端提供的 LoadBalancer 與 storage class，部署簡單。
- 建議：使用 `values-cloud.yaml`，Grafana 設為 LoadBalancer，Prometheus 使用 PVC（例如 20Gi）。
- 適合：短期測試、demo、開發環境或雲端 production（仍需調整 retention 與 HA）。

3) 地端 / Edge POC（目錄：`poc/prometheus-edge/`）
- 優點：可以在無外部 LB 的環境運作，利用 NodePort 或 port-forward 存取 Grafana。
- 風險：hostPath 僅供 PoC，不可作 production。建議使用 local PV provisioner（local-path-provisioner）或 NAS/NFS。
- 建議：若需在 edge 保留原始資料或做跨叢集查詢，考慮使用 remote_write 將資料送到 central long-term store（例如 Thanos、Cortex、Mimir）。

4) 共通建議與後續工作
- 長期儲存：使用 Thanos 或 Cortex / Mimir 來做物件存儲後端與跨叢集查詢。
- HA：對於 production，要配置 Prometheus HA（或使用 Thanos Store/Query 來提供高可用性）。
- 備援與安全：設定 Grafana 的 OAuth 或外部 Auth、Alertmanager 的通知（Slack/Email/PagerDuty）與 secret 管理（如 SealedSecrets / HashiCorp Vault）。

5) 如何驗證
- 檢查 pods 與 svc：
  kubectl -n monitoring get pods,svc
- 檢查 Prometheus targets：
  打開 Grafana → Prometheus datasource → 查看 targets，或 `kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090` 並訪問 http://localhost:9090/targets
- 測試 alert：
  人為 stop 某個 node-exporter 或模擬 job，使 `up == 0`，並觀察 Prometheus rules 與 Alertmanager。
