#! /bin/bash

# This script is used for manually performing copying of a container image from a source registry
# to AWS ECR. Requires skopeo to be installed.

export IMAGETAG='prod-2.1.0'
# May not need to assume role as a human, only service account
export role_arn='arn:aws:iam::297945954695:role/kubecost-add-on-role-maintainer'
export role_session_name='ecr'
export profile_name='ecr'

temp_role=$(aws sts assume-role --role-arn $role_arn --role-session-name $role_session_name --region us-east-1 --output json)

export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq -r .Credentials.SessionToken)

# Use AWS_PROFILE=EngineeringDeveloper when running as a human
aws ecr get-login-password --region us-east-1 | skopeo login --username AWS --password-stdin 709825985650.dkr.ecr.us-east-1.amazonaws.com
skopeo copy -a docker://gcr.io/kubecost1/cost-model:$IMAGETAG docker://709825985650.dkr.ecr.us-east-1.amazonaws.com/stackwatch/eks/cost-model:prod-2.1.0-eks1
