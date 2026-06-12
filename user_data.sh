#!/bin/bash
# User Data Script for EC2 Instance
# This runs when the instance starts to install and configure necessary software

set -e

# Update system
yum update -y

# Install essential tools
yum install -y \
    amazon-cloudwatch-agent \
    stress-ng \
    httpd \
    wget \
    curl

# Start and enable Apache HTTP Server
systemctl start httpd
systemctl enable httpd

# Create simple web page showing instance information
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>CPU Alarm Lab Instance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        h1 { color: #FF9900; border-bottom: 2px solid #FF9900; padding-bottom: 10px; }
        .info { background: #f0f0f0; padding: 15px; border-radius: 3px; margin: 10px 0; }
        .status { color: green; font-weight: bold; }
        code { background: #e8e8e8; padding: 2px 5px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 CPU Alarm Lab Instance</h1>
        
        <div class="info">
            <h2>Instance Status</h2>
            <p><strong>Status:</strong> <span class="status">✓ Running</span></p>
            <p><strong>Hostname:</strong> <code>$(hostname -f)</code></p>
            <p><strong>Instance ID:</strong> <code>$(ec2-metadata --instance-id | cut -d' ' -f2)</code></p>
            <p><strong>Local IPv4:</strong> <code>$(ec2-metadata --local-ipv4 | cut -d' ' -f2)</code></p>
            <p><strong>Public IPv4:</strong> <code>$(ec2-metadata --public-ipv4 | cut -d' ' -f2)</code></p>
            <p><strong>AMI ID:</strong> <code>$(ec2-metadata --ami-id | cut -d' ' -f2)</code></p>
        </div>

        <div class="info">
            <h2>CloudWatch Monitoring</h2>
            <p>✓ EC2 instance CPU is being monitored by CloudWatch</p>
            <p>✓ Alarm threshold: CPU > 80% for 5 minutes</p>
            <p>✓ Email notifications enabled via SNS</p>
        </div>

        <div class="info">
            <h2>Testing the Alarm</h2>
            <p>To generate CPU load and test the alarm:</p>
            <pre>
# SSH into this instance
ssh -i your-key.pem ec2-user@$(ec2-metadata --public-ipv4 | cut -d' ' -f2)

# Install stress tool (already installed)
sudo yum install -y stress-ng

# Generate CPU load for 10 minutes
stress-ng --cpu 2 --timeout 10m

# Or use yes command for infinite load
yes > /dev/null &
            </pre>
        </div>

        <div class="info">
            <h2>Monitor in CloudWatch</h2>
            <p>Open CloudWatch Console and navigate to:</p>
            <p><strong>CloudWatch → Alarms → ec2-cpu-high-alarm</strong></p>
            <p>Watch the alarm status change when CPU exceeds threshold</p>
        </div>

        <hr>
        <p style="color: #666; font-size: 12px;">AWS CPU Alarm Lab - Auto-generated page</p>
    </div>
</body>
</html>
EOF

# Create a system info file for logging
cat > /tmp/instance-info.txt <<EOF
=== EC2 Instance Information ===
Hostname: $(hostname -f)
Instance ID: $(ec2-metadata --instance-id)
Instance Type: $(ec2-metadata --instance-type)
AMI ID: $(ec2-metadata --ami-id)
Region: $(ec2-metadata --availability-zone | sed 's/[a-z]$//')
Date: $(date)
=== Software Installed ===
- Amazon CloudWatch Agent
- stress-ng (for CPU load testing)
- Apache HTTP Server
=== CPU Alarm Lab Ready ===
Web Server: http://$(ec2-metadata --public-ipv4 | cut -d' ' -f2)
EOF

echo "EC2 Instance initialization complete!"
