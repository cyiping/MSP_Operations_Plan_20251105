"""簡易帳務 microservice PoC

API:
 - POST /customers {name, billing_contact}
 - POST /subscriptions {customer_id, sku, quantity, unit_price}
 - POST /usage {subscription_id, metric, value, period_start, period_end}
 - POST /invoices/generate {billing_cycle}

發票會以 JSON 檔案儲存在 billing/invoices/ 目錄。
外部支付或上傳行為以環境變數表示，預設不會呼叫外部服務。
"""

import os
import json
from datetime import datetime
from flask import Flask, request, jsonify
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
DB_PATH = os.getenv('BILLING_DB', os.path.join(BASE_DIR, 'billing.db'))
INVOICE_DIR = os.getenv('INVOICE_DIR', os.path.join(BASE_DIR, 'billing', 'invoices'))
os.makedirs(INVOICE_DIR, exist_ok=True)

engine = create_engine(f'sqlite:///{DB_PATH}')
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()


class Customer(Base):
    __tablename__ = 'customers'
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    billing_contact = Column(String)


class Subscription(Base):
    __tablename__ = 'subscriptions'
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey('customers.id'), nullable=False)
    sku = Column(String)
    quantity = Column(Integer, default=1)
    unit_price = Column(Float, default=0.0)
    customer = relationship('Customer')


class UsageRecord(Base):
    __tablename__ = 'usage'
    id = Column(Integer, primary_key=True)
    subscription_id = Column(Integer, ForeignKey('subscriptions.id'), nullable=False)
    metric = Column(String)
    value = Column(Float)
    period_start = Column(DateTime)
    period_end = Column(DateTime)


Base.metadata.create_all(bind=engine)

app = Flask(__name__)


@app.route('/customers', methods=['POST'])
def create_customer():
    data = request.get_json() or {}
    name = data.get('name')
    billing_contact = data.get('billing_contact')
    if not name:
        return jsonify({'error': 'name required'}), 400
    db = SessionLocal()
    c = Customer(name=name, billing_contact=billing_contact)
    db.add(c)
    db.commit()
    db.refresh(c)
    return jsonify({'id': c.id, 'name': c.name})


@app.route('/subscriptions', methods=['POST'])
def create_subscription():
    data = request.get_json() or {}
    customer_id = data.get('customer_id')
    sku = data.get('sku')
    quantity = data.get('quantity', 1)
    unit_price = data.get('unit_price', 0.0)
    if not customer_id:
        return jsonify({'error': 'customer_id required'}), 400
    db = SessionLocal()
    s = Subscription(customer_id=customer_id, sku=sku, quantity=quantity, unit_price=unit_price)
    db.add(s)
    db.commit()
    db.refresh(s)
    return jsonify({'id': s.id, 'sku': s.sku})


@app.route('/usage', methods=['POST'])
def add_usage():
    data = request.get_json() or {}
    subscription_id = data.get('subscription_id')
    metric = data.get('metric')
    value = data.get('value')
    period_start = data.get('period_start')
    period_end = data.get('period_end')
    if not subscription_id:
        return jsonify({'error': 'subscription_id required'}), 400
    db = SessionLocal()
    ur = UsageRecord(subscription_id=subscription_id, metric=metric, value=value,
                     period_start=datetime.fromisoformat(period_start) if period_start else None,
                     period_end=datetime.fromisoformat(period_end) if period_end else None)
    db.add(ur)
    db.commit()
    db.refresh(ur)
    return jsonify({'id': ur.id})


@app.route('/invoices/generate', methods=['POST'])
def generate_invoices():
    data = request.get_json() or {}
    billing_cycle = data.get('billing_cycle') or datetime.utcnow().strftime('%Y-%m')
    db = SessionLocal()
    subscriptions = db.query(Subscription).all()
    invoices = []
    for s in subscriptions:
        # 簡單計價：quantity * unit_price
        amount = (s.quantity or 1) * (s.unit_price or 0.0)
        invoice = {
            'invoice_id': f'inv-{s.id}-{billing_cycle}',
            'customer_id': s.customer_id,
            'subscription_id': s.id,
            'amount': amount,
            'billing_cycle': billing_cycle,
            'generated_at': datetime.utcnow().isoformat() + 'Z'
        }
        invoices.append(invoice)
        # save to file in INVOICE_DIR
        filename = os.path.join(INVOICE_DIR, invoice['invoice_id'] + '.json')
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(invoice, f, ensure_ascii=False, indent=2)

    return jsonify({'count': len(invoices), 'billing_cycle': billing_cycle})


if __name__ == '__main__':
    # Local debug server
    app.run(host='127.0.0.1', port=int(os.getenv('BILLING_PORT', 8000)))
