# Runbook：設備離線（Device Offline）

目標：快速判定是否為暫時性斷線、網路造成或設備故障，並在 SLA 內回應與緩解。

等級：Major / Critical（依客戶等級而定）

步驟：

1. 取得告警內容
   - 檢查告警時間、最後心跳時間、設備 ID、客戶 tenant id

2. 檢查 Meraki Dashboard
   - 使用 Meraki API 查詢設備狀態：GET /devices/{serial}
   - 確認設備是否顯示離線與最後聯繫時間

3. 網路基礎檢查
   - 檢查客戶 WAN 是否有 upstream outage（透過 provider 提供或 X-tooltips）
   - 若可以遠端連線到 edge router，嘗試 ping 設備管理 IP

4. 嘗試遠端復原
   - 如果 Meraki 支援遠端重啟（API），執行 remote reboot
   - 若無法，通知現場或派工（依合約）

5. 建立 Ticket 與通知
   - 自動在 Service Desk 建立 ticket，填入檢查紀錄
   - 若 Critical，立即通知 on-call（PagerDuty / SMS）

6. 後續分析
   - 若為硬體問題，記錄 serial 與狀況；啟動 RMA 流程
   - 完成後更新 ticket 並通知客戶

檢查清單（回報）
- 告警時間、設備 serial、最後心跳時間
- 是否嘗試遠端重啟、結果為何
- 是否派工/現場處理、RMA 狀態
