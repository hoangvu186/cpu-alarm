# CPU Alarm → Email Alert via SNS - Complete Lab Guide

## Lab Objective
Create an automated monitoring system that sends email alerts when an EC2 instance's CPU utilization exceeds 80% for 5 consecutive minutes.

---

## Architecture Overview

```
EC2 Instance
     ↓
CloudWatch Monitoring (reads CPU metrics)
     ↓
CloudWatch Alarm (evaluates CPU > 80% for 5 min)
     ↓
SNS Topic (notification hub)
     ↓
SNS Subscription (email)
     ↓
Your Email Inbox
```

---

## Deployment Options

### Option 1: Using CloudFormation (Automated - Recommended)

#### Step 1: Deploy the Stack

1. **Open AWS CloudFormation Console**
   - Go to: https://console.aws.amazon.com/cloudformation/

2. **Create New Stack**
   - Click "Create Stack" → "With new resources"
   - Choose "Upload a template file"
   - Upload: `cpu-alarm-cloudformation.yaml`

3. **Configure Stack Details**
   - Stack name: `cpu-alarm-lab`
   - Parameters:
     - EmailAddress: Enter your email (e.g., your.email@example.com)
     - CPUThreshold: 80 (default)
     - EvaluationPeriods: 1 (default)
     - DatapointsToAlarm: 1 (default)

4. **Review and Create**
   - Click "Next" through all pages
   - Check "I acknowledge that AWS CloudFormation might create IAM resources"
   - Click "Create Stack"

5. **Wait for Stack Creation**
   - Monitor the "Events" tab
   - Status should change to CREATE_COMPLETE (~5 minutes)

6. **Confirm SNS Subscription**
   - Check your email inbox for AWS SNS confirmation
   - Click the confirmation link in the email
   - This activates email notifications

#### What Gets Created:
- ✅ 1 EC2 instance (t3.micro, Amazon Linux 2)
- ✅ 1 Security Group (SSH and HTTP access)
- ✅ 1 IAM Role (CloudWatch permissions)
- ✅ 1 SNS Topic (notification hub)
- ✅ 1 SNS Email Subscription
- ✅ 1 CloudWatch Alarm (CPU monitoring)

---

### Option 2: Manual Setup (Learning - Step by Step)

#### Step 1: Create SNS Topic & Subscription

1. **Navigate to SNS Console**
   - https://console.aws.amazon.com/sns/

2. **Create Topic**
   - Click "Create Topic"
   - Type: Standard
   - Name: `cpu-alarm-topic`
   - Click "Create Topic"
   - Copy the Topic ARN (format: `arn:aws:sns:region:account:cpu-alarm-topic`)

3. **Create Email Subscription**
   - Click "Create Subscription"
   - Protocol: `Email`
   - Endpoint: Your email address
   - Click "Create Subscription"

4. **Confirm Subscription**
   - Check your email for AWS Notification confirmation
   - Click "Confirm subscription" link
   - You'll see success page

**Why This Matters:**
- **SNS Topic** = Central hub for notifications (like a message broker)
- **Email Subscription** = Endpoint that receives messages
- **Confirmation** = AWS verifies you own the email

---

#### Step 2: Create EC2 Instance to Monitor

1. **Navigate to EC2 Console**
   - https://console.aws.amazon.com/ec2/

2. **Launch Instance**
   - Click "Launch Instances"
   - AMI: Amazon Linux 2 (free tier eligible)
   - Instance Type: t3.micro
   - Security Group: Allow SSH (port 22) and HTTP (port 80)

3. **Note the Instance ID**
   - Format: `i-0123456789abcdef0`
   - You'll need this for the alarm

**Why This Matters:**
- CloudWatch needs an actual EC2 instance to monitor
- Metrics are collected every 60 seconds by default

---

#### Step 3: Create CloudWatch Alarm

1. **Navigate to CloudWatch Console**
   - https://console.aws.amazon.com/cloudwatch/

2. **Go to Alarms**
   - Click "Alarms" → "Create Alarm"

3. **Select Metric**
   - Click "Select metric"
   - Browse: EC2 → Per-Instance Metrics
   - Find your instance → Select `CPUUtilization`
   - Click "Select metric"

4. **Configure Alarm Conditions**
   - Metric: CPUUtilization
   - Statistic: Average
   - Period: 300 seconds (5 minutes)
   - Threshold: Greater than 80
   - Datapoints to Alarm: 1 out of 1
   - Treat Missing Data: Not breaching

5. **Configure Actions**
   - Alarm state trigger: IN_ALARM
   - SNS Topic: Select your `cpu-alarm-topic`
   - Add another action for OK state (optional)

6. **Name and Create**
   - Alarm name: `ec2-cpu-high-alarm`
   - Alarm description: `Alert when EC2 CPU exceeds 80% for 5 minutes`
   - Click "Create alarm"

