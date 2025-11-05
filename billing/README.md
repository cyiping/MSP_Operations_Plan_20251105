簡介

這是一個簡易的本地帳務 microservice PoC，使用 Flask + SQLite，提供基本的多租戶資料模型、使用量上報與發票產生（JSON 存檔），適合在本地或 CI 做功能驗證。

設計要點
- 不連外部支付或 AWS：所有外部點位（如付款 gateway、S3）以環境變數表示；預設情況下會把發票寫到本地 `billing/invoices/`。
- 可擴充：未來可替換為真實 Payment Provider、PDF 生成或上傳 S3（透過環境變數/Secrets 管理）。

快速上手

1. 建立虛擬環境並安裝依賴：

   python3 -m venv .venv
   . .venv/bin/activate
   pip install -r billing/requirements.txt

2. 啟動服務：

   FLASK_APP=billing/app.py FLASK_ENV=development flask run

3. 範例 API：

- POST /customers -> 建立客戶
- POST /subscriptions -> 建立訂閱
- POST /usage -> 上傳使用量
- POST /invoices/generate -> 產生發票（將 JSON 寫入 billing/invoices/）

注意：此服務僅為 PoC 範例，生產務請加上認證、權限、輸入驗證與稽核日誌。
