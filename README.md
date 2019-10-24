# Introduction

Taken from [hackernoon](https://hackernoon.com/perform-canary-deployments-with-aws-app-mesh-on-amazon-ecs-fargate-3l3lo3zf8)


My notes:

- App Mesh maps virtual nodes and services onto ECS services
- App Mesh virtual routers define routing policies
- Envoy updates its service directory from Route53 as for the services that are configured for AWS App Mesh
- The ECS services have auto discovery enabled which creates a Route53 DNS A or PTR record for each task instance for a given hostname
- each task has an [envoy](https://www.envoyproxy.io/) as a sidecar for in and outgoing service traffic
- The application containers /etc/hosts gets an entry for each internal service it wants to talk to and they all point to the envoy sidecar which then reroutes to the closest instance it finds from the hosts returned by Route53
- Adding an AWS XRay container as a sidecar and configuring Envoy to use it traces the request information into XRay


This is sample code for running App Mesh on ECS Fargate

# Getting Started

## Prerequisites

- Install latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).

- Build and push the flask api and gateway images using setup-ecr.sh from within /api/ and api-gateway/
- Configure aws-cli to support Appmesh APIs
- Change the profile variable and default region variable in bash files.

## Cloudformation template for ECS, VPC and App Mesh

- Setup VPC

```
$ aws cloudformation create-stack --stack-name flask-sample --template-body file://ecs-vpc.yaml --profile YOUR_PROFILE --region YOUR_REGION
```

- Setup Mesh

```
$ aws cloudformation create-stack --stack-name flask-app-mesh --template-body file://ecs-app-mesh.yaml --profile YOUR_PROFILE --region YOUR_REGION
```

- Setup ECS Cluster
  Change AWS_DEFAULT_REGION and AWS_PROFILE variables in ecs-services-stack.sh, then run

```
$ bash ecs-services-stack.sh
```

## Apps

Once VPC and ECS cluster are setup you can deploy applications and configure mesh.

## Building api

In /api directory, Change AWS_DEFAULT_REGION and AWS_PROFILE variables in .sh files

```
$ bash setup-ecr.sh && bash setup-task-def.sh
```

## Building api

In /api-gateway directory, Change AWS_DEFAULT_REGION and AWS_PROFILE variables in .sh files

```
$ bash setup-ecr.sh && bash setup-task-def.sh
```
