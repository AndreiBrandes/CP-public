import os
import json
import boto3
from flask import Flask, request, jsonify
app = Flask(__name__)
sqs = boto3.client('sqs', region_name=os.getenv('AWS_REGION', 'eu-north-1'))
SQS_QUEUE_URL = os.getenv('SQS_QUEUE_URL')
TOKEN = os.getenv('TOKEN', '$DJISA<$#45ex3RtYr')
@app.route('/health')
def health():
    return jsonify({'status': 'ok'})
@app.route('/api/process', methods=['POST'])
def process():
    data = request.get_json()
    if data.get('token') != TOKEN:
        return jsonify({'error': 'invalid token'}), 401
    sqs.send_message(QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps(data.get('data')))
    return jsonify({'message': 'ok'})
