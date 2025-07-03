#!/bin/bash

# Download the mailx package
sudo wget https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/os/Packages/mailx-12.5-29.el8.x86_64.rpm

# Install the downloaded mailx package
sudo yum localinstall -y mailx-12.5-29.el8.x86_64.rpm

# Install nss-tools
sudo yum install -y nss-tools

# Install bc
sudo yum install -y bc

