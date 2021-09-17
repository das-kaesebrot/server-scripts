# Server scripts
This repo provides some useful scripts for setting up remote servers quickly. All scripts run interactively.

## OS setup script
### Debian Buster

### Included options (you will be prompted for each)
- Utilities: `screenfetch htop nano`
- Hosting utils: `mariadb-server nginx-full certbot python3-certbot-nginx`
- Webmin (adds repo automatically): `webmin libsocket6-perl`
- Docker (adds repo automatically): `docker-ce docker-ce-cli containerd.io`
- docker-compose and bash autocompletion (using curl)
- Adding a sudo user & setting their password (if docker is installed also adds the user to the `docker` group)
- Setting the SSH server port to a random port above 49152 and disabling root access

### Commands
Run as root:
```bash
wget https://raw.githubusercontent.com/das-kaesebrot/server-scripts/master/buster/install.sh -O install-tmp.sh && chmod +x install-tmp.sh && ./install-tmp.sh && rm install-tmp.sh
```
or as a privileged user:
```bash
sudo sh -c "wget https://raw.githubusercontent.com/das-kaesebrot/server-scripts/master/buster/install.sh -O install-tmp.sh && chmod +x install-tmp.sh && ./install-tmp.sh && rm install-tmp.sh"
```

## WireGuard peer script
This script allows you to interactively add peers to an existing WireGuard VPN configuration, appending the new peer to the server configuration and dumping a client configuration to the `peers/` subfolder in the process.
You will be prompted for all required options.

Download:
```bash
wget https://raw.githubusercontent.com/das-kaesebrot/server-scripts/master/wireguard/add-peer-interactively.sh
```