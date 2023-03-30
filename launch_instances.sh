#!/bin/bash

#Written by Anthony Segarra on 3/28/2023
#usage: make script executable with chmod 744 script_name.sh
#       to run from your terminal, type ./script_name.sh

# Check if aws cli is installed
if ! command -v aws &> /dev/null
then
    echo "aws cli not found, please install and configure aws cli"
    exit
fi

# Get instance IDs of all stopped instances
INSTANCE_IDS=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=stopped --query "Reservations[].Instances[].InstanceId" --output text)

# Start all stopped instances
if [ -z "$INSTANCE_IDS" ]
then
    echo "No stopped instances found."
else
    aws ec2 start-instances --instance-ids $INSTANCE_IDS
    echo "Starting instances: $INSTANCE_IDS"
    for i in $INSTANCE_IDS; do
        # Wait until the instance is running
        aws ec2 wait instance-running --instance-ids $i

        # Get the name and Public IPv4 address of the instance
        NAME=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$i" "Name=key,Values=Name" --query "Tags[*].Value" --output text)
        PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $i --query 'Reservations[].Instances[].PublicIpAddress' --output text)
        echo "Instance Name: $NAME, Instance ID: $i, Public IP address: $PUBLIC_IP"
    done
fi
