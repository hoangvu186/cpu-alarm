# CPU Alarm → Email Alert via SNS Lab

A complete hands-on AWS lab project demonstrating how to set up automated email alerts when EC2 CPU utilization exceeds 80% for 5 consecutive minutes.

## 📋 Project Contents

This repository contains multiple options to complete the lab:

### Documentation Files
- **`LAB_GUIDE.md`** - Comprehensive step-by-step guide with detailed explanations
- **`QUICK_REFERENCE.md`** - Quick reference card with checklists and troubleshooting
- **`README.md`** - This file

### Infrastructure as Code Options

#### Option 1: CloudFormation (Recommended for AWS beginners)
- **`cpu-alarm-cloudformation.yaml`** - Complete CloudFormation template
- **`deploy.sh`** - Bash deployment script (Mac/Linux)
- **`deploy.ps1`** - PowerShell deployment script (Windows)

#### Option 2: Terraform (For IaC enthusiasts)
- **`main.tf`** - Terraform configuration file
- **`terraform.tfvars.example`** - Terraform variables template
- **`user_data.sh`** - EC2 user data script

---

## 🎯 Lab Objectives

By completing this lab, you will:

✅ Understand AWS CloudWatch metrics and alarms
✅ Set up an SNS topic for notifications
✅ Configure email subscriptions
✅ Create CloudWatch alarms based on EC2 metrics
✅ Test alarm triggers with CPU load generation
✅ Understand the complete monitoring pipeline

---

## 🚀 Quick Start

### For Windows Users (Fastest Option)

```powershell
# Open PowerShell and navigate to the lab folder
cd "d:\CODING\CDO\CPU Alarm"

# Run the deployment script
.\deploy.ps1

# When prompted, enter your email address
# Script will create all resources automatically
```

### For Mac/Linux Users

```bash
# Navigate to the lab folder
cd path/to/CPU\ Alarm

# Run the deployment script
bash deploy.sh

# When prompted, enter your email address
```

### Using Terraform

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your email
nano terraform.tfvars

# Initialize, plan, and apply
terraform init
terraform plan
terraform apply
```

### Manual Setup (Learning Option)

Follow the step-by-step instructions in **`LAB_GUIDE.md`** under "Option 2: Manual Setup" to learn how each component works.

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   AWS MONITORING PIPELINE               │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  EC2 Instance                                           │
│  ├─ CPU: 85%                                            │
│  └─ Generates metrics every 60 seconds                  │
│                │                                         │
│                ↓ CloudWatch Metric Collection            │
│                                                          │
│  CloudWatch (Monitoring Service)                        │
│  ├─ Collects CPU metrics                                │
│  ├─ Stores time-series data                             │
│  └─ Evaluates against thresholds                        │
│                │                                         │
│                ↓ (CPU > 80% for 5 minutes)              │
│                                                          │
│  CloudWatch Alarm (IN_ALARM state)                      │
│  ├─ Threshold: 80%                                      │
│  ├─ Period: 5 minutes                                   │
│  └─ Triggers AlarmActions                               │
│                │                                         │
│                ↓ Publishes to SNS                        │
│                                                          │
│  SNS Topic (cpu-alarm-topic)                            │
│  ├─ Central notification hub                            │
│  ├─ Fan-out to all subscriptions                        │
│  └─ Processes messages                                  │
│                │                                         │
│                ↓ Delivers via subscribed protocols       │
│                                                          │
│  SNS Subscriptions                                      │
│  ├─ Email Subscription (your@email.com)                │
│  │  └─ Email received in inbox                          │
│  ├─ (Optional) SMS Subscription                         │
│  └─ (Optional) Lambda / SQS / HTTP                      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## ⚙️ Components Created

### EC2 Instance
- **Type:** t3.micro (free tier eligible)
- **AMI:** Amazon Linux 2
- **Security Group:** Allows SSH (22) and HTTP (80)
- **IAM Role:** CloudWatch read/write permissions
- **Pre-installed:** stress-ng for load testing

### CloudWatch Alarm
- **Name:** ec2-cpu-high-alarm
- **Metric:** CPUUtilization
- **Threshold:** 80%
- **Period:** 300 seconds (5 minutes)
- **Evaluation:** 1 datapoint
- **Actions:** SNS topic publication

### SNS Topic
- **Name:** cpu-alarm-topic
- **Type:** Standard topic
- **Subscriptions:** Email endpoint

---

## 🧪 Testing the Setup

### Step 1: Confirm SNS Subscription
1. Check your email inbox for AWS SNS confirmation
2. Click "Confirm subscription" link
3. This activates email notifications

### Step 2: Generate CPU Load

#### Using SSH (Recommended)
```bash
# SSH into the instance
ssh -i your-key.pem ec2-user@<public-ip>

