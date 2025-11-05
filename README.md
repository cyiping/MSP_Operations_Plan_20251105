# MSP Operations Plan

> 專案代號：MSP_Operations_Plan_20251105  
> 版本：1.0  
> 更新日期：2025/11/05

本文檔為將 Cisco Meraki 類產品（以下簡稱 Meraki）用於 Managed Service Provider (MSP) 營運的高階與實作計畫，重點涵蓋服務監控、帳務管理、在 AWS 上的技術架構、安全與合規、SLA 與日常運維流程。

---

## 目標

- 提供可量測、可追蹤、可自動化的 Meraki-based MSP 營運流程。
- 建立集中監控、事件通知與自動化回應機制，降低 MTTR。
- 建置帳務系統支援多租戶計價（定額與用量混合）、發票與會計整合。
- 在 AWS 上使用可擴充、可觀察的基礎設施以支援長期營運。

## 範圍

- 支援的設備：Meraki MR(AP)、MX(SD-WAN/Firewall)、MS(Switch)、SM(裝置管理)
- 主要功能：佈建/拆除、監控/告警、帳務/計費、報表、更新管理、事件/問題處理
- 不包含：客戶內部專屬非 Meraki 設備深度支援（除非另行合約）

## 營運合約與服務（建議）

- 基本服務：設備監控、遠端故障排查、韌體維護建議、月度報表
- 進階服務：24x7 SLA、定期網路優化、配置變更管理、現場支援（選配）
- 帳務模式：月租制（設備/服務）+ 用量計費（超額流量、客戶數、VPN 通道數）+ 授權代收/代付

## AWS 技術架構建議

高階元件（最小可行技術）：

- VPC（多 AZ）: 公私子網分離，NAT、Bastion 主機（或 Session Manager）
- EKS / ECS：部署監控與帳務微服務（建議 EKS + Fargate 或自動擴縮的 ECS）
- RDS（Postgres）: 帳務/訂閱資料儲存（Multi-AZ, 自動備份）
- S3：長期日誌、報表、發票 PDF 儲存（設定 Lifecycle）
- CloudWatch + CloudTrail + Config：AWS 合規、稽核與指標
- Prometheus + Grafana（可在 EKS）：Meraki 與內部服務指標、客製化儀表板
- Alertmanager / SNS / PagerDuty：告警路由與班表整合
- API Gateway + Lambda：處理來自 Meraki Webhooks 的事件並觸發工作流程
- Secrets Manager / Parameter Store：保存 API Keys、DB 密碼

網路與安全：

- ALB / NLB（必要時）
- 子網與安全群組最小權限
- VPC Flow Logs（輸入至 S3 或 CloudWatch Logs）

備援與備份：RDS 自動備份、多區部署；S3 版本與 Lifecycle；重要快照定期保留

成本控制建議：使用 Savings Plans/Reserved Instances、S3 Lifecycle、EKS 节点自动扩缩与 Fargate

## 監控需求（Service Monitoring）

監控目標：可即時掌握設備/網路與服務健康狀態，並能自動化分級通報與回應。

監控項目（分類）：

- 設備生命週期與連線
  - 設備在線/離線狀態
  - 客戶連線數 (client count)、SSID 使用量
  - POE/Port 狀態、端口錯誤率
  - AP 與 Switch 的 Channel/Tx/Rx/Throughput

- 網路與服務層
  - WAN 連線品質（延遲、丟包、抖動）、BGP/動態路由狀態
  - VPN 隧道狀態與重連次數
  - NAT/Firewall 規則觸發數、拒絕流量

- 安全性
  - IPS/IDS 事件（若 Meraki 提供）
  - 非預期的大量流量/掃描行為
  - 帳戶/API Key 的可疑活動

- 營運服務
  - 監控服務（Prometheus 指標、Exporter 健康）
  - 帳務處理隊列長度、發票產生失敗率

指標與量測方式：

- MTTD（平均偵測時間）, MTTR（平均修復時間）
- 可用性：設備 UP-time、服務 SLA（99.9% etc.）
- 告警等級：Critical / Major / Minor / Info，並對應 Escalation Policy

告警規則與流：

1. Meraki Webhooks -> API Gateway -> Lambda -> 將事件寫入 Kafka/SQS 或直接推到 Prometheus Pushgateway / Metrics DB
2. Prometheus/Grafana 設定門檻警示 -> Alertmanager -> SNS/PagerDuty/Email/Slack
3. Critical 事件自動開立 Ticket（整合 ServiceNow / Jira Service Desk）並觸發指定 on-call

Runbook 範例（每個常見告警需對應 Runbook）：

- 設備離線：檢查最後心跳、檢查客戶端電源/網路、遠端重啟指令、通知現場
- VPN 掉線：檢查對端狀態、重新建立隧道、回報到客戶

資料保留：監控原始事件 90 天，聚合指標 2 年（可依合約與法規調整）

## 帳務管理需求（Billing & Accounting）

功能需求：

