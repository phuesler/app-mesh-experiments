#!/bin/bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

AWS_DEFAULT_REGION="eu-central-1"
AWS_PROFILE="default"

cluster_stack_output=$(aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    cloudformation describe-stacks --stack-name "flask-sample" \
    | jq '.Stacks[].Outputs[]')

task_role_arn=($(echo $cluster_stack_output \
    | jq -r 'select(.OutputKey == "TaskIamRoleArn") | .OutputValue'))

echo ${task_role_arn}

execution_role_arn=($(echo $cluster_stack_output \
    | jq -r 'select(.OutputKey == "TaskExecutionIamRoleArn") | .OutputValue'))

ecs_service_log_group=($(echo $cluster_stack_output \
    | jq -r 'select(.OutputKey == "ECSServiceLogGroup") | .OutputValue'))

envoy_log_level="debug"

API_IMAGE="$( aws ecr describe-repositories --repository-name flask-api --region ${AWS_DEFAULT_REGION} --profile ${AWS_PROFILE} --query '[repositories[0].repositoryUri]' --output text)"

#Api v1 Task Definition
v1_task_def_json=$(jq -n \
    --arg APP_IMAGE $API_IMAGE \
    --arg SERVICE_LOG_GROUP $ecs_service_log_group \
    --arg TASK_ROLE_ARN $task_role_arn \
    --arg EXECUTION_ROLE_ARN $execution_role_arn \
    --arg ENVOY_LOG_LEVEL $envoy_log_level \
    --arg LOG_STREAM_PREFIX "api" \
    --arg API_FAMILY "api" \
    --arg VERSION "1" \
    --arg VIRTUAL_NODE "mesh/flask-mesh/virtualNode/api-vn" \
    -f "${DIR}/task-definition.json")


task_def_arn=$(aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    ecs register-task-definition \
    --cli-input-json "${v1_task_def_json}" \
    --query [taskDefinition.taskDefinitionArn] --output text)

#update ECS servcie if there is new version of task definiton
# aws ecs update-service  --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
#                         --cluster flask \
#                         --service api \
#                         --task-definition ${task_def_arn} \
#                         --desired-count 1

#Api v2 Task Definition
v2_task_def_json=$(jq -n \
    --arg APP_IMAGE $API_IMAGE \
    --arg SERVICE_LOG_GROUP $ecs_service_log_group \
    --arg TASK_ROLE_ARN $task_role_arn \
    --arg EXECUTION_ROLE_ARN $execution_role_arn \
    --arg ENVOY_LOG_LEVEL $envoy_log_level \
    --arg LOG_STREAM_PREFIX "api-v2" \
    --arg API_FAMILY "api-v2" \
    --arg VERSION "2" \
    --arg VIRTUAL_NODE "mesh/flask-mesh/virtualNode/api-v2-vn" \
    -f "${DIR}/task-definition.json")

v2_task_def_arn=$(aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    ecs register-task-definition \
    --cli-input-json "${v2_task_def_json}" \
    --query [taskDefinition.taskDefinitionArn] --output text)

#update ECS servcie if there is new version of task definiton
# aws ecs update-service  --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
#                         --cluster flask \
#                         --service api-v2 \
#                         --task-definition ${v2_task_def_arn} \
#                         --desired-count 1