# Install stress tool (already installed)
sudo yum install -y stress-ng

# Generate load on 2 CPU cores for 10 minutes
stress-ng --cpu 2 --timeout 10m

# Alternative: use yes command
yes > /dev/null &
yes > /dev/null &
```

#### Monitor Progress
```bash
# In another terminal, SSH and run:
watch -n 1 'top -b -n 1 | head -20'

# Or use aws command
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxxxx \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Step 3: Monitor CloudWatch Alarm
1. Go to CloudWatch Console
2. Navigate to Alarms section
3. Select "ec2-cpu-high-alarm"
4. Watch status change: OK → IN_ALARM
5. Check email for notification (arrives 1-2 minutes after alarm triggers)

---

## 📈 Understanding Alarm Evaluation

```
Timeline of CPU Measurements (1-minute interval):
14:00 - 45%
14:01 - 48%
14:02 - 50%
14:03 - 47%
14:04 - 49%
├─ Period ends: Average = 48% (< 80%) → OK state

14:05 - 81%
14:06 - 82%
14:07 - 85%
14:08 - 83%
14:09 - 84%
├─ Period ends: Average = 83% (> 80%) → IN_ALARM ⚠️
└─ Email sent to subscribed address

14:10 - 35%
14:11 - 32%
14:12 - 38%
14:13 - 30%
14:14 - 29%
├─ Period ends: Average = 33% (< 80%) → OK state
└─ OK notification sent (optional)
```

**Key Point:** Alarm evaluates at the END of each 5-minute period, not continuously.

---

## ❌ Troubleshooting

### Email Not Received
**Problem:** Alarm triggered but no email arrives

**Solutions:**
1. Check email spam/junk folder
2. Verify SNS subscription status:
   ```bash
   aws sns list-subscriptions-by-topic --topic-arn <topic-arn>
   ```
3. Check that subscription status is "Confirmed" (not "PendingConfirmation")
4. Resend confirmation from SNS console if needed

### Alarm Shows "INSUFFICIENT_DATA"
**Problem:** Alarm exists but shows no data

**Causes & Solutions:**
- Not enough data points collected yet
  - Solution: Wait 5-10 minutes, metrics appear gradually
- Instance has no CPU activity
  - Solution: Generate load with stress-ng
- Wrong instance selected in alarm
  - Solution: Edit alarm, select correct instance

### Alarm Never Triggers
**Problem:** CPU is high but alarm doesn't trigger

**Debugging:**
```bash
# Verify CPU is actually > 80%
ssh ec2-user@<ip> "top -bn1 | head -3"

# Check alarm configuration
aws cloudwatch describe-alarms --alarm-names ec2-cpu-high-alarm

# Look for:
# - "Threshold": 80
# - "ComparisonOperator": "GreaterThanThreshold"
# - "AlarmActions": SNS topic ARN

# Check if SNS topic exists
aws sns list-topics
```

### DNS/Network Issues
```bash
# Test EC2 instance connectivity
ping <public-ip>

# Test SSH connection
ssh -i your-key.pem ec2-user@<public-ip> "uptime"

# Get instance details
aws ec2 describe-instances --instance-ids i-xxxxx
```

---

## 📊 Viewing Metrics & Logs

### CloudWatch Metrics
```bash
# Get last 5 minutes of CPU data
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxxxx \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Minimum,Maximum
```

### Alarm History
```bash
# View alarm state changes
aws cloudwatch describe-alarm-history \
  --alarm-name ec2-cpu-high-alarm \
  --max-records 10

# View all alarms in account
aws cloudwatch describe-alarms \
  --query 'MetricAlarms[?StateValue==`ALARM`]'
```

---

## 💰 Cost Analysis

### Free Tier Limits (per month)
| Service | Limit | Cost |
|---------|-------|------|
| EC2 | 750 hours | Free |
| CloudWatch Metrics | 10 custom metrics | Free |
| CloudWatch Alarms | 10 alarms | Free |
| SNS | 1,000 email publishes | Free |

### Estimated Monthly Cost (After Free Tier)
| Component | Pricing | Usage | Cost |
|-----------|---------|-------|------|
| EC2 t3.micro | $0.0104/hour | 730 hours | $7.59 |
| CloudWatch Alarm | $0.10/alarm | 1 alarm | $0.10 |
| SNS Emails | $0.002/email | 100/month | $0.20 |
| **Total** | | | **~$8/month** |

---

## 🧹 Cleanup Instructions

### Remove All Resources

#### Using CloudFormation
```bash
# Delete the entire stack
aws cloudformation delete-stack --stack-name cpu-alarm-lab

# Wait for deletion (takes 2-3 minutes)
aws cloudformation wait stack-delete-complete --stack-name cpu-alarm-lab
```