- 多租戶帳務模型（每個客戶一個 tenant id）
- 支援混合計費：固定月費 + 用量（流量、AP 數量、客戶數、支援級別等）
- 授權/軟體費用代收代付（pass-through）與代理價差管理
- 發票自動產生（PDF）、電子發票支援
- 支援多種支付方式（銀行轉帳、信用卡、 ACH / Stripe / Payment Gateway）
- 權限分級：帳單管理員、稽核觀看、會計整合角色
- 折扣、促銷、契約期與續約管理
- 記帳整合（如 QuickBooks、Xero）、稅務計算與地區稅率

資料模型（建議最小欄位）：

- Customer (id, name, billing_cycle, billing_contact)
- Subscription (id, customer_id, sku, quantity, unit_price, billing_model, start_date, end_date)
- UsageRecord (id, subscription_id, metric, value, period_start, period_end)
- Invoice (id, customer_id, amount, due_date, status, pdf_s3_key)

計費流程（高階）：

1. 每日/每小時收集使用量（Lambda / EKS job） -> 寫入 Usage DB
2. 月末/計費週期執行計價引擎，產生 Invoice 草稿
3. 審核 -> 發送（Email + 存 S3），並更新會計系統
4. 付款回呼處理、逾期追蹤、退款/調整

稽核與報表：

- 月度營收報表、客戶貢獻報表、授權成本報表
- 對帳機制：將發票與實際收款比對，建立調整流程

安全與合規：

- 敏感資訊（信用卡）不儲存在自建系統，使用 PCI-compliant Payment Processor（Stripe、Adyen）
- 發票與帳務憑證保留期限依地區法規（建議至少 7 年）

## 運維流程與 Runbooks

上線前檢查清單（Onboarding）:

1. 客戶資料與合約上傳
2. Meraki 組織與 Network 建立、API Key 配置
3. 基本監控指標、告警門檻設定
4. 帳務訂閱建立、試算發票與稅務檢查
5. 測試事件演練（告警與工單流）

日常運維（建議）:

- 每日：自動巡檢（設備心跳、關鍵服務指標）、發票/付款處理檢查
- 每週：安全補丁與韌體更新窗口管理、流量趨勢檢查
- 每月：帳務對帳、SLA 報表、備份驗證

事故回應（簡化流程）：

1. 偵測（監控） -> 2. 分級 -> 3. 建 Ticket -> 4. 初步緩解（自動化腳本） -> 5. 評估與修復 -> 6. Root Cause 分析 -> 7. 通報與記錄

## SLA 與 KPI

- 建議預設 SLA 層級：
  - Gold: 99.95% 可用性、1 小時回應、4 小時修復目標（視情況）
  - Silver: 99.9% 可用性、4 小時回應、24 小時修復目標
  - Bronze: 99.0% 可用性、工作日回應

關鍵 KPI：MTTD、MTTR、客戶滿意度（CSAT）、每租戶月營收、流失率

## 安全與合規

- 身分與存取管理（IAM 最小權限、MFA）
- API Key 管理（定期輪替、儲存在 Secrets Manager）
- 日誌與稽核（CloudTrail、Meraki Audit logs）
- 資料加密（傳輸 TLS, S3 與 RDS at-rest encryption）
- 隱私法規（依客戶所在地遵守 GDPR / CCPA 等）

## 人力與角色建議

- Site Reliability Engineer (1-2)：監控、事件回應、Runbook 維運
- Network Engineer (1)：Meraki 配置、網路診斷
- Billing/Finance (1)：發票與會計整合
- Support / NOC（視客戶量）：輪班 on-call

## 實作里程碑（建議）

1. 第 0 週：需求確認、合約與計價模型草案
2. 週 1-2：AWS 帳號與基礎 VPC、IAM、Secrets 布署
3. 週 3-4：監控堆疊（Prometheus/Grafana）、Webhook 處理管線、告警策略
4. 週 5-6：帳務微服務與 RDS 設計、發票產生樣板、支付整合測試
5. 週 7-8：測試上線、SLA 模擬測試、文件與 Runbook 完成

## 成本估算（高階）

- 初始：EKS / EC2 節點、RDS 初始、小量 S3 與 CloudWatch 成本
- 運行：EKS/Fargate 費用、RDS 顯著占比、付費監控/告警（PagerDuty/第三方）
- 建議在 PoC 階段先以低規格部署並觀察使用量再調整

## 驗收與測試

- 功能測試：Meraki Webhook -> Lambda 處理 -> Prometheus 可見
- 性能測試：在多租戶情況下測試收集尺度與 DB 負載
- 障礙演練：模擬設備大量離線、網路斷鏈，驗證告警與回復流程

## 下一步（短期優先項）

1. 訂定計價模型範本與試算表（供商務與法務確認）
2. 在 AWS 建立 PoC 帳號，部署最小監控管線並串接一個 Meraki 測試組織
3. 撰寫 Runbook 的第一版（前三個高頻事件）

## 附錄：整合要點

- Meraki Dashboard API：使用 API Key 或 OAuth 並限制權限與 IP
- Webhook 處理：確保重試機制與去重邏輯
- 發票檔（PDF）儲存在 S3，並使用 Signed URL 發送給客戶（過期連結）

