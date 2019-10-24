#!/bin/bash

set -ex
AWS_DEFAULT_REGION="eu-central-1"
AWS_PROFILE="default"

docker build -t flask-gateway .

GATEWAY_IMAGE="$( aws ecr create-repository --repository-name flask-gateway \
              --region ${AWS_DEFAULT_REGION} --profile ${AWS_PROFILE} \
              --query '[repository.repositoryUri]' --output text || aws ecr describe-repositories --repository-name flask-gateway \
              --region ${AWS_DEFAULT_REGION} --profile ${AWS_PROFILE} \
              --query '[repositories[0].repositoryUri]' --output text)" \


echo ${GATEWAY_IMAGE}

docker tag flask-gateway ${GATEWAY_IMAGE}

$(aws ecr get-login --no-include-email --region ${AWS_DEFAULT_REGION}  --profile ${AWS_PROFILE})

docker push ${GATEWAY_IMAGE}
