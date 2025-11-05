"""Meraki webhook 範例接收器（PoC）。

此檔案示範如何以 "variables-as-env" 的方式處理外部 API / key：
- MERAKI_API_URL: (可選) 若要在 Lambda 中呼叫 Meraki API，設定此環境變數為 API endpoint
- MERAKI_API_KEY: (可選) Meraki Dashboard API key（生產環境請使用 Secrets Manager）
- PROMETHEUS_PUSHGATEWAY: (可選) 若要把事件轉為 metric 推送到 Pushgateway，設定此變數

設計原則：
- 若未設定外部 endpoint 或 key，函式僅作解析與 log，並不會外部連線，確保在本地或未配置 AWS 的情況下安全執行。
"""

import os
import json
import base64
from datetime import datetime
import requests


def _get_env(name, default=None):
    """從環境變數取得設定（PoC 用 helper）。"""
    return os.environ.get(name, default)


def lambda_handler(event, context):
    """處理 Meraki Webhook 事件。

    注意：為了配合使用者要求（不自動連上 AWS），此 handler 不會在未設定外部變數時發出任何外部 HTTP 請求。
    """
    # 解析 body（API Gateway proxy integration 格式）
    try:
        body = event.get('body')
        if event.get('isBase64Encoded'):
            body = base64.b64decode(body).decode('utf-8')
        payload = json.loads(body)
    except Exception as e:
        return {'statusCode': 400, 'body': json.dumps({'error': 'invalid payload', 'detail': str(e)})}

    # 建立紀錄
    record = {
        'received_at': datetime.utcnow().isoformat() + 'Z',
        'orgId': payload.get('organizationId'),
        'networkId': payload.get('networkId'),
        'type': payload.get('type'),
        'deviceSerial': payload.get('serial') or payload.get('deviceSerial')
    }

    print('Meraki webhook received:', json.dumps(record))

    # 範例：如果設定了 PROMETHEUS_PUSHGATEWAY，則嘗試推送一個簡單的 metric
    pushgateway = _get_env('PROMETHEUS_PUSHGATEWAY')
    if pushgateway:
        try:
            # Prometheus pushgateway expects a specific format; 這裡僅示範以文本格式推送
            metric_name = 'meraki_event_total'
            metric_value = 1
            job = 'meraki_poc'
            url = f"{pushgateway}/metrics/job/{job}"
            payload_txt = f"{metric_name} {metric_value}\n"
            # 小心：在生產環境應檢查 TLS 與憑證
            requests.post(url, data=payload_txt, timeout=5)
            print('pushed metric to', url)
        except Exception as e:
            print('failed to push metric (ignored in PoC):', str(e))

    # 若設定了 MERAKI_API_URL 與 MERAKI_API_KEY，可作為範例呼叫 API（此動作為可選）
    meraki_url = _get_env('MERAKI_API_URL')
    meraki_key = _get_env('MERAKI_API_KEY')
    if meraki_url and meraki_key:
        try:
            # 範例：取得設備詳細資料（僅示範用，實務上請依 API 規格調整）
            serial = record.get('deviceSerial')
            if serial:
                headers = {'X-Cisco-Meraki-API-Key': meraki_key, 'Content-Type': 'application/json'}
                device_endpoint = f"{meraki_url}/devices/{serial}"
                r = requests.get(device_endpoint, headers=headers, timeout=5)
                print('meraki device response status', r.status_code)
        except Exception as e:
            print('failed to call Meraki API (ignored in PoC):', str(e))

    # 回應 200 表示接收成功
    return {'statusCode': 200, 'body': json.dumps({'status': 'ok'})}
