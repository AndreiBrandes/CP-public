#!/bin/bash

# Test script for the microservices
# Usage: ./test.sh <ALB_DNS_NAME> <TOKEN>

ALB_DNS=$1
TOKEN=$2

if [ -z "$ALB_DNS" ] || [ -z "$TOKEN" ]; then
    echo "Usage: ./test.sh <ALB_DNS_NAME> <TOKEN>"
    exit 1
fi

echo "Testing health endpoint..."
curl -s http://${ALB_DNS}/health

echo -e "\n\nTesting process endpoint with valid data..."
curl -X POST http://${ALB_DNS}/api/process \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"email_subject\": \"Test Subject\",
      \"email_sender\": \"Test User\",
      \"email_timestream\": \"1693561101\",
      \"email_content\": \"This is a test message\"
    },
    \"token\": \"${TOKEN}\"
  }"

echo -e "\n\nTesting with invalid token..."
curl -X POST http://${ALB_DNS}/api/process \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"email_subject\": \"Test\",
      \"email_sender\": \"Test\",
      \"email_timestream\": \"1693561101\",
      \"email_content\": \"Test\"
    },
    \"token\": \"invalid-token\"
  }"

echo -e "\n\nDone!"

