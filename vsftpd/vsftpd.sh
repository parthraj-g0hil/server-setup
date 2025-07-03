#!/bin/bash

echo "Starting vsftpd installation and configuration..."

# Step 1: Check OS and Install vsftpd
if [ -f /etc/debian_version ]; then
    echo "Detected Ubuntu/Debian. Installing vsftpd..."
    sudo apt update
    sudo apt install vsftpd -y
    config_file="/etc/vsftpd.conf"
    backup_file="/etc/vsftpd.conf.bkp"
elif [ -f /etc/system-release ] && grep -qi "amazon linux" /etc/system-release; then
    echo "Detected Amazon Linux. Installing vsftpd..."
    sudo yum install vsftpd -y
    config_file="/etc/vsftpd/vsftpd.conf"
    backup_file="/etc/vsftpd/vsftpd.conf.bkp"
else
    echo "Detected RHEL/CentOS. Installing vsftpd..."
    sudo yum install vsftpd -y
    config_file="/etc/vsftpd/vsftpd.conf"
    backup_file="/etc/vsftpd/vsftpd.conf.bkp"
fi

# Step 2: Backup existing vsftpd.conf
if [ -f "$config_file" ]; then
    echo "Backing up vsftpd configuration file..."
    sudo cp "$config_file" "$backup_file"
fi

# Step 3: Configure User
read -p "Enter the username for vsftpd: " username
if id "$username" &>/dev/null; then
    echo "User $username already exists. Proceeding..."
else
    echo "User $username does not exist. Creating..."
    sudo useradd -m -d /home/$username $username
    echo "Set password for the new user $username:"
    sudo passwd $username
fi

# Step 4: Check OS-Specific Configuration
if [ -f /etc/system-release ] && grep -qi "amazon linux" /etc/system-release; then
    echo "Detected Amazon Linux. Applying Amazon Linux configuration..."

    # Step 5: Add User to /etc/vsftpd/user_list
    echo "Adding user $username to /etc/vsftpd/user_list..."
    sudo bash -c "echo $username >> /etc/vsftpd/user_list"

    # Step 6: Update vsftpd.conf
    echo "Updating vsftpd configuration..."
    sudo bash -c "cat > $config_file <<EOL
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
listen_ipv6=NO
pam_service_name=vsftpd
userlist_enable=YES
userlist_deny=NO
tcp_wrappers=NO
pasv_promiscuous=YES
pasv_max_port=13100
pasv_min_port=13000
userlist_file=/etc/vsftpd/user_list
pasv_enable=YES
pasv_address=$(curl -s ifconfig.me)
EOL"

else
    echo "Detected other OS (Ubuntu/Debian/RHEL/CentOS). Applying general configuration..."

    # Step 5: Set Default Directory
    read -p "Do you want to set a custom directory for this user? (yes/no): " set_dir
    if [[ "$set_dir" == "yes" ]]; then
        read -p "Enter the path for the default directory: " user_path
        sudo mkdir -p $user_path
        sudo chown $username:$username $user_path
        sudo usermod -d $user_path -s /bin/bash $username
        echo "Default directory for $username set to $user_path."
    fi

    # Step 6: Create /etc/vsftpd.chroot_list
    echo "Adding user $username to /etc/vsftpd.chroot_list..."
    sudo bash -c "echo $username >> /etc/vsftpd.chroot_list"

    # Step 7: Create /etc/vsftpd.userlist
    echo "Adding user $username to /etc/vsftpd.userlist..."
    sudo bash -c "echo $username >> /etc/vsftpd.userlist"

    # Step 8: Update vsftpd.conf
    echo "Updating vsftpd configuration..."
    sudo bash -c "cat > $config_file <<EOL
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
listen_ipv6=NO
pam_service_name=vsftpd
userlist_enable=YES
userlist_deny=NO
tcp_wrappers=YES
chroot_local_user=YES
chroot_list_enable=YES
pasv_promiscuous=YES
pasv_max_port=13100
pasv_min_port=13000
userlist_file=/etc/vsftpd.userlist
chroot_list_file=/etc/vsftpd.chroot_list
pasv_address=$(curl -s ifconfig.me)
EOL"
fi

# Step 9: Enable and Start vsftpd
echo "Enabling and starting vsftpd service..."
sudo systemctl enable vsftpd.service
sudo systemctl start vsftpd.service
sudo systemctl restart vsftpd.service

echo "vsftpd installation and configuration completed successfully."