#### Using Terraform
```bash
terraform destroy
```

#### Manual Cleanup
```bash
# Delete CloudWatch Alarm
aws cloudwatch delete-alarms --alarm-names ec2-cpu-high-alarm

# Terminate EC2 Instance
aws ec2 terminate-instances --instance-ids i-xxxxx

# Delete SNS Subscriptions
aws sns delete-subscription --subscription-arn <subscription-arn>

# Delete SNS Topic
aws sns delete-topic --topic-arn arn:aws:sns:region:account:cpu-alarm-topic

# Delete IAM Role
aws iam delete-role-policy --role-name cpu-alarm-lab-ec2-role --policy-name
aws iam delete-instance-profile --instance-profile-name cpu-alarm-lab-ec2-profile
aws iam delete-role --role-name cpu-alarm-lab-ec2-role
```

---

## 📚 Learning Resources

### AWS Documentation
- [CloudWatch User Guide](https://docs.aws.amazon.com/cloudwatch/)
- [Creating CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/Create_CloudWatch_Alarm.html)
- [SNS Developer Guide](https://docs.aws.amazon.com/sns/)
- [EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/)

### Hands-On Tutorials
- [Monitor your EC2 instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring_ec2.html)
- [Getting started with SNS](https://docs.aws.amazon.com/sns/latest/dg/getting-started.html)
- [CloudWatch Alarms Best Practices](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/Best_Practice_Recommended_Alarms_AWS_Services.html)

---

## 🎓 Key Concepts Learned

### CloudWatch
- **Metrics:** Time-series data (CPU, Memory, Disk, Network)
- **Namespaces:** Grouping for services (AWS/EC2, AWS/Lambda, etc.)
- **Dimensions:** Filters for metrics (InstanceId, FunctionName, etc.)
- **Statistics:** Aggregation types (Average, Sum, Maximum, Minimum)
- **Periods:** Time intervals for data aggregation
- **Alarms:** Conditions that trigger actions

### SNS (Simple Notification Service)
- **Topics:** Message distribution points
- **Publishers:** Services/applications sending messages
- **Subscribers:** Endpoints receiving messages
- **Subscriptions:** Links between topics and endpoints
- **Protocols:** Delivery methods (Email, SMS, Lambda, SQS, HTTP, etc.)

### EC2 Monitoring
- **Instance Metrics:** CPU, Network, Status checks
- **Metric Frequency:** Detailed (1 min) or Standard (5 min)
- **Custom Metrics:** Application-level data via CloudWatch agent
- **Logs:** System/Application logs via CloudWatch Logs

---

## 🚀 Next Steps

After completing this lab, explore:

1. **Add SMS Notifications**
   - Add phone number subscription to SNS topic
   - Test alarm triggers with SMS

2. **Create Auto-Scaling**
   - Use Lambda to automatically scale when CPU high
   - Reduce capacity when CPU low

3. **Multi-Metric Monitoring**
   - Monitor Memory, Disk, Network simultaneously
   - Create composite alarms

4. **Custom Metrics**
   - Push application metrics to CloudWatch
   - Create alarms on business metrics

5. **Advanced Notifications**
   - Only alert during business hours
   - Filter alarms by severity
   - Escalate to on-call via Lambda

6. **Dashboard Creation**
   - Build comprehensive monitoring dashboard
   - Visualize multiple metrics in one view

---

## 📝 Lab Completion Checklist

- [ ] CloudFormation stack or Terraform deployment created
- [ ] EC2 instance is running
- [ ] SNS topic created
- [ ] Email subscription confirmed
- [ ] CloudWatch alarm created and enabled
- [ ] CPU load test executed
- [ ] Email alert received when CPU > 80%
- [ ] Alarm state changed to "IN_ALARM"
- [ ] Understood the complete monitoring pipeline
- [ ] Cleaned up resources (optional)

---

## 🤝 Support & Help

### Common Issues & Solutions
See **`QUICK_REFERENCE.md`** for troubleshooting

### Detailed Walkthrough
See **`LAB_GUIDE.md`** for step-by-step instructions

### Quick Commands Reference
```bash
# View current alarms
aws cloudwatch describe-alarms --state-value ALARM

# List EC2 instances
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType]'

# Get SNS topics
aws sns list-topics

# Test SNS email
aws sns publish --topic-arn <topic-arn> --subject "Test" --message "Test notification"
```

---

## 📄 License & Attribution

This lab is based on the AWS "CPU Alarm → Email Alert via SNS" hands-on training module from AWS Mastering System Monitoring & TechTraining.

---

**Last Updated:** 2024
**Lab Status:** ✅ Complete & Ready to Deploy