**Detailed Explanation of Settings:**

| Setting | Value | Why |
|---------|-------|-----|
| **Period** | 300 seconds | Data point = 5-minute average |
| **Evaluation Periods** | 1 | Check 1 period before alarming |
| **Threshold** | 80% | CPU limit |
| **Comparison** | Greater than | Alert if CPU > 80% |
| **Datapoints to Alarm** | 1 | Trigger if 1 out of 1 breaches |
| **Statistic** | Average | Use average CPU (not peak) |

**Flow When CPU Exceeds Threshold:**
```
1. CloudWatch collects CPU metrics (per minute)
2. At end of 5-minute period, calculates average
3. If average > 80%, triggers alarm state
4. Alarm sends message to SNS topic
5. SNS delivers email to you
```

---

## Testing the Setup

### Method 1: Generate CPU Load (On the EC2 Instance)

1. **SSH into your EC2 instance**
   ```bash
   ssh -i your-key.pem ec2-user@<public-ip>
   ```

2. **Install stress tool**
   ```bash
   sudo yum install -y stress-ng
   ```

3. **Generate CPU load**
   ```bash
   # Run for 10 minutes with 2 cores at 100%
   stress-ng --cpu 2 --timeout 10m
   ```

4. **Monitor in CloudWatch**
   - Go to CloudWatch → Alarms
   - Watch alarm status change to "IN ALARM"
   - Check your email (arrives within 1-2 minutes)

### Method 2: Test SNS Notification (Manual)

1. **Go to SNS Console**
   - Select your topic → "Publish message"
   - Subject: "Test"
   - Message: "Test alarm notification"
   - Click "Publish"

2. **You'll receive email immediately**
   - Confirms email subscription is working

---

## CloudWatch Alarm States

```
┌─────────────────────────────────────────────────────────┐
│                  ALARM STATE LIFECYCLE                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  OK STATE (Green)                                        │
│  └─ CPU < 80%                                            │
│     └─ All metrics within threshold                      │
│        └─ No action triggered                            │
│                                                          │
│         ↓ (CPU spikes to > 80%)                          │
│                                                          │
│  INSUFFICIENT_DATA STATE (Grey)                          │
│  └─ Not enough data points to evaluate                   │
│     └─ Can occur on first deployment                     │
│                                                          │
│         ↓ (Data collected, threshold breached)           │
│                                                          │
│  IN_ALARM STATE (Red) ★ EMAIL SENT ★                    │
│  └─ CPU ≥ 80% for 5 minutes                              │
│     └─ SNS notification triggered                        │
│        └─ Email delivered to subscription                │
│                                                          │
│         ↓ (CPU drops below 80%)                          │
│                                                          │
│  OK STATE (returns)                                      │
│  └─ OK action SNS notification sent (optional)           │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Monitoring Dashboard

### View Alarm in Console

1. **CloudWatch Dashboard**
   - Home → Dashboards → Create Dashboard
   - Add widget: Metric → EC2 → CPUUtilization
   - Select your instance
   - Click "Create Dashboard"

2. **Real-time CPU Monitoring**
   - Graph shows CPU over time
   - Red line at 80% threshold
   - Alarm status indicator

### View Alarm History

1. **CloudWatch Alarms Page**
   - Select your alarm
   - View "History" tab
   - See all state changes and triggers

---

## Troubleshooting

### ❌ Not Receiving Emails

**Problem:** Alarm is IN_ALARM but no email received

1. **Confirm SNS Subscription**
   - SNS Console → Topic → Subscriptions
   - Status should be "Confirmed"
   - If "PendingConfirmation", check email spam folder

2. **Check SNS Permissions**
   - Make sure email address is correct
   - Try manual publish from SNS console first

3. **Check Alarm Configuration**
   - Alarm → Edit
   - Verify SNS topic is selected in actions

### ❌ Alarm Never Triggers

**Problem:** CPU load generated but alarm doesn't trigger

1. **Check Metric Data**
   - CloudWatch → Metrics → EC2 → CPUUtilization
   - Select your instance
   - Verify data points appear (may take 1-2 minutes)

2. **Verify Threshold**
   - Alarm → Edit → Threshold value = 80?
   - Comparison = "Greater than"?

3. **Wait for Data**
   - Need 5 minutes of CPU > 80% before alarming
   - First 5 minutes may show INSUFFICIENT_DATA

### ❌ Wrong Instance Being Monitored

**Problem:** Alarm created but monitoring wrong instance

1. **Edit Alarm**
   - CloudWatch → Alarms → Select alarm
   - Click "Edit" → "Metric"
   - Select correct Instance ID

---

## Cost Considerations

### EC2 (t3.micro)
- Free tier: 750 hours/month
- Beyond free tier: ~$0.0104/hour

### CloudWatch
- Metrics: 10 custom metrics free
- Alarms: 10 alarms free
- Beyond: $0.10 per alarm/month

### SNS
- Email: Free (Amazon SNS free tier)
- Requests: 1,000/month free

**For this lab:** Entirely within AWS free tier if you have remaining free tier hours

---

## Architecture Deep Dive

### How CloudWatch Alarm Works

```
STEP 1: Data Collection (Every 60 seconds)
┌──────────────────────────────────────────┐
│ EC2 Instance publishes CPUUtilization    │
│ Metric value: e.g., 45%                  │
└──────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────┐
│ CloudWatch receives metric data          │
│ Time: 2024-01-15 14:00:00 UTC            │
│ Namespace: AWS/EC2                       │
│ MetricName: CPUUtilization               │
│ Dimension: InstanceId=i-12345            │
│ Value: 45%                               │
└──────────────────────────────────────────┘

