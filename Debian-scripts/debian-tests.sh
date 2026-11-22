#!/usr/bin/env bash

source ../MacOS-sudo-replace.sh;
source debian-updates.sh;

#libpam-tmpdir cfg
sudo apt install libpam-tmpdir;
sudo pam-auth-update --package tmpdir

#apt-listugs cfg
sudo apt install apt-listbugs;
sudo tee /etc/apt/apt.conf.d/90-apt-listbugs-local >/dev/null <<'EOF'
AptListbugs::Severites "critical,grave,serious,important"
EOF

#needrestart cfg
sudo apt install needrestart;
sudo cat - << 'EOF' | sudo tee /etc/needrestart/conf.d/custom.conf
#Automatically restart services without prompting
$nrconf{restart} = 'a';
EOF

#fail2ban cfg
sudo apt install fail2ban;
cat - << 'EOF' | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
# Whitelist your own IP address or subnet to avoid locking yourself out
ignoreip = 127.0.0.1/8 ::1

# Ban duration (e.g., 1h, 1d, or -1 for permanent)
bantime  = 1h

# Time window to count failed attempts
findtime = 10m

# Number of failed attempts before banning
maxretry = 5

# Backend for reading logs (systemd is required for modern Ubuntu/Debian)
backend = systemd

[sshd]
enabled = true
port    = ssh
EOF

sudo systemctl enable --now fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd