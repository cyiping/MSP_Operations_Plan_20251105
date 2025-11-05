Prometheus + Grafana PoC — Edge / On-Prem Kubernetes

目標

- 在地端 Kubernetes（無 cloud LB 的環境）部署 Prometheus 與 Grafana，驗證 NodePort 或 port-forward、local PV/hostPath 儲存與資源限制。
- 示範如何在 edge node 上以 DaemonSet（node-exporter）收集節點指標，以及如何用 NodePort 存取 Grafana。

設計重點

- Grafana service: NodePort（或使用 ingress / metallb 若可用）。
- PV: 範例使用 hostPath（僅用於 PoC / demo），長期請改成 local PV provider 或 NFS/Ceph 等正式方案。
- 指定 nodeSelector/ tolerations 讓 Prometheus 只跑在指定 edge 節點（示例可選）。

部署步驟（假設 kubeconfig 指向地端 cluster）

1. 建立 namespace：

   kubectl create namespace monitoring

2. 安裝 Helm chart（使用本目錄的 values）：

   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring -f values-edge.yaml

3. 驗證：

   kubectl -n monitoring get pods
   kubectl -n monitoring get svc grafana

   如果使用 NodePort，可透過任一叢集節點 IP 與 NodePort 訪問 Grafana。或使用 port-forward：

   kubectl -n monitoring port-forward svc/grafana 3000:80

注意事項

- hostPath 只適合短期 PoC，若叢集中有 local-volume provisioner（例如 local-path-provisioner），請優先用該方案。
- 若要把地端 metrics 匯聚到雲端，可考慮在 edge 使用 remote_write 送到 cloud 的接收端（Thanos/RemoteWrite endpoint）。