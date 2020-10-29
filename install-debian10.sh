#!/bin/bash

USERNAME=julian
SSHPORT=
SSHDCONF=/etc/sshd/sshd_config

# check if user is root
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi

read -p 'SSH Port: ' SSHPORT

# install basic utilities
apt update
apt install -y screenfetch htop nano
echo "Installed utilities"

# install lem (no PHP) stack
apt install -y mariadb-server nginx-full certbot python3-certbot-nginx
echo "Installed web server and utils, mariadb"

# add repo and install webmin
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -
sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
apt update
apt install -y webmin libsocket6-perl
echo "Installed webmin"

# add repo and install docker
apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt update
apt install -y docker-ce docker-ce-cli containerd.io
echo "Installed docker"

# install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/1.27.4/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
echo "Installed docker-compose"

# add user
useradd -m -s /bin/bash -G sudo,docker $USERNAME
passwd $USERNAME

# change ssh port
sed -i 's/.*\bPort\b.*/Port '"$SSHPORT"'/' $SSHDCONF
sed -i 's/.*\bPermitRootLogin.*/PermitRootLogin no/' $SSHDCONF
systemctl restart sshd
echo "Changed ssh port to $SSHPORT and disabled root login"
