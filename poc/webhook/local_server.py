from flask import Flask, request, jsonify
import json
import meraki_webhook_lambda as lambda_module
import os
from dotenv import load_dotenv

# Load .env if present (optional). This allows local testing with environment variables
# without modifying source code. Create a `.env` file by copying `.env.example`.
load_dotenv()

app = Flask(__name__)


@app.route('/webhook', methods=['POST'])
def webhook():
    # 本地 server 將收到的 POST body 轉為與 API Gateway 相同的事件格式
    try:
        payload = request.get_json(force=True)
    except Exception as e:
        return jsonify({'error': 'invalid json', 'detail': str(e)}), 400

    event = {
        'body': json.dumps(payload),
        'isBase64Encoded': False
    }

    # 呼叫 PoC 的 lambda handler；handler 已設計為在未提供外部 API 變數時不會發出外部請求
    resp = lambda_module.lambda_handler(event, None)
    # lambda_handler 回傳 dict {statusCode, body}
    status = resp.get('statusCode', 200)
    body = resp.get('body')
    try:
        parsed = json.loads(body)
    except Exception:
        parsed = {'body': body}

    return jsonify(parsed), status


if __name__ == '__main__':
    # 預設只在 localhost 綁定，不會對外開放
    app.run(host='127.0.0.1', port=int(os.getenv('POC_PORT', 5000)))
