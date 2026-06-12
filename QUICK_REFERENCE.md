# CPU Alarm Lab - Quick Reference Card

## 🎯 Lab Objective
Create an automated monitoring system that sends email alerts when EC2 CPU > 80% for 5 minutes.

---

## ⚡ Quick Start (2 Methods)

### Method 1: CloudFormation (5 minutes)
```bash
# Windows PowerShell
.\deploy.ps1

# Linux/Mac Bash
bash deploy.sh
```

### Method 2: AWS Console Manual (15 minutes)
Follow steps in `LAB_GUIDE.md` under "Option 2: Manual Setup"

---

## 📊 What Gets Created

```
┌─ EC2 Instance (t3.micro) ────────────────────┐
│ • Amazon Linux 2                              │
│ • Auto-configured security group              │
│ • IAM role for CloudWatch access              │
└───────────────┬───────────────────────────────┘
                │
                ↓ CloudWatch Monitoring
┌─ CloudWatch Alarm ────────────────────────────┐
│ • Metric: CPUUtilization                      │
│ • Threshold: > 80%                            │
│ • Period: 5 minutes                           │
│ • Triggers when: CPU > 80% for 5 min          │
└───────────────┬───────────────────────────────┘
                │ sends message
                ↓
┌─ SNS Topic ───────────────────────────────────┐
│ • Notification hub                            │
│ • Routes to all subscriptions                 │
└───────────────┬───────────────────────────────┘
                │ delivers email
                ↓
┌─ Email Subscription ──────────────────────────┐
│ • Your email address                          │
│ • Requires confirmation                       │
└───────────────────────────────────────────────┘
```

---

## 🔧 Key AWS Services

| Service | Role | Cost |
|---------|------|------|
| **EC2** | Instance to monitor | Free tier: 750 hrs/month |
| **CloudWatch** | Metrics + Alarms | Free tier: 10 alarms |
| **SNS** | Email notifications | Free tier: 1,000 emails/month |
| **IAM** | Permissions | Free |

---

## 📝 Alarm Configuration Details

| Setting | Value | Purpose |
|---------|-------|---------|
| **Metric Name** | CPUUtilization | What to monitor |
| **Namespace** | AWS/EC2 | Service providing metric |
| **Statistic** | Average | Use average (not Peak) |
| **Period** | 300 seconds | Evaluate every 5 minutes |
| **Threshold** | 80 | CPU % limit |
| **Comparison** | Greater Than | Alert if CPU > 80% |
| **Evaluation Periods** | 1 | Check 1 period |
| **Datapoints to Alarm** | 1 out of 1 | Trigger if 1/1 breaches |
| **Treat Missing Data** | Not Breaching | Don't alert if no data |

---

## 🧪 Testing the Alarm

### Step 1: Generate CPU Load
```bash
# SSH into EC2 instance
ssh -i your-key.pem ec2-user@<instance-ip>

# Install stress tool
sudo yum install -y stress-ng

# Run for 10 minutes
stress-ng --cpu 2 --timeout 10m
```

### Step 2: Monitor CloudWatch
1. Open: https://console.aws.amazon.com/cloudwatch/
2. Go to: Alarms → Select your alarm
3. Watch status change: OK → IN_ALARM
4. Email arrives within 1-2 minutes

### Step 3: Verify Email
- Check inbox for: `AWS Notification - ec2-cpu-high-alarm`
- Confirm SNS subscription (if not already done)

---

## 📈 Understanding the Flow

```
TIME  │  CPU %  │  PERIOD AVERAGE  │  ALARM STATE
──────┼─────────┼──────────────────┼──────────────
14:00 │   45%   │       -          │  OK
14:01 │   48%   │       -          │  OK
14:02 │   50%   │       -          │  OK
14:03 │   47%   │       -          │  OK
14:04 │   49%   │       -          │  OK
14:05 │   48%   │    48% (< 80%)   │  OK
14:06 │   81%   │       -          │  OK
14:07 │   82%   │       -          │  OK
14:08 │   85%   │       -          │  OK
14:09 │   83%   │       -          │  OK
14:10 │   84%   │    83% (> 80%)   │  IN_ALARM ⚠️ EMAIL SENT
```

