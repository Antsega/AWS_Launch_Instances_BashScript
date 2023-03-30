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
    # Start instances
    aws ec2 start-instances --instance-ids $INSTANCE_IDS
    echo "Starting instances: $INSTANCE_IDS"

    # Wait for instances to be in running state
    echo "Waiting for instances to start..."
    START_TIME=$(date +%s)
    RUNNING_INSTANCE_IDS=""
    COUNTER=0
    while [ -z "$RUNNING_INSTANCE_IDS" ] || [ "$COUNTER" -lt 10 ]
    do
        sleep 10
        RUNNING_INSTANCE_IDS=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[].Instances[?InstanceId=='$INSTANCE_IDS'].PublicIpAddress" --output text)
        echo -ne "Instances still starting... $((++COUNTER))0 seconds elapsed\r"
    done
    echo -e "\nInstances started successfully."

    # Print instance details
    echo "Instance details:"
    echo "------------------"
    echo "Instance Name\tInstance ID\tPublic IPv4"
    echo "------------\t----------\t-----------"
    aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[].Instances[].Tags[?Key=='Name'].Value | [0], Instances[].InstanceId, Instances[].PublicIpAddress | [0,1,2]" --output text

    END_TIME=$(date +%s)
    ELAPSED_TIME=$((END_TIME - START_TIME))
    echo "Total time elapsed: $ELAPSED_TIME seconds."
fi
