# Project DESC
Change to bookapp directory
```


# HOW TO

## Run locally

## Run Docker image locally

## Push to AWS ECR
Basic pattern is:
```
aws ecr get-login-password --region region | docker login --username AWS --password-stdin aws_account_id.dkr.ecr.region.amazonaws.com
```