**Key Point:** Alarm evaluates AFTER 5-minute period completes

---

## ✅ Verification Checklist

- [ ] CloudFormation stack status: CREATE_COMPLETE
- [ ] EC2 instance running (visible in EC2 console)
- [ ] CloudWatch alarm exists with correct metric
- [ ] SNS topic created and has 1 subscription
- [ ] Email subscription status: Confirmed
- [ ] Received confirmation email from AWS SNS
- [ ] Test email from SNS console (optional)

---

## ❌ Troubleshooting

### Not Receiving Confirmation Email
```bash
# Check SNS subscription status
aws sns list-subscriptions-by-topic --topic-arn <topic-arn>

# Look for: "SubscriptionArn": "PendingConfirmation"
```

**Solution:** Check email spam folder, resend confirmation if needed

### Alarm Shows "Insufficient Data"
- **Cause:** Not enough metrics collected yet
- **Solution:** Wait 5-10 minutes, metrics appear gradually

### Alarm Never Triggers
- **Check 1:** Is CPU actually > 80%?
  ```bash
  # SSH into instance and run: top
  # Verify CPU column shows > 80%
  ```
- **Check 2:** Is SNS action configured?
  ```bash
  aws cloudwatch describe-alarms --alarm-names ec2-cpu-high-alarm
  # Look for: "AlarmActions": ["arn:aws:sns:..."]
  ```

---

## 📍 Console Shortcuts

| Service | Console URL | What To Check |
|---------|------------|---|
| **EC2** | https://console.aws.amazon.com/ec2/ | Instance running, IP address |
| **CloudWatch Alarms** | https://console.aws.amazon.com/cloudwatch/home#alarmsV2: | Alarm status, metric data |
| **SNS Topics** | https://console.aws.amazon.com/sns/v3/home | Topic exists, subscriptions |
| **IAM** | https://console.aws.amazon.com/iam/ | Role attached to instance |

---

## 🎓 Learning Outcomes

After this lab, you understand:
- ✅ How CloudWatch collects and evaluates metrics
- ✅ How alarms trigger based on thresholds
- ✅ How SNS distributes notifications
- ✅ Email subscription confirmation workflow
- ✅ How to test monitoring in AWS

---

## 💰 Cost Breakdown (Monthly)

| Component | Pricing | Estimated |
|-----------|---------|-----------|
| EC2 (t3.micro) | $0.0104/hour | $7.50/month |
| CloudWatch Alarms | Free tier: 10 | $0 |
| SNS Emails | Free tier: 1,000 | $0 |
| **Total (with free tier)** | | **$0** |
| **Total (after free tier)** | | **~$8/month** |

---

## 🧹 Cleanup

### Option 1: Delete Stack (All Resources)
```bash
aws cloudformation delete-stack --stack-name cpu-alarm-lab
```

### Option 2: Manual Delete
1. EC2: Terminate instance
2. CloudWatch: Delete alarm
3. SNS: Delete subscription & topic
4. IAM: Delete role

---

## 📚 Additional Resources

- [AWS CloudWatch Docs](https://docs.aws.amazon.com/cloudwatch/)
- [AWS SNS Docs](https://docs.aws.amazon.com/sns/)
- [EC2 Monitoring](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring_ec2.html)
- [CloudWatch Alarms Best Practices](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/Best_Practice_Recommended_Alarms_AWS_Services.html)

---

## 🚀 Next Challenges

1. **Add SMS notification** - Add phone number subscription to SNS topic
2. **Create recovery action** - Use Lambda to auto-scale when CPU high
3. **Multi-metric dashboard** - Monitor CPU, Memory, Disk together
4. **Notification filtering** - Only alert during business hours
5. **Custom metrics** - Application-level metrics from code
