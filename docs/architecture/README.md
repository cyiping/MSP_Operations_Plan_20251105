# MSP 營運平台系統架構

## 概述

本文件說明 MSP 營運平台的系統架構設計，包含：
1. AWS 基礎設施
2. 監控系統
3. 帳務系統
4. 安全性設計

## 架構圖

```
[客戶環境]
    │
    ▼
[Meraki Dashboard]
    │
    ▼
[API Gateway] ──► [Lambda] ──► [EventBridge]
    │                              │
    ▼                              ▼
[VPC]                       [Prometheus]
  ├── EKS Cluster              │
  │   ├── 監控服務            │
  │   └── 帳務服務 ◄──────────┘
  │       │
  │       ▼
  └── RDS (Multi-AZ)
```

## 元件說明

### 1. AWS 基礎設施

- **網路**
  - VPC（多 AZ）
  - 私有子網（RDS、EKS）
  - 公有子網（NAT、ALB）

- **運算**
  - EKS + Fargate
  - Lambda（webhook 處理）
  - EC2 Bastion（選配）

- **儲存**
  - RDS（帳務資料）
  - S3（日誌、報表）

### 2. 監控系統

- **時序資料庫**
  - Prometheus
  - Pushgateway

- **視覺化**
  - Grafana
  - 自訂儀表板

- **告警**
  - Alertmanager
  - SNS/Lambda

### 3. 帳務系統

- **API 服務**
  - Flask + SQLAlchemy
  - JWT 認證

- **資料庫**
  - PostgreSQL
  - 自動備份

- **整合**
  - 支付網關
  - 發票系統

## 安全考量

1. 網路安全
   - VPC 分區
   - 安全群組
   - WAF

2. 存取控制
   - IAM 角色
   - RBAC
   - MFA

3. 加密
   - TLS
   - KMS
   - at-rest

## 擴展性

1. 自動擴展
   - EKS Node
   - RDS Storage

2. 地區擴展
   - Multi-Region
   - Route53

## 監控指標

1. 基礎設施
   - CPU/Memory
   - Network I/O
   - Disk IOPS

2. 應用層
   - API Latency
   - Error Rate
   - Queue Length

3. 業務層
   - 客戶數
   - 設備數
   - 營收指標

## 災難恢復

1. 備份策略
   - RDS 快照
   - S3 版本控制
   - 設定備份

2. 故障轉移
   - Multi-AZ
   - 跨區域複製

## CI/CD 流程

1. 開發環境
   - 本地測試
   - 沙箱部署

2. 生產部署
   - 藍綠部署
   - 金絲雀發布

## 成本最佳化

1. 資源調整
   - Reserved Instances
   - Spot Instances
   - Auto Scaling

2. 儲存優化
   - S3 生命週期
   - RDS 儲存優化

## 後續規劃

1. 短期（1-3個月）
   - 完善監控
   - 優化效能

2. 中期（3-6個月）
   - 新增功能
   - 擴展整合

3. 長期（6個月+）
   - 全球部署
   - AI/ML 整合

Prometheus PoC: see `poc/prometheus-grafana-pocs.md`.