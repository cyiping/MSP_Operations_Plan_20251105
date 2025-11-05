# Onboarding 檢查清單（Onboarding Checklist）

目的：確保客戶啟用流程完整且可追溯，降低初期失誤與後續問題。

步驟：

1. 合約與帳務
   - 確認合約、計價模型與試算表
   - 建立 Customer record（tenant id、billing contact、稅務資料）
   - 建立訂閱（Subscription）並標記試算期

2. 資訊收集
   - 客戶網路拓樸圖、主要聯絡人、IP 範圍
   - 提供 Meraki Dashboard 權限或請客戶建立 API Key（授予最小權限）

3. 設備與組態
   - 確認設備 serial / 型號 / 固件版本
   - 將設備加入 Meraki 組織與 Network（或提供 L3 引導文件）
   - 部署初始 SSID、VLAN、ACL 等最小配置

4. 監控與告警
   - 在監控系統新增 target（Meraki webhook / exporter）
   - 設定初始告警門檻與通知路徑（PagerDuty、Email、Slack）

5. 帳務與發票
   - 確認計費週期、付款方式、稅務設定
   - 建立發票樣板與測試發送

6. 測試與驗收
   - 測試事件流：Meraki webhook -> API Gateway/Lambda -> metrics/logs
   - 測試發票產生流程
   - 與客戶確認服務項目與聯絡窗口

7. 上線
   - 排程正式上線時間、變更通告
   - 完成上線紀錄並關閉 Onboarding ticket