STEP 2: Period Aggregation (Every 5 minutes)
┌──────────────────────────────────────────┐
│ 14:00:00 → 45%                           │
│ 14:01:00 → 48%                           │
│ 14:02:00 → 50%                           │
│ 14:03:00 → 47%                           │
│ 14:04:00 → 49%                           │
│ ──────────────                           │
│ Average = 48%  (NOT > 80%, OK)           │
└──────────────────────────────────────────┘

STEP 3: Evaluation (When threshold reached)
┌──────────────────────────────────────────┐
│ 14:05:00 → 81%                           │
│ 14:06:00 → 82%                           │
│ 14:07:00 → 85%                           │
│ 14:08:00 → 83%                           │
│ 14:09:00 → 84%                           │
│ ──────────────                           │
│ Average = 83%  (> 80%, ALARM!)           │
└──────────────────────────────────────────┘

STEP 4: Action Execution
┌──────────────────────────────────────────┐
│ Alarm enters IN_ALARM state              │
│ Triggers all AlarmActions                │
│ Publishes message to SNS topic           │
└──────────────────────────────────────────┘

STEP 5: SNS Distribution
┌──────────────────────────────────────────┐
│ SNS Topic receives message from CloudWatch
│ Topic Name: cpu-alarm-topic              │
│ Message includes:                        │
│ - Alarm Name: ec2-cpu-high-alarm         │
│ - Reason: Threshold Crossed              │
│ - StateChangeTime: timestamp             │
│ - NewStateValue: ALARM                   │
│ - Instance ID: i-12345                   │
└──────────────────────────────────────────┘

STEP 6: Email Delivery
┌──────────────────────────────────────────┐
│ SNS delivers to all Subscriptions        │
│ Subscription Protocol: Email             │
│ Email arrives in inbox                   │
│ From: aws-notifications@sns.amazonaws.com│
│ Subject: AWS Notification Message        │
│ Body: Formatted alarm details            │
└──────────────────────────────────────────┘
```

### SNS Topic vs Subscription

```
┌─────────────────────────────────────────────┐
│           SNS Topic (Hub)                   │
│  arn:aws:sns:region:account:cpu-alarm      │
│                                             │
│  Receives messages from:                    │
│  • CloudWatch Alarms                        │
│  • Lambda functions                         │
│  • Other AWS services                       │
│                                             │
└─────────────────────────────────────────────┘
           ↓ Fan-out ↓
┌──────────────┬──────────────┬──────────────┐
│              │              │              │
│ Subscription │ Subscription │ Subscription │
│ Email        │ SMS          │ Lambda       │
│ your@email   │ +1-555-1234  │ function-arn │
│              │              │              │
└──────────────┴──────────────┴──────────────┘
```

For this lab, we only have 1 email subscription, but SNS can route to unlimited endpoints.

---

## Cleanup (When Done)

### Using CloudFormation
```bash
# Delete entire stack (removes all resources)
aws cloudformation delete-stack --stack-name cpu-alarm-lab --region us-east-1
```

### Manual Cleanup
1. **EC2 Instance:** Terminate instance
2. **SNS:** Delete subscription and topic
3. **CloudWatch:** Delete alarm
4. **IAM:** Delete role if manually created

---

## Key Learnings

✅ **CloudWatch** monitors AWS resources and collects metrics
✅ **CloudWatch Alarms** evaluate metrics against thresholds
✅ **SNS Topics** are notification hubs for AWS services
✅ **Subscriptions** connect topics to delivery endpoints (email, SMS, Lambda, etc.)
✅ **Periods** determine data aggregation intervals
✅ **Evaluation Periods** determine how many periods trigger alarm
✅ **Threshold** is the condition that triggers the alarm

---

## Next Steps

After completing this lab:
1. Create alarms for other metrics (Network, Disk, Memory)
2. Add Lambda function subscription to auto-remediate high CPU
3. Create custom metrics from application code
4. Set up SNS SMS notifications for critical alarms
5. Create dashboard for multiple alarms
