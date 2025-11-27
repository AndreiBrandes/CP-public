import os
import json
import time
import boto3
from datetime import datetime
sqs = boto3.client('sqs', region_name='eu-north-1')
s3 = boto3.client('s3', region_name='eu-north-1')
SQS_QUEUE_URL = os.getenv('SQS_QUEUE_URL')
S3_BUCKET = os.getenv('S3_BUCKET')
while True:
    response = sqs.receive_message(QueueUrl=SQS_QUEUE_URL, MaxNumberOfMessages=10)
    for msg in response.get('Messages', []):
        body = json.loads(msg['Body'])
        s3.put_object(Bucket=S3_BUCKET, Key=f"messages/{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}.json", Body=json.dumps(body))
        sqs.delete_message(QueueUrl=SQS_QUEUE_URL, ReceiptHandle=msg['ReceiptHandle'])
    time.sleep(10)
