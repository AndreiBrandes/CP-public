#!/bin/bash

# Deployment script
# Usage: ./deploy.sh <dockerhub-username> [image-tag]

set -e

DOCKERHUB_USER=${1:-"your-dockerhub-username"}
IMAGE_TAG=${2:-"latest"}

if [ "$DOCKERHUB_USER" == "your-dockerhub-username" ]; then
    echo "Error: Please provide your Docker Hub username"
    echo "Usage: ./deploy.sh <dockerhub-username> [image-tag]"
    exit 1
fi

echo "Building Docker images..."
docker build -t ${DOCKERHUB_USER}/microservice1:${IMAGE_TAG} ./microservice1
docker build -t ${DOCKERHUB_USER}/microservice2:${IMAGE_TAG} ./microservice2

echo "Pushing to Docker Hub..."
docker push ${DOCKERHUB_USER}/microservice1:${IMAGE_TAG}
docker push ${DOCKERHUB_USER}/microservice2:${IMAGE_TAG}

echo "Updating Terraform with new image URLs..."
cd terraform
terraform apply -var="docker_image_ms1=${DOCKERHUB_USER}/microservice1:${IMAGE_TAG}" \
                -var="docker_image_ms2=${DOCKERHUB_USER}/microservice2:${IMAGE_TAG}" \
                -auto-approve

echo "Forcing ECS service updates..."
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
aws ecs update-service --cluster $CLUSTER_NAME --service devops-exam-ms1 --force-new-deployment --region eu-north-1
aws ecs update-service --cluster $CLUSTER_NAME --service devops-exam-ms2 --force-new-deployment --region eu-north-1

echo "Waiting for services to stabilize..."
aws ecs wait services-stable --cluster $CLUSTER_NAME --services devops-exam-ms1 devops-exam-ms2 --region eu-north-1

echo "Deployment complete!"
echo "ALB DNS: $(terraform output -raw alb_dns_name)"

