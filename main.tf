# CPU Alarm Lab - Terraform Configuration
# This provides an alternative to CloudFormation using Terraform

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "email_address" {
  description = "Email address for CPU alarm notifications"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email_address))
    error_message = "Must be a valid email address"
  }
}

variable "cpu_threshold" {
  description = "CPU utilization percentage threshold for alarm"
  type        = number
  default     = 80
  validation {
    condition     = var.cpu_threshold >= 0 && var.cpu_threshold <= 100
    error_message = "CPU threshold must be between 0 and 100"
  }
}

variable "evaluation_periods" {
  description = "Number of periods to evaluate before triggering alarm"
  type        = number
  default     = 1
  validation {
    condition     = var.evaluation_periods >= 1
    error_message = "Evaluation periods must be at least 1"
  }
}

variable "period_seconds" {
  description = "Period in seconds for metric evaluation (default 5 minutes)"
  type        = number
  default     = 300
  validation {
    condition     = var.period_seconds > 0
    error_message = "Period must be greater than 0"
  }
}

# Data source to get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ===== Security Group =====
resource "aws_security_group" "cpu_alarm_sg" {
  name        = "cpu-alarm-lab-sg"
  description = "Security group for CPU Alarm lab instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "CPUAlarmLabSG"
    Lab  = "CPU-Alarm-SNS"
  }
}

# ===== IAM Role for EC2 =====
resource "aws_iam_role" "ec2_role" {
  name = "cpu-alarm-lab-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "CPUAlarmLabRole"
    Lab  = "CPU-Alarm-SNS"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "cpu-alarm-lab-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ===== EC2 Instance =====
resource "aws_instance" "cpu_alarm_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.cpu_alarm_sg.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    hostname_placeholder = "cpu-alarm-lab"
  }))

  tags = {
    Name = "CPUAlarmLabInstance"
    Lab  = "CPU-Alarm-SNS"
  }

  depends_on = [aws_iam_role_policy_attachment.cloudwatch_policy]
}

# ===== SNS Topic =====
resource "aws_sns_topic" "cpu_alarm_topic" {
  name              = "cpu-alarm-topic"
  display_name      = "CPU Alarm Notifications"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "CPUAlarmTopic"
    Lab  = "CPU-Alarm-SNS"
  }
}

# ===== SNS Email Subscription =====
resource "aws_sns_topic_subscription" "cpu_alarm_email" {
  topic_arn = aws_sns_topic.cpu_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.email_address

  lifecycle {
    ignore_changes = [endpoint_auto_confirms]
  }
}

# ===== CloudWatch Alarm =====
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "ec2-cpu-high-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.period_seconds
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "Alert when EC2 CPU utilization exceeds ${var.cpu_threshold}% for ${var.period_seconds / 60} minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.cpu_alarm_instance.id
  }

  alarm_actions = [aws_sns_topic.cpu_alarm_topic.arn]
  ok_actions    = [aws_sns_topic.cpu_alarm_topic.arn]

  tags = {
    Name = "CPUHighAlarm"
    Lab  = "CPU-Alarm-SNS"
  }

  depends_on = [aws_sns_topic.cpu_alarm_topic]
}

# ===== Outputs =====
output "instance_id" {
  description = "EC2 Instance ID being monitored"
  value       = aws_instance.cpu_alarm_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.cpu_alarm_instance.public_ip
}

output "sns_topic_arn" {
  description = "ARN of the SNS Topic for CPU Alarms"
  value       = aws_sns_topic.cpu_alarm_topic.arn
}

output "sns_subscription_status" {
  description = "SNS subscription status (check email for confirmation)"
  value       = "Email confirmation required at: ${var.email_address}"
}

output "alarm_name" {
  description = "Name of the CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

output "cloudwatch_console_url" {
  description = "Direct link to CloudWatch Alarm in console"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#alarmsV2:alarmFilter=${aws_cloudwatch_metric_alarm.cpu_high.alarm_name}"
}

output "ec2_console_url" {
  description = "Direct link to EC2 Instance in console"
  value       = "https://console.aws.amazon.com/ec2/v2/home?region=${var.aws_region}#Instances:instanceId=${aws_instance.cpu_alarm_instance.id}"
}
