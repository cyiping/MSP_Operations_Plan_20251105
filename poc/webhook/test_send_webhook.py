import requests
import json

SAMPLE_PAYLOAD = {
    "organizationId": "123456",
    "networkId": "N_ABC123",
    "type": "device_overheated",
    "serial": "Q2XX-XXXX-XXXX"
}

def main():
    url = 'http://127.0.0.1:5000/webhook'
    r = requests.post(url, json=SAMPLE_PAYLOAD)
    print('status', r.status_code)
    try:
        print('resp', r.json())
    except Exception:
        print('resp text', r.text)

if __name__ == '__main__':
    main()
