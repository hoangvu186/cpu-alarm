# CPU Alarm Lab - Deployment Script for CloudFormation (PowerShell)
# This script automates the deployment of the CPU Alarm CloudFormation stack

$ErrorActionPreference = "Stop"

# Configuration
$STACK_NAME = "cpu-alarm-lab"
$TEMPLATE_FILE = "cpu-alarm-cloudformation.yaml"
$REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }

function Write-Status {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

# Header
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "CPU Alarm → Email Alert via SNS Lab" -ForegroundColor Cyan
Write-Host "CloudFormation Deployment Script" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..."
Write-Host ""

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
    Write-Status "AWS CLI found: $awsVersion"
}
catch {
    Write-Error-Custom "AWS CLI is not installed or not in PATH"
    Write-Host "Install from: https://aws.amazon.com/cli/"
    exit 1
}

# Check if template file exists
if (-not (Test-Path $TEMPLATE_FILE)) {
    Write-Error-Custom "Template file not found: $TEMPLATE_FILE"
    exit 1
}
Write-Status "Template file found: $TEMPLATE_FILE"

# Check AWS credentials
try {
    $accountInfo = aws sts get-caller-identity --output json | ConvertFrom-Json
    $ACCOUNT_ID = $accountInfo.Account
    Write-Status "AWS Account: $ACCOUNT_ID"
}
catch {
    Write-Error-Custom "AWS credentials not configured"
    Write-Host "Configure with: aws configure"
    exit 1
}

Write-Host ""
Write-Host "Deployment Configuration:"
Write-Host "  Stack Name: $STACK_NAME"
Write-Host "  Region: $REGION"
Write-Host "  Template: $TEMPLATE_FILE"
Write-Host ""

# Prompt for email
Write-Host "Enter your email address for alarm notifications:"
$EMAIL = Read-Host "Email"

if ([string]::IsNullOrEmpty($EMAIL)) {
    Write-Error-Custom "Email address cannot be empty"
    exit 1
}

# Validate email format
$emailPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
if (-not ($EMAIL -match $emailPattern)) {
    Write-Error-Custom "Invalid email format"
    exit 1
}

Write-Status "Email: $EMAIL"
Write-Host ""

# Check if stack already exists
Write-Host "Checking if stack already exists..."
try {
    $existingStack = aws cloudformation describe-stacks `
        --stack-name $STACK_NAME `
        --region $REGION `
        --output json 2>&1 | ConvertFrom-Json
    
    Write-Warning-Custom "Stack '$STACK_NAME' already exists"
    
    $response = Read-Host "Do you want to update the existing stack? (y/n)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Warning-Custom "Deployment cancelled"
        exit 0
    }
    $OPERATION = "update-stack"
    $ACTION = "Updating"
}
catch {
    $OPERATION = "create-stack"
    $ACTION = "Creating"
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "$ACTION stack: $STACK_NAME" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Deploy/Update stack
$cfParams = @(
    "ParameterKey=EmailAddress,ParameterValue=$EMAIL",
    "ParameterKey=CPUThreshold,ParameterValue=80",
    "ParameterKey=EvaluationPeriods,ParameterValue=1",
    "ParameterKey=DatapointsToAlarm,ParameterValue=1"
)

try {
    aws cloudformation $OPERATION `
        --stack-name $STACK_NAME `
        --template-body "file://$TEMPLATE_FILE" `
        --parameters $cfParams `
        --capabilities CAPABILITY_NAMED_IAM `
        --region $REGION
    
    Write-Status "CloudFormation command executed successfully"
}
catch {
    Write-Error-Custom "CloudFormation command failed: $_"
    exit 1
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Deployment Status" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Wait for stack operation to complete
$WAIT_CONDITION = if ($OPERATION -eq "update-stack") { "stack-update-complete" } else { "stack-create-complete" }

Write-Status "Waiting for stack $WAIT_CONDITION..."
Write-Warning-Custom "This may take 5-10 minutes..."
Write-Host ""

try {
    aws cloudformation wait $WAIT_CONDITION `
        --stack-name $STACK_NAME `
        --region $REGION
    
    Write-Status "Stack deployment completed successfully!"
}
catch {
    Write-Error-Custom "Stack deployment failed or timed out"
    Write-Host ""
    Write-Host "Check stack events:"
    Write-Host "aws cloudformation describe-stack-events --stack-name $STACK_NAME --region $REGION"
    exit 1
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Stack Outputs" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

aws cloudformation describe-stacks `
    --stack-name $STACK_NAME `
    --region $REGION `
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' `
    --output table

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

Write-Status "Check your email ($EMAIL) for SNS subscription confirmation"
Write-Status "Click the confirmation link to activate email notifications"
Write-Host ""
Write-Status "SSH into the instance and generate CPU load to test:"
Write-Host "  1. Get instance IP from EC2 console"
Write-Host "  2. ssh -i your-key.pem ec2-user@<instance-ip>"
Write-Host "  3. sudo yum install -y stress-ng"
Write-Host "  4. stress-ng --cpu 2 --timeout 10m"
Write-Host ""
Write-Status "Monitor the alarm in CloudWatch console:"
Write-Host "  https://console.aws.amazon.com/cloudwatch/home?region=$REGION#alarmsV2:"
Write-Host ""

# Get stack outputs
$stackOutputs = aws cloudformation describe-stacks `
    --stack-name $STACK_NAME `
    --region $REGION `
    --query 'Stacks[0].[Outputs[?OutputKey==`EC2InstanceId`].OutputValue[0],Outputs[?OutputKey==`SNSTopicArn`].OutputValue[0]]' `
    --output json | ConvertFrom-Json

$INSTANCE_ID = $stackOutputs[0]
$TOPIC_ARN = $stackOutputs[1]

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Lab Summary" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Stack Name:       $STACK_NAME"
Write-Host "Region:           $REGION"
Write-Host "Instance ID:      $INSTANCE_ID"
Write-Host "SNS Topic ARN:    $TOPIC_ARN"
Write-Host "Email:            $EMAIL"
Write-Host ""
Write-Status "Lab deployment complete!"
