#!/bin/bash

echo -e "\e[32mCreating necessary files for 2nd instance of fr24feed......\e[39m"

CONFIG_FILE=/etc/fr24feed.ini
sudo touch ${CONFIG_FILE}
sudo chmod 666 ${CONFIG_FILE}
echo "Writing code to config file fr24feed.ini"
/bin/cat <<EOM >${CONFIG_FILE}
receiver="beast-tcp"
fr24key="xxxxxxxxxxxxxxxx"
host="127.0.0.1:30005"
bs="no"
raw="no"
logmode="1"
logpath="/var/log/fr24feed"
mlat="yes"
mlat-without-gps="yes"
EOM
sudo chmod 644 ${CONFIG_FILE}


CONFIG_FILE2=/etc/fr24feed2.ini
sudo touch ${CONFIG_FILE2}
sudo chmod 666 ${CONFIG_FILE2}
echo "Writing code to config file fr24feed2.ini"
/bin/cat <<EOM >${CONFIG_FILE2}
receiver="beast-tcp"
fr24key="xxxxxxxxxxxxxxxx"
host="127.0.0.1:31005"
bs="no"
raw="no"
logmode="1"
logpath="/var/log/fr24feed2"
mlat="yes"
mlat-without-gps="yes"
EOM
sudo chmod 644 ${CONFIG_FILE2}


SERVICE_FILE2=/etc/systemd/system/fr24feed2.service
sudo touch ${SERVICE_FILE2}
sudo chmod 666 ${SERVICE_FILE2}

/bin/cat <<EOM >${SERVICE_FILE2}
[Unit]
Description=Flightradar24 Feeder2
After=network-online.target

[Service]
Type=simple
Restart=always
LimitCORE=infinity
RuntimeDirectory=fr24feed2
RuntimeDirectoryMode=0755
ExecStartPre=-/bin/mkdir -p /var/log/fr24feed2
ExecStartPre=-/bin/mkdir -p /run/fr24feed2
ExecStartPre=-/bin/chown fr24:fr24 /run/fr24feed2 /var/log/fr24feed2
ExecStart=/usr/bin/fr24feed  --config-file=/etc/fr24feed2.ini
User=fr24
PermissionsStartOnly=true
StandardOutput=null

[Install]
WantedBy=multi-user.target

EOM
sudo chmod 644 ${SERVICE_FILE2}

sudo systemctl enable fr24feed2
sudo systemctl start fr24feed2

echo -e "\e[32mCreation of necessary files of 2nd instance \"fr24feed2\" completed...\e[39m"

echo -e "\e[32mInstalling fr24feed package...\e[39m"

sudo bash -c "$(wget -O - http://repo.feed.flightradar24.com/install_fr24_rpi.sh)"

sudo systemctl restart fr24feed
sudo systemctl restart fr24feed2

echo " "
echo " "
echo -e "\e[01;32mInstallation of two instances of fr24feed completed...\e[39m"
echo " "
echo -e "\e[01;32m(1) Please add your fr24keys in following config files\e[39m"
echo -e "\e[01;33m    For 1st Copy of fr24feed:   sudo nano /etc/fr24feed.ini  \e[39m"
echo -e "\e[01;35m    For 2nd Copy of fr24feed:   sudo nano /etc/fr24feed2.ini  \e[39m"
echo " "
echo -e "\e[01;32m(2) After adding fr24keys, restart...\e[39m"
echo -e "\e[01;33m    For 1st Copy of fr24feed:   sudo systemctl restart fr24feed  \e[39m"
echo -e "\e[01;35m    For 2nd Copy of fr24feed:   sudo systemctl restart fr24feed2  \e[39m"

echo " "
echo -e "\e[01;32m(2) After restart, check logs...\e[39m"
echo -e "\e[01;33m    For 1st Copy of fr24feed:   cat /var/log/fr24feed/fr24feed.log  \e[39m"
echo -e "\e[01;35m    For 2nd Copy of fr24feed:   cat /var/log/fr24feed2/fr24feed.log  \e[39m"
echo " "
echo " "
