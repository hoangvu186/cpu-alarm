# CPU Alarm Lab - Implementation Checklist & Worksheet

Use this document to track your progress through the lab.

---

## Phase 1: Pre-Deployment Setup

### Prerequisites Check
- [ ] AWS account created and activated
- [ ] AWS CLI installed (`aws --version` works)
- [ ] AWS credentials configured (`aws sts get-caller-identity` succeeds)
- [ ] Email address ready for SNS confirmation
- [ ] SSH key pair created in your region (if using manual setup)

### Environment Setup
- [ ] Region selected: `________________` (default: us-east-1)
- [ ] AWS credentials verified working
- [ ] CloudFormation or Terraform chosen as deployment method

---

## Phase 2: Deployment

### Option 1: CloudFormation (Recommended)

#### Using PowerShell (Windows)
```
Steps:
1. [ ] Open PowerShell in admin mode
2. [ ] Navigate to: d:\CODING\CDO\CPU Alarm
3. [ ] Run: .\deploy.ps1
4. [ ] Enter email when prompted: ________________
5. [ ] Wait for stack creation (5-10 minutes)
6. [ ] Status shows: ✓ CREATE_COMPLETE
```

#### Using Bash (Mac/Linux)
```
Steps:
1. [ ] Open Terminal
2. [ ] Navigate to lab folder
3. [ ] Run: bash deploy.sh
4. [ ] Enter email when prompted: ________________
5. [ ] Wait for stack creation
6. [ ] Status shows: ✓ CREATE_COMPLETE
```

#### Output Notes
```
Stack Name: ________________________________________
Region: __________________________________________
Instance ID: _______________________________________
SNS Topic ARN: _____________________________________
Public IP: _________________________________________
```

### Option 2: Terraform

```
Steps:
1. [ ] Copy terraform.tfvars.example to terraform.tfvars
2. [ ] Edit terraform.tfvars with your email
3. [ ] Run: terraform init
4. [ ] Run: terraform plan (review changes)
5. [ ] Run: terraform apply (confirm with 'yes')
6. [ ] Wait for resource creation (5-10 minutes)
```

#### Output Notes
```
Instance ID: _______________________________________
Instance Public IP: _________________________________
SNS Topic ARN: _____________________________________
```

### Option 3: Manual Setup

```
Steps:
1. [ ] Follow LAB_GUIDE.md "Option 2: Manual Setup"
2. [ ] Complete: Step 1 - SNS Topic & Subscription
3. [ ] Complete: Step 2 - EC2 Instance Creation
4. [ ] Complete: Step 3 - CloudWatch Alarm Creation
5. [ ] Complete: Step 4 - SNS Action Configuration
```

#### Resources Created
```
EC2 Instance ID: ___________________________________
SNS Topic ARN: _____________________________________
CloudWatch Alarm Name: ______________________________
Email Subscribed: ___________________________________
```

---

## Phase 3: Email Confirmation

### SNS Subscription Confirmation

```
1. [ ] Check email inbox (may take 1-2 minutes)
2. [ ] Look for: "AWS Notification - Request to confirm Amazon SNS subscription"
3. [ ] Open email and click: "Confirm subscription"
4. [ ] You'll see confirmation page
5. [ ] Subscription status changed to: "Confirmed"
```

#### Notes
```
Confirmation email sent to: _________________________
Confirmation completed at: __________________________
Any issues? ________________________________________
```

---

## Phase 4: Verification & Testing

### CloudFormation/Stack Verification

```bash
Step 1: Verify EC2 Instance Running
# Command to run:
aws ec2 describe-instances --instance-ids i-xxxxx --query 'Reservations[0].Instances[0].[InstanceId,State.Name,InstanceType,PublicIpAddress]'

Result:
Instance ID: _________________ State: _______________
Type: ______________________ IP: ___________________
```

```bash
Step 2: Verify CloudWatch Alarm
# Command to run:
aws cloudwatch describe-alarms --alarm-names ec2-cpu-high-alarm

Result:
Alarm Name: _________________ Threshold: __________
Metric: ______________________ State: _______________
```

```bash
Step 3: Verify SNS Topic & Subscription
# Command to run:
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:region:account:cpu-alarm-topic

Result:
Topic ARN: ___________________________________________
Subscription Status: _______________________________
Subscription Endpoint: ______________________________
```

### Connection Test

