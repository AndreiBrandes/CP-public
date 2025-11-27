# DevOps Exam

What is this project?
----------------------
The project contains two microservces - ms1 and ms1.
ms1 is a rest api that valideates the token and the json structure. if valid , it sends the message to the sqs queue.
ms2 is a sqs consumer that pulls the message (every 10 seconds) from the sqs queue and uploads it to the s3 bucket, assumes it's valid.

ecs is used to run the microservices.

All aws resources are deployed using terraform

cicd is used to build the docker images and deploy them to the ecs cluster.

How to setup the project:
1. set aws credentials as env vars (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION)
2. cd terraform && terraform init
3. create terraform.tfvars file: echo 'dockerhub_password = "your-token"' > terraform.tfvars
4. terraform apply
4. get source bucket from terraform output, then upload code and trigger pipeline:
zip -r source.zip microservice1/ microservice2/ buildspec.yml deploy-buildspec.yml
aws s3 cp source.zip s3://<source-bucket-from-output>/source.zip
aws codepipeline start-pipeline-execution --name devops-exam-pipeline




how to test:
get alb url from terraform output: terraform output alb_dns_name
curl -X POST http://<alb-url>/api/process -H "Content-Type: application/json" -d '{"token": "<your-token>", "data": {"email_subject": "test", "email_sender": "me", "email_timestream": "123", "email_content": "hello"}}'
should return: {"message":"Request processed successfully"}
wait 15 seconds, then check s3 bucket for the uploaded file

