# Runbook：VPN 掉線（VPN Tunnel Down）

目標：快速恢復站對站或遠端存取的 VPN 隧道，並在必要時切換備援路徑。

等級：Critical（影響跨-site 通訊或主業務系統）

步驟：

1. 收集資訊
   - 取得隧道名稱、兩端設備 serial/IP、告警時間

2. 檢查隧道狀態
   - Meraki Dashboard 查詢 VPN 狀態（或使用 API）
   - 檢查對端是否有對等告警

3. 基礎網路檢查
   - 檢查兩端 WAN 是否可達（ping, traceroute）
   - 檢查 NAT/防火牆是否阻擋 IPSec 流量（UDP 500/4500, ESP）

4. 嘗試重建
   - 在 Meraki 執行隧道重新協商/重啟
   - 若使用第三方設備，依 Runbook 重啟 IPsec 進程或套用設定

5. 切換備援
   - 若有 SD-WAN 或備援路由，啟用備援路徑並通知流量切換

6. 建立 ticket 與回報
   - 紀錄所有嘗試與結果並更新 ticket

後續
   - 若頻繁掉線，啟動深度網路診斷（抓封包、頻寬分析）