```
1. [ ] SSH into EC2 instance
   Command: ssh -i your-key.pem ec2-user@<public-ip>
   
2. [ ] Verify internet connectivity
   Command: ping 8.8.8.8
   Result: ____________________________________________
   
3. [ ] Check CloudWatch agent installed
   Command: which amazon-cloudwatch-agent
   Result: ____________________________________________
   
4. [ ] Check stress-ng installed
   Command: which stress-ng
   Result: ____________________________________________
```

---

## Phase 5: Load Testing & Alarm Trigger

### Generate CPU Load

#### Method 1: Using stress-ng (Recommended)

```bash
# SSH into instance
ssh -i your-key.pem ec2-user@<public-ip>

# Option A: Stress for 10 minutes
stress-ng --cpu 2 --timeout 10m

# Option B: Stress for 5 minutes with verbose output
stress-ng --cpu 2 --timeout 5m --verbose

# Option C: Manual load (leave running in background)
yes > /dev/null &
yes > /dev/null &
```

#### Notes
```
Load start time: ____________________________________
Load method used: ___________________________________
Stress duration: ____________________________________
CPU cores stressed: _________________________________
```

### Monitor CPU in Real-Time

#### Option 1: SSH into Instance (Recommended)

```bash
# Run top command
top

# Output shows:
CPU %user: __________ %system: __________ %idle: __________
Processes running: __________________________________
```

#### Option 2: CloudWatch Console

```
1. [ ] Open: https://console.aws.amazon.com/cloudwatch/
2. [ ] Go to: Alarms → ec2-cpu-high-alarm
3. [ ] Watch Graph tab for CPU spike
4. [ ] Note the timestamp when CPU > 80%
5. [ ] Note when alarm state changes to ALARM
```

#### Observations
```
Timestamp CPU exceeded 80%: __________________________
How long to reach 80%: _______________________________
Timestamp alarm triggered: ___________________________
Time between CPU spike and alarm: ____________________
```

### Email Alert Reception

```
1. [ ] Check email inbox
2. [ ] Look for: From: aws-notifications@sns.amazonaws.com
3. [ ] Subject: "AWS Notification Message"
4. [ ] Email contains alarm details:
   - Alarm Name: _____________________________________
   - Reason: __________________________________________
   - State: ___________________________________________
   - Instance ID: ____________________________________
   
5. [ ] Email received at (time): _____________________
6. [ ] Time from alarm trigger to email: ____________
```

#### Email Content Verification
```
Check email contains:
- [ ] AlarmName: ec2-cpu-high-alarm
- [ ] StateChangeTime: (valid timestamp)
- [ ] NewStateValue: ALARM
- [ ] StateReason: (mentions threshold)
- [ ] Trigger details with metrics
```

### Stop the Load

```bash
# SSH into instance and run:

# Option 1: Kill stress-ng
killall stress-ng

# Option 2: Kill yes command
killall yes

# Verify CPU returns to normal
top
# CPU usage should drop significantly
```

#### Post-Load Observations
```
Time stopped: _______________________________________
Time for CPU to drop: _______________________________
Alarm state after 5 min: ____________________________
Recovery email received: [ ] Yes [ ] No
```

---

## Phase 6: Advanced Testing (Optional)

### Test 1: Manual SNS Notification

```bash
# Publish manual test message
aws sns publish \
  --topic-arn <topic-arn> \
  --subject "Alarm Test" \
  --message "This is a test notification"

Expected: Email arrives within 1 minute
```

### Test 2: Create Dashboard

```
1. [ ] CloudWatch → Dashboards → Create New
2. [ ] Add widget → Metric
3. [ ] Select: EC2 → CPUUtilization
4. [ ] Select your instance
5. [ ] Set time range: Last 30 minutes
6. [ ] Save dashboard as: cpu-alarm-lab-dashboard
```

### Test 3: View Alarm History

```bash
# Get alarm state change history
aws cloudwatch describe-alarm-history \
  --alarm-name ec2-cpu-high-alarm \
  --max-records 20

Results:
- [ ] Shows ALARM → OK transition
- [ ] Timestamps match observations
- [ ] State reasons visible
```

---

## Phase 7: Cleanup & Documentation

### Resource Teardown

#### If Using CloudFormation/Terraform
```bash
# Delete all resources at once

CloudFormation:
aws cloudformation delete-stack --stack-name cpu-alarm-lab

Terraform:
terraform destroy
```

