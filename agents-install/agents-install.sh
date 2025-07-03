


 #                               ************ SSM-AGENT**************


dnf install https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

systemctl enable amazon-ssm-agent 	

systemctl start amazon-ssm-agent







 #                               ****************CW-AGiENT*************



yum install collectd -y

wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm

rpm -Uvf amazon-cloudwatch-agent.rpm

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

systemctl enable amazon-cloudwatch-agent.service

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

systemctl restart amazon-cloudwatch-agent.service

    systemctl status amazon-cloudwatch-agent.service






 #                               ****************WAZUH/SIEM-AGENT**************





curl -o wazuh-agent-4.7.0-1.aarch64.rpm https://packages.wazuh.com/4.x/yum/wazuh-agent-4.7.0-1.aarch64.rpm



systemctl daemon-reload
WAZUH_MANAGER='65.2.59.252' WAZUH_AGENT_GROUP='AWS_NON_PROD' rpm -ihv wazuh-agent-4.7.0-1.aarch64.rpmsystemctl enable wazuh-agent
systemctl start wazuh-agent







#                                    ***************SOPHOS-AGENT****************



wget  https://api-cloudstation-us-east-2.prod.hydra.sophos.com/api/download/0d1ab8ccf35da7d2a2f56265ff5fbb96/SophosSetup.sh

mount -t tmpfs -o exec tmpfs /tmp

chmod +x sophosSetup.sh
run the script




#                           **************chrome & chromedriver install ******************

google chrome install 
yum install https://dl.google.com/linux/chrome/rpm/stable/x86_64/google-chrome-stable-127.0.6533.119-1.x86_64.rpm

google chrome-driver install in perticular directory 
wget https://storage.googleapis.com/chrome-for-testing-public/127.0.6533.119/linux64/chromedriver-linux64.zip









*********************agent install script *****************************8

#!/usr/bin/env bash
# comment out the appropriate linux version for install

#Ubuntu x86-64
curl -o /tmp/cwagent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

# Amazon Linux x86-64
#wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm -O /tmp/cwagent.rpm
# Amazon Linux ARM64
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/arm64/latest/amazon-cloudwatch-agent.rpm -O /tmp/cwagent.rpm

#centos
#wget https://amazoncloudwatch-agent.s3.amazonaws.com/centos/amd64/latest/amazon-cloudwatch-agent.rpm

#wget https://amazoncloudwatch-agent-region.s3.region.amazonaws.com/centos/amd64/latest/amazon-cloudwatch-agent.rpm

# Redhat x86-64
# curl -o /tmp/cwagent.rpm https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
# Redhat ARM64
#curl -o /tmp/cwagent.rpm https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/arm64/latest/amazon-cloudwatch-agent.rpm

# SUSE x86-64
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/suse/amd64/latest/amazon-cloudwatch-agent.rpm -O /tmp/cwagent.rpm
# SUSE ARM64
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/suse/arm64/latest/amazon-cloudwatch-agent.rpm -O /tmp/cwagent.rpm

# Debian x86-64
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/cwagent.deb
# Debian ARM64
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/arm64/latest/amazon-cloudwatch-agent.deb -O /tmp/cwagent.deb

# Ubuntu x86-64
#curl -o /tmp/cwagent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
# Ubuntu ARM64
# curl -o /tmp/cwagent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb


# For RPM install, uncoment next line
rpm -U /tmp/cwagent.rpm
#yum install -y amazon-cloudwatch-agent.rpm
# For Debian package install, uncoment next line
# dpkg -i -E /tmp/cwagent.deb


cat > /tmp/cwconfig.json <<"EOL"
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "metrics": {
        "aggregation_dimensions": [
            [
                "InstanceId"
            ]
        ],
        "append_dimensions": {
            "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
            "ImageId": "${aws:ImageId}",
            "InstanceId": "${aws:InstanceId}",
            "InstanceType": "${aws:InstanceType}"
        },
        "metrics_collected": {
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "/"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOL
echo "Configuring CloudWatch agent with file /tmp/cwconfig.json: "
cat /tmp/cwconfig.json
echo "starting cloudwatch agent"
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/tmp/cwconfig.json -s