---

驗收摘要：本 README.md 提供從高階策略到技術實作的端到端營運計畫草案，包含服務監控、帳務管理與 AWS 架構建議。下一步為 PoC 部署、計價模型確認與 Runbook 撰寫。

## 專案架構與快速導航

本專案提供完整的 MSP 營運架構與工具鏈，所有組件預設使用環境變數控制外部連線，可在本地完整測試。

### 快速開始指南

1. 監控堆疊（Prometheus + Grafana）：
```bash
# 在專案根目錄
make poc-up              # 啟動 Prometheus + Grafana + Pushgateway
open http://localhost:3000  # 訪問 Grafana（admin/admin）
```

2. Webhook 接收與測試：
```bash
make poc-server         # 啟動本地 webhook handler
# 在另一個 terminal：
make poc-test          # 發送測試 webhook
# 查看 server log 確認接收
```

3. 帳務服務（本地版）：
```bash
cd billing
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
FLASK_APP=app.py flask run

# 在另一個 terminal 測試 API：
# 建立客戶
curl -X POST http://localhost:5000/customers \
  -H "Content-Type: application/json" \
  -d '{"name":"測試公司","billing_contact":"billing@example.com"}'

# 建立訂閱
curl -X POST http://localhost:5000/subscriptions \
  -H "Content-Type: application/json" \
  -d '{"customer_id":1,"sku":"MX-L","quantity":2,"unit_price":100}'

# 產生發票
curl -X POST http://localhost:5000/invoices/generate \
  -H "Content-Type: application/json" \
  -d '{"billing_cycle":"2025-11"}'
```

### 專案目錄結構

```
MSP_Operations_Plan_20251105/
├── docs/                    # 📚 專案文件
│   ├── architecture/       # 系統架構圖與說明
│   └── api/               # API 文件
├── sop/                    # 📋 標準作業程序
│   ├── sop.md             # 主要 SOP（日常運維與事故處理）
│   ├── onboarding/        # 客戶上線相關文件
│   └── acceptance/        # 驗收測試清單與程序
├── runbooks/               # 📖 運維手冊
│   ├── device/            # 設備相關處理程序
│   ├── network/           # 網路問題處理指南
│   └── billing/           # 帳務異常處理流程
├── poc/                    # 🧪 概念驗證
│   ├── docker/            # Docker 配置文件
│   ├── webhook/           # Webhook 處理器
│   └── sam/               # AWS SAM 部署模板
├── billing/                # 💰 帳務系統
│   ├── api/               # Flask API 服務
│   ├── models/            # 資料模型
│   └── invoices/          # 發票範本與輸出
└── iac/                    # 🏗️ 基礎設施即程式碼
    ├── terraform/         # Terraform 模組與範本
    └── examples/          # 部署範例與變數配置
```

#### 1. 營運文件（`sop/`）
- [`sop/sop.md`](sop/sop.md) - 📋 主要 SOP（日常運維與事故處理）
- [`sop/onboarding/checklist.md`](sop/onboarding/checklist.md) - ✅ 客戶上線流程
- [`sop/acceptance/tests.md`](sop/acceptance/tests.md) - 🔍 驗收測試清單

#### 2. 運維手冊（`runbooks/`）
- [`runbooks/device/offline.md`](runbooks/device/offline.md) - 🔌 設備離線處理
- [`runbooks/network/vpn.md`](runbooks/network/vpn.md) - 🌐 VPN 中斷處理
- [`runbooks/billing/invoice.md`](runbooks/billing/invoice.md) - 📝 發票異常處理

#### 3. 程式碼與實作（`poc/`, `billing/`, `iac/`）
- [`poc/README.md`](poc/README.md) - 🧪 PoC 實作說明
  - Webhook handler + 監控堆疊
  - 本地測試環境配置
  - AWS 部署參考

- [`billing/README.md`](billing/README.md) - 💰 帳務服務
  - RESTful API 設計
  - 資料庫結構說明
  - 本地開發指南

- [`iac/terraform/README.md`](iac/terraform/README.md) - 🏗️ 基礎設施
  - AWS 資源配置
  - 安全性考量
  - CI/CD 整合建議

### 環境變數與外部連線

所有外部服務連線均使用環境變數控制：
- Meraki API：`MERAKI_API_URL`, `MERAKI_API_KEY`
- Prometheus：`PROMETHEUS_PUSHGATEWAY`
- 帳務相關：`BILLING_DB`, `INVOICE_DIR`

➡️ 複製對應目錄下的 `.env.example` 為 `.env` 並依需求配置。
⚠️ 預設不自動連接 AWS 或外部 API。

### 後續擴充建議

1. 監控報表：
   - 在 Grafana 建立設備健康度儀表板
   - 設定 AlertManager 規則與通知
   
2. 帳務功能：
   - 整合 PDF 發票生成
   - 串接實際支付系統
   
3. AWS 部署：
   - 使用 SAM 部署 Lambda
   - 設定 VPC endpoint 與安全組
   
詳細說明請查看各目錄下的 README。
