#!/bin/bash

USERNAMEDEFAULT=julian

SSHDCONF=/etc/ssh/sshd_config
MINPORT=49152
PORTRANGE=16382

# check if user is root
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi

function yesno() {
    while true;
    do
        y="y"
        read -p "$1 [Y/n] " yn
        yn=${yn:-y}
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) echo ""; return 1;;
            # * ) echo "Invalid input.";;
        esac
    done
}

function genSSHPort() {
    SSHPORTDEFAULT=$[ $RANDOM % $PORTRANGE + $MINPORT ]
}

apt update
echo ""

# install basic utilities
if yesno "Install utilities [screenfetch, htop, nano, vnstat, tuptime]?";
then
    apt install -y screenfetch htop nano vnstat tuptime
    echo "Installed utilities"
    echo ""
fi    

# install security utils
if yesno "Install security utilities? [ufw, fail2ban]?";
then
    apt install -y ufw fail2ban
    echo "Installed security utilities"
    echo ""
fi

# install lem (no PHP) stack
if yesno "Install hosting utils [mariadb-server nginx-full certbot python3-certbot-nginx]?";
then
    apt install -y mariadb-server nginx-full certbot python3-certbot-nginx
    echo "Installed hosting utils"
    echo ""
fi

# add repo and install webmin
if yesno "Install webmin interface?";
then
    apt install -y gnupg-agent
    wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -
    sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
    apt update
    apt install -y webmin libsocket6-perl
    echo "Installed webmin"
    echo ""
fi

# add repo and install docker
if yesno "Install docker?";
then
    apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
    apt-key fingerprint 0EBFCD88
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    echo "Installed docker"
    echo ""
fi

# install docker-compose
if yesno "Install docker-compose?";
then
    curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    curl -L https://raw.githubusercontent.com/docker/compose/1.27.4/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
    echo "Installed docker-compose"
    echo ""
fi

# add user
if yesno "Add privileged user?";
then
    read -p "Username? [$USERNAMEDEFAULT] " USERNAME
    USERNAME=${USERNAME:-$USERNAMEDEFAULT}
    useradd -m -s /bin/bash -G sudo $USERNAME
    if systemctl is-active --quiet docker;
    then
        usermod -aG docker $USERNAME
    fi
    passwd $USERNAME
    echo "Added privileged user $USERNAME"
    echo ""
fi

# change ssh port
if yesno "Change SSH server port and disable root login?";
then
    genSSHPort
    read -p "SSH Port: [$SSHPORTDEFAULT] " SSHPORT
    SSHPORT=${SSHPORT:-$SSHPORTDEFAULT}
    sed -i 's/.*\bPort\b.*/Port '"$SSHPORT"'/' $SSHDCONF
    sed -i 's/.*\bPermitRootLogin.*/PermitRootLogin no/' $SSHDCONF
    systemctl restart sshd
    echo "Changed ssh port to $SSHPORT and disabled root login"
    echo ""
fi

echo ""
echo "Script done"
