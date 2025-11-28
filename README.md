# Microservices project by Andrei Brandes

What is this project?
----------------------
The project contains two microservces - ms1 and ms1.
ms1 ./microservice1 is a rest api that valideates the token and the json structure. if valid , it sends the message to the sqs queue.
ms2 ./microservice2 is a sqs consumer that pulls the message (every 10 seconds) from the sqs queue and uploads it to the s3 bucket, assumes it's valid.

ecs is used to run the microservices.

All aws resources are deployed using terraform ./terraform

CI - ./buildspec.yml
CD - ./deploy-buildspec.yml
CI builds the docker images and pushes them to dockerhub.
CD pulls the images from dockerhub and deploys them to the ecs cluster.


Project setup
-------------
1. Set aws credentials as env vars (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION)
2. Cd terraform && terraform init
3. Create terraform.tfvars file: echo 'dockerhub_password = "your-token"' > terraform.tfvars
4. terraform apply
5. Get source bucket from terraform output, then upload code and trigger pipeline:
zip -r source.zip microservice1/ microservice2/ buildspec.yml deploy-buildspec.yml
aws s3 cp source.zip s3://<source-bucket-from-output>/source.zip
aws codepipeline start-pipeline-execution --name devops-exam-pipeline


Test
----
get alb url from terraform output: terraform output alb_dns_name
run test.sh: ./test.sh <alb-url> <your-token>
or manually:

curl -X POST http://<alb-url>/api/process -H "Content-Type: application/json" -d '{"token": "<your-token>", "data": {"email_subject": "test", "email_sender": "me", "email_timestream": "123", "email_content": "hello"}}'
should return: {"message":"Request processed successfully"}
wait 15 seconds, then check s3 bucket for the uploaded file