#### Manual Cleanup
```bash
Deletions needed:
- [ ] CloudWatch Alarm: ec2-cpu-high-alarm
- [ ] EC2 Instance: (instance ID)
- [ ] SNS Subscription: (subscription ARN)
- [ ] SNS Topic: cpu-alarm-topic
- [ ] Security Group: cpu-alarm-lab-sg
- [ ] IAM Role: cpu-alarm-lab-ec2-role
```

### Documentation Recording

```
Lessons Learned:
__________________________________________________________________
__________________________________________________________________
__________________________________________________________________

Challenges Encountered:
__________________________________________________________________
__________________________________________________________________
__________________________________________________________________

Key Insights:
__________________________________________________________________
__________________________________________________________________
__________________________________________________________________

Time Summary:
- Deployment: ____________ minutes
- Testing: ____________ minutes
- Total: ____________ minutes
```

---

## Phase 8: Completion Summary

### Lab Completion Status

```
✓ Deployment
- [ ] Stack/Infrastructure created successfully
- [ ] All resources visible in AWS console
- [ ] No errors during creation

✓ Configuration
- [ ] EC2 instance running
- [ ] CloudWatch alarm configured correctly
- [ ] SNS topic and subscription created
- [ ] Email confirmation completed

✓ Testing
- [ ] CPU load generated successfully
- [ ] Alarm transitioned to IN_ALARM state
- [ ] Email notification received
- [ ] Email content verified
- [ ] Alarm returned to OK state

✓ Monitoring
- [ ] CloudWatch metrics visible
- [ ] Alarm history complete
- [ ] All logs accessible

✓ Cleanup (if applicable)
- [ ] Resources deleted
- [ ] No lingering charges
```

### Final Verification

```bash
# Confirm all resources deleted
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId]' --filters "Name=tag:Lab,Values=CPU-Alarm-SNS"
# Should return: empty results

aws cloudwatch describe-alarms --alarm-names ec2-cpu-high-alarm
# Should return: No alarms found

aws sns list-topics
# cpu-alarm-topic should not be listed
```

### Lab Grade

```
Criteria                          Met    Partial  Not Met
────────────────────────────────────────────────────────
All resources deployed              [ ]     [ ]      [ ]
Resources configured correctly      [ ]     [ ]      [ ]
CPU load generated                  [ ]     [ ]      [ ]
Alarm triggered properly            [ ]     [ ]      [ ]
Email alert received                [ ]     [ ]      [ ]
Troubleshooting attempted           [ ]     [ ]      [ ]
Documentation completed             [ ]     [ ]      [ ]
Resources cleaned up                [ ]     [ ]      [ ]

Overall Completion: ___________%
```

---

## Troubleshooting Log

Use this section to document any issues encountered:

### Issue #1
```
Date/Time: __________________________________
Problem: ____________________________________
Error Message: ______________________________
Resolution Attempted: _______________________
Resolution Result: ___________________________
Reference: LAB_GUIDE.md section ______________
```

### Issue #2
```
Date/Time: __________________________________
Problem: ____________________________________
Error Message: ______________________________
Resolution Attempted: _______________________
Resolution Result: ___________________________
Reference: QUICK_REFERENCE.md section ________
```

### Issue #3
```
Date/Time: __________________________________
Problem: ____________________________________
Error Message: ______________________________
Resolution Attempted: _______________________
Resolution Result: ___________________________
Reference: _________________________________
```

---

## Next Steps & Advanced Topics

After completing this lab, explore:

```
Advanced Topics:
- [ ] Add SMS notification channel to SNS
- [ ] Create Lambda function triggered by alarm
- [ ] Build CloudWatch dashboard
- [ ] Set up SNS -> SQS for application integration
- [ ] Create composite alarms
- [ ] Implement Auto Scaling based on alarms
- [ ] Add custom application metrics
- [ ] Set up cross-region monitoring

Resources to Study:
- [ ] SNS message filtering
- [ ] CloudWatch Logs Insights
- [ ] EventBridge integration
- [ ] AWS Systems Manager automation
- [ ] Cost optimization strategies
```

---

## Sign-Off

```
Lab Completed By: _______________________________
Completion Date: ________________________________
Email: __________________________________________
Notes: __________________________________________
____________________________________________________
```

---

**Save this worksheet for your records and future reference!**
