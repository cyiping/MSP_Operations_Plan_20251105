# MSP 營運平台 API 文件

## 概述

本文件說明 MSP 營運平台的 API 介面，包含：
1. Webhook 接收與處理
2. 帳務系統 API
3. 監控指標 API

## API 端點

### 1. Webhook API

```http
POST /webhook
Content-Type: application/json
X-Meraki-Signature: {signature}

{
  "sentAt": "2025-11-05T10:00:00Z",
  "organizationId": "123456",
  "deviceSerial": "Q2XX-XXXX-XXXX",
  "deviceName": "Branch-SW01",
  "eventType": "device.down"
}
```

### 2. 帳務 API

#### 2.1 建立客戶

```http
POST /customers
Content-Type: application/json

{
  "name": "客戶公司",
  "billingContact": "billing@example.com",
  "billingCycle": "monthly"
}
```

#### 2.2 建立訂閱

```http
POST /subscriptions
Content-Type: application/json

{
  "customerId": "cust_123",
  "sku": "MX-L",
  "quantity": 2,
  "unitPrice": 100.00
}
```

### 3. 監控 API

#### 3.1 裝置狀態

```http
GET /devices/{serial}/status
Authorization: Bearer {token}
```

#### 3.2 推送指標

```http
POST /metrics
Content-Type: application/json

{
  "deviceSerial": "Q2XX-XXXX-XXXX",
  "metric": "uptime",
  "value": 99.99,
  "timestamp": "2025-11-05T10:00:00Z"
}
```

## 認證與安全性

1. Webhook 驗證：使用 HMAC 簽章
2. API 認證：JWT Bearer Token
3. 限流：每 IP 每分鐘 100 請求

## 錯誤處理

所有 API 使用標準 HTTP 狀態碼：
- 200: 成功
- 400: 請求格式錯誤
- 401: 未認證
- 403: 權限不足
- 404: 資源不存在
- 429: 超過限流
- 500: 服務器錯誤

## 環境變數

```bash
# API 服務配置
API_PORT=5000
API_DEBUG=false
JWT_SECRET=xxx

# 外部服務
MERAKI_API_KEY=xxx
PROMETHEUS_URL=http://localhost:9090
```

## 開發與測試

1. 本地運行：
```bash
make api-up
```

2. API 測試：
```bash
make api-test
```

## 注意事項

1. 所有時間使用 UTC
2. 金額使用 decimal(10,2)
3. 需實作 idempotency
4. 關鍵操作需留存審計日誌