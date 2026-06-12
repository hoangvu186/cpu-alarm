# CPU Alarm Lab - File Index & Navigation Guide

## 📂 Project Structure

```
CPU Alarm/
├── README.md                              ← Start here!
├── LAB_GUIDE.md                          ← Detailed walkthrough
├── QUICK_REFERENCE.md                    ← Quick lookup & troubleshooting
├── IMPLEMENTATION_CHECKLIST.md           ← Track your progress
├── INDEX.md                              ← This file
│
├── Deployment Scripts (Choose One Method)
│   ├── deploy.ps1                        ← For Windows (PowerShell)
│   └── deploy.sh                         ← For Mac/Linux (Bash)
│
├── CloudFormation (Recommended for AWS beginners)
│   ├── cpu-alarm-cloudformation.yaml    ← Complete template
│   └── user_data.sh                      ← EC2 initialization script
│
└── Terraform (For IaC enthusiasts)
    ├── main.tf                           ← Terraform configuration
    ├── terraform.tfvars.example          ← Variables template
    └── user_data.sh                      ← EC2 initialization script
```

---

## 🗺️ Reading Guide

### If You're Starting Now...

**Option A: Quick Deploy (Recommended)**
1. Read: [README.md](README.md) (5 min)
2. Run: `.\deploy.ps1` or `bash deploy.sh` (1 min)
3. Wait: Stack creation (5-10 min)
4. Reference: [QUICK_REFERENCE.md](QUICK_REFERENCE.md) as needed

**Option B: Want to Understand Everything First**
1. Read: [LAB_GUIDE.md](LAB_GUIDE.md) - Complete guide with architecture (30 min)
2. Choose deployment method
3. Execute step by step

**Option C: Learning with Hands-On**
1. Read: [LAB_GUIDE.md](LAB_GUIDE.md) - "Option 2: Manual Setup" (45 min)
2. Follow each step in AWS console
3. Use [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) to track progress

---

## 📖 Document Descriptions

### Core Documentation

#### [README.md](README.md) - **START HERE** ⭐
- **Purpose:** Complete project overview and quick reference
- **Length:** 15-20 minutes reading
- **Contains:**
  - Lab objectives and architecture diagram
  - Quick start instructions for all OS
  - Complete troubleshooting guide
  - Cost analysis
  - Cleanup instructions

#### [LAB_GUIDE.md](LAB_GUIDE.md) - **THE TEXTBOOK**
- **Purpose:** Comprehensive step-by-step guide with deep explanations
- **Length:** 1 hour reading + 1 hour execution
- **Contains:**
  - Architecture overview with detailed diagrams
  - Two deployment options (CloudFormation and Manual)
  - Detailed explanation of every setting
  - Testing procedures
  - Alarm state lifecycle
  - Cost considerations
  - Troubleshooting with solutions

#### [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - **YOUR CHEAT SHEET**
- **Purpose:** Quick lookup for commands, commands, and common issues
- **Length:** 5-10 minutes reference
- **Contains:**
  - Quick start commands
  - Architecture diagram
  - Component summary table
  - Testing steps
  - Troubleshooting checklist
  - Console shortcuts
  - Cost breakdown

#### [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) - **TRACKING SHEET**
- **Purpose:** Track progress through the entire lab
- **Length:** Interactive checklist
- **Contains:**
  - Pre-deployment checklist
  - Phase-by-phase tracking
  - Output notes for reference
  - Troubleshooting log
  - Completion verification

---

## 🚀 Deployment Method Selection

### Method 1: CloudFormation (Recommended)

#### Files Used:
- `cpu-alarm-cloudformation.yaml` - Infrastructure definition
- `deploy.ps1` or `deploy.sh` - Automated deployment

#### When to Use:
- First time with AWS
- Want fully automated setup
- Need quick deployment (5-10 minutes)
- Prefer native AWS service

#### Getting Started:
```bash
# Windows
.\deploy.ps1

# Mac/Linux
bash deploy.sh
```

