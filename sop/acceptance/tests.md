# 驗收測試清單（Acceptance Tests）

目標：驗證 PoC / 生產環境的核心行為符合預期，並作為交付驗收依據。

測試項目：

1. Meraki Webhook 流程
   - 測試：由 Meraki Dashboard 發送 sample webhook 到 PoC endpoint
   - 驗收：Lambda / local server 能正確解析事件並回傳 200；事件寫入 log 或 queue

2. 監控可觀察性
   - 測試：Prometheus 能抓到示範 metric（或 pushgateway 接收到事件後可見）
   - 驗收：Grafana 顯示基本儀表板（設備數、離線數、VPN 狀態）

3. 告警與通知
   - 測試：模擬阈值超過（例如 5 個設備同時離線）並產生警示
   - 驗收：Alertmanager -> SNS -> PagerDuty/Email 正確送達，並產生 ticket

4. 帳務生成流程
   - 測試：產生一筆使用量資料並執行計價引擎，產生發票草稿與 PDF
   - 驗收：Invoice record 建立、PDF 存至 S3 並 Email 發送成功（或確認 Signed URL 可取回）

5. 故障演練
   - 測試：模擬 WAN 全斷（某 site）或大量設備離線情境
   - 驗收：系統能在 SLA 時限內回報告警、啟動 Runbook 並完成初步緩解步驟

資料保留與稽核：
- 驗收測試結果需存檔並附 log、screenshots、以及 ticket 連結，供交付驗收用。 
