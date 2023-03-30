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
    START_TIME=$(date +%s)
    echo "Starting instances:"
    COUNTER=0
    for INSTANCE_ID in $INSTANCE_IDS
    do
        ((COUNTER++))
        INSTANCE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[].Instances[].Tags[?Key=='Name'].Value" --output text)
        echo "$COUNTER. $INSTANCE_NAME (Instance ID: $INSTANCE_ID)"
        aws ec2 start-instances --instance-ids $INSTANCE_ID > /dev/null
    done

    # Wait for instances to start
    echo "Waiting for instances to start..."
    while [ $(aws ec2 describe-instances --instance-ids $INSTANCE_IDS --query 'Reservations[].Instances[?State.Name==`running`].InstanceId' --output text | wc -w) -ne $(echo $INSTANCE_IDS | wc -w) ]
    do
        sleep 5
    done
    END_TIME=$(date +%s)
    ELAPSED_TIME=$((END_TIME - START_TIME))
    echo "All instances are now running. Elapsed time: $ELAPSED_TIME seconds."
    
    # Get the public IP addresses of the instances
    echo "Public IP addresses of started instances:"
    for INSTANCE_ID in $INSTANCE_IDS
    do
        INSTANCE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[].Instances[].Tags[?Key=='Name'].Value" --output text)
        IPV4=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[].Instances[].PublicIpAddress" --output text)
        echo "$INSTANCE_NAME (Instance ID: $INSTANCE_ID): $IPV4"
    done
fi
