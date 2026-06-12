#!/bin/bash

# CPU Alarm Lab - Deployment Script for CloudFormation
# This script automates the deployment of the CPU Alarm CloudFormation stack

set -e  # Exit on error

echo "======================================================"
echo "CPU Alarm → Email Alert via SNS Lab"
echo "CloudFormation Deployment Script"
echo "======================================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="cpu-alarm-lab"
TEMPLATE_FILE="cpu-alarm-cloudformation.yaml"
REGION="${AWS_REGION:-us-east-1}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    echo "Install from: https://aws.amazon.com/cli/"
    exit 1
fi
print_status "AWS CLI found: $(aws --version)"

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    print_error "Template file not found: $TEMPLATE_FILE"
    exit 1
fi
print_status "Template file found: $TEMPLATE_FILE"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured"
    echo "Configure with: aws configure"
    exit 1
fi
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_status "AWS Account: $ACCOUNT_ID"

echo ""
echo "Deployment Configuration:"
echo "  Stack Name: $STACK_NAME"
echo "  Region: $REGION"
echo "  Template: $TEMPLATE_FILE"
echo ""

# Prompt for email
echo "Enter your email address for alarm notifications:"
read -p "Email: " EMAIL

if [ -z "$EMAIL" ]; then
    print_error "Email address cannot be empty"
    exit 1
fi

# Validate email format
if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    print_error "Invalid email format"
    exit 1
fi

print_status "Email: $EMAIL"
echo ""

# Check if stack already exists
echo "Checking if stack already exists..."
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
    print_warning "Stack '$STACK_NAME' already exists"
    read -p "Do you want to update the existing stack? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled"
        exit 0
    fi
    OPERATION="update-stack"
    ACTION="Updating"
else
    OPERATION="create-stack"
    ACTION="Creating"
fi

echo ""
echo "======================================================"
echo "$ACTION stack: $STACK_NAME"
echo "======================================================"
echo ""

# Deploy/Update stack
aws cloudformation $OPERATION \
    --stack-name "$STACK_NAME" \
    --template-body file://"$TEMPLATE_FILE" \
    --parameters \
        ParameterKey=EmailAddress,ParameterValue="$EMAIL" \
        ParameterKey=CPUThreshold,ParameterValue=80 \
        ParameterKey=EvaluationPeriods,ParameterValue=1 \
        ParameterKey=DatapointsToAlarm,ParameterValue=1 \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION"

if [ $? -eq 0 ]; then
    print_status "CloudFormation command executed successfully"
else
    print_error "CloudFormation command failed"
    exit 1
fi

echo ""
echo "======================================================"
echo "Deployment Status"
echo "======================================================"
echo ""

# Wait for stack operation to complete
WAIT_CONDITION="stack-create-complete"
if [ "$OPERATION" = "update-stack" ]; then
    WAIT_CONDITION="stack-update-complete"
fi

print_status "Waiting for stack $WAIT_CONDITION..."
print_warning "This may take 5-10 minutes..."
echo ""

aws cloudformation wait $WAIT_CONDITION \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

if [ $? -eq 0 ]; then
    print_status "Stack deployment completed successfully!"
else
    print_error "Stack deployment failed or timed out"
    echo ""
    echo "Check stack events:"
    echo "aws cloudformation describe-stack-events --stack-name $STACK_NAME --region $REGION"
    exit 1
fi

echo ""
echo "======================================================"
echo "Stack Outputs"
echo "======================================================"
echo ""

aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

echo ""
echo "======================================================"
echo "Next Steps"
echo "======================================================"
echo ""
print_status "Check your email ($EMAIL) for SNS subscription confirmation"
print_status "Click the confirmation link to activate email notifications"
echo ""
print_status "SSH into the instance and generate CPU load to test:"
echo "  1. Get instance IP from EC2 console"
echo "  2. ssh -i your-key.pem ec2-user@<instance-ip>"
echo "  3. sudo yum install -y stress-ng"
echo "  4. stress-ng --cpu 2 --timeout 10m"
echo ""
print_status "Monitor the alarm in CloudWatch console:"
echo "  https://console.aws.amazon.com/cloudwatch/home?region=$REGION#alarmsV2:"
echo ""

# Stack summary
INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`EC2InstanceId`].OutputValue' \
    --output text)

TOPIC_ARN=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`SNSTopicArn`].OutputValue' \
    --output text)

echo "======================================================"
echo "Lab Summary"
echo "======================================================"
echo "Stack Name:       $STACK_NAME"
echo "Region:           $REGION"
echo "Instance ID:      $INSTANCE_ID"
echo "SNS Topic ARN:    $TOPIC_ARN"
echo "Email:            $EMAIL"
echo ""
print_status "Lab deployment complete!"