#### Read First:
1. [README.md](README.md) - 5 min overview
2. [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Quick commands

---

### Method 2: Terraform

#### Files Used:
- `main.tf` - Infrastructure definition
- `terraform.tfvars.example` - Variables template
- `user_data.sh` - EC2 initialization

#### When to Use:
- Familiar with Infrastructure as Code
- Need multi-cloud capability
- Want reusable, version-controlled infra
- Prefer Terraform syntax

#### Getting Started:
```bash
# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your email

# Deploy
terraform init
terraform plan
terraform apply
```

#### Read First:
1. [README.md](README.md) - Project overview
2. `main.tf` - Review configuration
3. [LAB_GUIDE.md](LAB_GUIDE.md) - Option 1 section

---

### Method 3: Manual Setup

#### Files Used:
- None (pure AWS Console)
- Optional: [LAB_GUIDE.md](LAB_GUIDE.md) for reference

#### When to Use:
- Want to learn how each piece works
- Exploring AWS console manually
- Understanding alarm configuration in detail
- Educational purposes

#### Getting Started:
1. Read: [LAB_GUIDE.md](LAB_GUIDE.md) - "Option 2: Manual Setup" (Section 2)
2. Follow each step in AWS console
3. Use [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) to track

---

## 📋 Common Use Cases

### "I want to deploy this NOW"
```
1. Run: .\deploy.ps1 (or bash deploy.sh)
2. Enter your email
3. Wait 5-10 minutes
4. Check email for confirmation
5. Reference: QUICK_REFERENCE.md for testing
```

### "I want to understand what I'm doing"
```
1. Read: LAB_GUIDE.md (30 min)
2. Choose method
3. Use: IMPLEMENTATION_CHECKLIST.md to track
4. Reference: QUICK_REFERENCE.md for troubleshooting
```

### "I need to test the alarm now"
```
1. Complete: Deployment & email confirmation
2. SSH: ssh -i key.pem ec2-user@<public-ip>
3. Run: stress-ng --cpu 2 --timeout 10m
4. Monitor: CloudWatch Alarms console
5. Check: Email inbox
```

### "Something's not working"
```
1. Check: QUICK_REFERENCE.md - Troubleshooting section
2. Review: LAB_GUIDE.md - Troubleshooting section
3. Run: AWS CLI commands from QUICK_REFERENCE.md
4. Verify: Each component with checklist
```

### "I want to clean up resources"
```
1. CloudFormation: aws cloudformation delete-stack --stack-name cpu-alarm-lab
2. Terraform: terraform destroy
3. Manual: Follow README.md - Cleanup section
```

---

## 🎓 Learning Path

### Path 1: Quick Learner (1 hour total)
- README.md (5 min)
- Run deploy.ps1 (1 min execution, 10 min wait)
- QUICK_REFERENCE.md (10 min)
- Test alarm (30 min)
- **Result:** Working lab, basic understanding

### Path 2: Thorough Learner (3 hours total)
- README.md (5 min)
- LAB_GUIDE.md (45 min)
- Deploy via CloudFormation (10 min)
- Test thoroughly (30 min)
- Review architecture diagrams (15 min)
- **Result:** Deep understanding of all components

### Path 3: Deep Dive Learner (5+ hours)
- README.md (5 min)
- LAB_GUIDE.md - Read all sections (60 min)
- Manual setup following steps (90 min)
- Test each component individually (45 min)
- Explore Terraform and CloudFormation templates (30 min)
- Document learnings (15 min)
- **Result:** Expert-level understanding

---

## 🔧 File Purpose Reference

| File | Purpose | When to Read | Time |
|------|---------|-------------|------|
| README.md | Overview & quick start | Always first | 5 min |
| LAB_GUIDE.md | Detailed walkthrough | Before/during deployment | 45 min |
| QUICK_REFERENCE.md | Commands & troubleshooting | During testing & issues | 5-10 min |
| IMPLEMENTATION_CHECKLIST.md | Progress tracking | Throughout lab | 2-3 min each phase |
| cpu-alarm-cloudformation.yaml | AWS Infrastructure | Before CloudFormation deploy | 10 min review |
| main.tf | Terraform Infrastructure | Before Terraform deploy | 10 min review |
| deploy.ps1 | Automated deployment (Windows) | Execute when ready | 1 min setup |
| deploy.sh | Automated deployment (Linux/Mac) | Execute when ready | 1 min setup |
| user_data.sh | EC2 initialization | Read for understanding | 5 min |
| terraform.tfvars.example | Terraform variables | Before Terraform deploy | 1 min |

---

## ✅ Verification Checklist

Before considering the lab complete:

```
Reading & Planning
- [ ] Read README.md
- [ ] Chose deployment method
- [ ] Understood architecture

Deployment
- [ ] All resources created successfully
- [ ] No errors in deployment
- [ ] Resources visible in AWS console

Configuration
- [ ] EC2 instance running
- [ ] CloudWatch alarm created
- [ ] SNS topic exists
- [ ] Email subscription status: Confirmed

Testing
- [ ] CPU load generated
- [ ] Alarm triggered (state: IN_ALARM)
- [ ] Email notification received
- [ ] Verified email content

Understanding
- [ ] Can explain the architecture
- [ ] Understand each AWS service role
- [ ] Know how alarm evaluation works
- [ ] Can troubleshoot issues

Cleanup (Optional)
- [ ] Resources deleted
- [ ] No accidental charges
```

---

## 🚀 Next Steps After Completing

### Suggested Advanced Topics
1. **SMS Notifications** - Add phone number to SNS
2. **Auto-Scaling** - Create Lambda to respond to alarms
3. **Custom Metrics** - Push application data to CloudWatch
4. **Dashboard** - Build monitoring visualization
5. **Composite Alarms** - Multi-condition alerts

### Resources for Further Learning
- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [SNS Developer Guide](https://docs.aws.amazon.com/sns/)
- [EC2 Monitoring Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring_ec2.html)

---

## 💡 Pro Tips

### Time Optimization
- Use CloudFormation/Terraform for faster deployment
- Read QUICK_REFERENCE.md while waiting for resources
- Test with multiple load levels (30%, 60%, 90%, 100% CPU)

### Learning Optimization
- Experiment with alarm settings (threshold, period, evaluation)
- Create dashboard while waiting for next evaluation period
- Take screenshots of alarm triggering and email

### Cost Optimization
- Delete resources immediately after lab
- Use free tier resources when possible
- Monitor CloudWatch for unexpected charges

---

## 📞 Support Resources

### Finding Information
| Need | Check | Time |
|------|-------|------|
| Quick command | QUICK_REFERENCE.md | 1 min |
| Step-by-step | LAB_GUIDE.md | 5-10 min |
| Troubleshooting | QUICK_REFERENCE.md or LAB_GUIDE.md | 10 min |
| Progress tracking | IMPLEMENTATION_CHECKLIST.md | 2 min |
| Architecture details | LAB_GUIDE.md or README.md | 10 min |

---

## 🎯 Success Criteria

You've successfully completed the lab when:

✅ **All Resources Deployed**
- EC2 instance running
- CloudWatch alarm exists
- SNS topic configured
- Email subscription confirmed

✅ **Tested & Verified**
- CPU load successfully generated
- Alarm triggered and state changed to IN_ALARM
- Email notification received in inbox
- Alarm returned to OK state after load stopped

✅ **Understanding Demonstrated**
- Can explain architecture
- Understand each component's role
- Can troubleshoot issues
- Can reproduce results

---

## 📝 Document Versions

| Document | Last Updated | Version | Status |
|----------|-------------|---------|--------|
| README.md | 2024 | 1.0 | Complete |
| LAB_GUIDE.md | 2024 | 1.0 | Complete |
| QUICK_REFERENCE.md | 2024 | 1.0 | Complete |
| IMPLEMENTATION_CHECKLIST.md | 2024 | 1.0 | Complete |
| CloudFormation Template | 2024 | 1.0 | Production Ready |
| Terraform Configuration | 2024 | 1.0 | Production Ready |

---

**Ready to start? Pick a document above and let's go! 🚀**

Recommended: Start with [README.md](README.md)
