#!/bin/bash

# This script will find all AWS CloudFormation stacks matching the supplied filter
# and export the outputs into environment variables.
# 
# This script is assumed to be run on a host with an IAM profile matching the following:
#
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "Stmt1465412301000",
#             "Effect": "Allow",
#             "Action": [
#                 "cloudformation:DescribeStacks"
#             ],
#             "Resource": [
#                 "*"
#             ]
#         }
#     ]
# }


function usage {
  echo "usage: source fetchenv.sh <env name>"
}

function main {

  if [ -z "$1" ]; then
    usage
    exit 1
  else
    stack_filter="$1"
  fi

  if [ -z "$2" ]; then
    region=us-east-1
  else
    region="$2"
  fi

  stacks=$(aws cloudformation describe-stacks --region "$region" | \
             grep "StackName" | grep -i "$stack_filter" | cut -d\" -f4)

  if [ -z "$stacks" ]; then
    echo "Unable to locate any CloudFormation stacks matching the supplied name"
    exit 1
  fi

  for stack in $stacks; do
    stack_info=$(aws cloudformation describe-stacks --region $region --stack-name $stack --output json)
    if [[ "$stack_info" =~ "OutputKey" ]]; then
      read -r -a output_keys <<< $(echo "$stack_info" | jq ".Stacks[].Outputs[].OutputKey")
      read -r -a output_vals <<< $(echo "$stack_info" | jq ".Stacks[].Outputs[].OutputValue")
      for ((i=0;i<${#output_keys[@]};++i)); do
        key=$(echo "${output_keys[i]}" | sed -e 's/^"//'  -e 's/"$//')
        val=$(echo "${output_vals[i]}" | sed -e 's/^"//'  -e 's/"$//')
        echo "export $key=$val"
        export "$key"="$val"
      done
    fi
  done
}

main "$@"