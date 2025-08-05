#!/usr/bin/env bash
set -e

# Detect Architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_ID=$ID
else
    echo "Cannot detect OS."
    exit 1
fi

# Map OS and determine package manager
case "$OS_ID" in
    amzn)
        OS="amazon_linux"
        PKG_TYPE="rpm"
        ;;
    rhel|centos|fedora)
        OS="redhat"
        PKG_TYPE="rpm"
        ;;
    debian)
        OS="debian"
        PKG_TYPE="deb"
        ;;
    ubuntu)
        OS="ubuntu"
        PKG_TYPE="deb"
        ;;
    sles|suse)
        OS="suse"
        PKG_TYPE="rpm"
        ;;
    *)
        echo "Unsupported OS: $OS_ID"
        exit 1
        ;;
esac

# Download and Install CloudWatch Agent
echo "Detected OS: $OS, Architecture: $ARCH, Package Type: $PKG_TYPE"

if [[ "$PKG_TYPE" == "rpm" ]]; then
    URL="https://s3.amazonaws.com/amazoncloudwatch-agent/${OS}/${ARCH}/latest/amazon-cloudwatch-agent.rpm"
    curl -o /tmp/cwagent.rpm "$URL"
    rpm -U /tmp/cwagent.rpm
elif [[ "$PKG_TYPE" == "deb" ]]; then
    URL="https://s3.amazonaws.com/amazoncloudwatch-agent/${OS}/${ARCH}/latest/amazon-cloudwatch-agent.deb"
    curl -o /tmp/cwagent.deb "$URL"
    dpkg -i -E /tmp/cwagent.deb
fi

# Create advanced CloudWatch Agent config
cat > /tmp/cwconfig.json <<"EOL"
{
	"agent": {
		"metrics_collection_interval": 60,
		"run_as_user": "root"
	},
	"metrics": {
		"append_dimensions": {
			"AutoScalingGroupName": "${aws:AutoScalingGroupName}",
			"ImageId": "${aws:ImageId}",
			"InstanceId": "${aws:InstanceId}",
			"InstanceType": "${aws:InstanceType}"
		},
		"metrics_collected": {
			"cpu": {
				"measurement": [
					"cpu_usage_idle",
					"cpu_usage_iowait",
					"cpu_usage_user",
					"cpu_usage_system"
				],
				"metrics_collection_interval": 60,
				"totalcpu": true
			},
			"disk": {
				"measurement": [
					"used_percent",
					"inodes_free"
				],
				"metrics_collection_interval": 60,
				"resources": [
					"*"
				]
			},
			"diskio": {
				"measurement": [
					"io_time",
					"write_bytes",
					"read_bytes",
					"writes",
					"reads"
				],
				"metrics_collection_interval": 60,
				"resources": [
					"*"
				]
			},
			"mem": {
				"measurement": [
					"mem_used_percent"
				],
				"metrics_collection_interval": 60
			},
			"netstat": {
				"measurement": [
					"tcp_established",
					"tcp_time_wait"
				],
				"metrics_collection_interval": 60
			},
			"swap": {
				"measurement": [
					"swap_used_percent"
				],
				"metrics_collection_interval": 60
			}
		}
	}
}
EOL

# Start the agent
echo "CloudWatch Agent config written to /tmp/cwconfig.json:"
cat /tmp/cwconfig.json

echo "Starting CloudWatch Agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/tmp/cwconfig.json \
    -s

# Ensure it starts at boot and stays active
echo "Enabling and restarting the CloudWatch Agent service..."
systemctl enable amazon-cloudwatch-agent.service
systemctl restart amazon-cloudwatch-agent.service

# Confirm status
systemctl status amazon-cloudwatch-agent.service --no-pager || true