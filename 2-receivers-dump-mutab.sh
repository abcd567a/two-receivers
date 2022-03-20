#!/bin/bash
PIAWARE_VER=7.2
echo -e "\e[33m(1) Installing dump1090-mutability EB_VER ....\e[39m"
sudo apt update
sudo apt install -y dump1090-mutability
sudo usermod -a -G plugdev dump1090 
#sudo dpkg-reconfigure dump1090-mutability

echo -e "\e[32mdump1090-mutability EB_VER installed....\e[39m"
echo ""
echo -e "\e[32mCreating necessary files for 2nd instance of dump1090-mutability....\e[39m"
echo ""
echo -e "\e[33m(3) Creating init.d file for dump1090-mutability2....\e[39m"
sudo cp /etc/init.d/dump1090-mutability /etc/init.d/dump1090-mutability2
sudo sed -i 's/NAME=dump1090-mutability/NAME=dump1090-mutability2/'  /etc/init.d/dump1090-mutability2
sudo sed -i '/DAEMON=/c\DAEMON=\/usr\/bin\/dump1090-mutability'  /etc/init.d/dump1090-mutability2
echo -e "\e[32minit.d file for dump1090-mutability2 created......\e[39m"
echo ""
echo -e "\e[33m(4) Creating config file for dump1090-mutability2....\e[39m"
sudo cp /etc/default/dump1090-mutability  /etc/default/dump1090-mutability2
sudo sed -i '/LOGFILE=/c\LOGFILE="/var/log/dump1090-mutability2.log"'  /etc/default/dump1090-mutability2
sudo sed -i '/DEVICE=/c\DEVICE=101'  /etc/default/dump1090-mutability
sudo sed -i '/DEVICE=/c\DEVICE=202'  /etc/default/dump1090-mutability2
sudo sed -i 's/30001/31001/'  /etc/default/dump1090-mutability2
sudo sed -i 's/30002/31002/'  /etc/default/dump1090-mutability2
sudo sed -i 's/30003/31003/'  /etc/default/dump1090-mutability2
sudo sed -i 's/30004,30104/31004,31104/'  /etc/default/dump1090-mutability2
sudo sed -i 's/30005/31005/'  /etc/default/dump1090-mutability2
sudo sed -i '/JSON_DIR=/c\JSON_DIR="\/run\/dump1090-mutability2/"'  /etc/default/dump1090-mutability2
echo ""
echo -e "\e[32mConfig file for dump1090-mutability2 created......\e[39m"
echo -e "\e[32mTo avoid conflict between two instances of dump1090-mutability,\e[39m"
echo -e "\e[32mthe 2nd instance has been configured for following Port numbers:\e[39m"
echo -e "\e[32mri-port: 31001\nro-port: 31002\nsbs-port: 31003\nbi-port: 31004,31104\nbo-port: 31005\e[39m"
echo ""
echo -e "\e[33mdongle serial # 101 for 1st instance\ndongle serial # 202 for 2nd instance\e[39m"
echo ""

sudo update-rc.d dump1090-mutability2 defaults  
sudo systemctl daemon-reload 

echo -e "\e[32mConfig file for dump1090-mutability2 created......\e[39m"
echo -e "\e[33m(5) Creating lighttpd integration of dump1090-mutability2....\e[39m"

sudo cp /etc/lighttpd/conf-available/89-dump1090.conf  /etc/lighttpd/conf-available/89-dump1090-2.conf

sudo sed -i 's/dump1090\//dump1090-2\//g' /etc/lighttpd/conf-available/89-dump1090-2.conf
sudo sed -i 's/dump1090\$/dump1090-2\$/' /etc/lighttpd/conf-available/89-dump1090-2.conf
sudo sed -i 's/\/run\/dump1090-mutability\//\/run\/dump1090-mutability2\//' /etc/lighttpd/conf-available/89-dump1090-2.conf
sudo sed -i 's/server.stat-cache-engine/#server.stat-cache-engine/' /etc/lighttpd/conf-available/89-dump1090-2.conf 


sudo lighty-enable-mod dump1090-2
sudo service lighttpd force-reload


echo -e "\e[33m(2) Installing Piaware data feeder using package from Flightaware....\e[39m"
wget http://flightaware.com/adsb/piaware/files/packages/pool/piaware/p/piaware-support/piaware-repository_${PIAWARE_VER}_all.deb 
sudo dpkg -i piaware-repository_${PIAWARE_VER}_all.deb 
sudo apt-get update 
echo  -e "\e[33mInstalling piaware .....\e[39m"
sudo apt-get install -y piaware 
sudo piaware-config uat-receiver-type none
sudo piaware-config allow-auto-updates yes
sudo piaware-config allow-manual-updates yes
echo -e "\e[32mInstallation of Piaware completed....\e[39m"


echo -e "\e[33m(5) Creating Service file for Piaware 2....\e[39m"
SERVICE_FILE_piaware=/lib/systemd/system/piaware2.service
sudo touch $SERVICE_FILE_piaware
sudo chmod 666 $SERVICE_FILE_piaware
sudo cat <<\EOT > $SERVICE_FILE_piaware
# piaware uploader service for systemd
# install in /etc/systemd/system
[Unit]
Description=FlightAware ADS-B uploader
Documentation=https://flightaware.com/adsb/piaware/
Wants=network-online.target
After=dump1090-fa2.service network-online.target time-sync.target
[Service]
User=piaware
RuntimeDirectory=piaware2
SyslogIdentifier=piaware2
ExecStart=/usr/bin/piaware -p %t/piaware2/piaware.pid -plainlog -statusfile %t/piaware2/status.json -configfile /etc/piaware2.conf -cachedir /var/cache/piaware2  
ExecReload=/bin/kill -HUP $MAINPID
Type=simple
Restart=on-failure
RestartSec=30
# exit code 4 means login failed
# exit code 6 means startup failed (bad args or missing MAC)
RestartPreventExitStatus=4 6
[Install]
WantedBy=default.target
EOT

sudo chmod 644 $SERVICE_FILE_piaware
echo ""
echo -e "\e[33m(6) Creating /var/log/piaware2.log entry in /etc/rsyslog.d/piaware.conf file......\e[39m"
sudo sed -i '/& stop/i\else if $programname == "piaware2" then /var/log/piaware2.log' /etc/rsyslog.d/piaware.conf
echo ""
echo -e "\e[33m(6) Creating piaware2 Config file......\e[39m"
CONFIG_FILE_piaware=/etc/piaware2.conf
sudo touch $CONFIG_FILE_piaware
sudo chmod 666 $CONFIG_FILE_piaware
sudo cat <<\EOT > $CONFIG_FILE_piaware
# This file configures piaware and related software.
# You can edit it directly to view and change settings.
#
uat-receiver-type none
allow-auto-updates yes 
allow-manual-updates yes
receiver-type other
receiver-port 31005
receiver-host 127.0.0.1
mlat-results-format beast,connect,localhost:31104 beast,listen,31105 ext_basestation,listen,31106
EOT

sudo chmod 644 $CONFIG_FILE_piaware

echo -e "\e[33m((7) Creating directory /var/cache/piaware2 ....\e[39m"
sudo mkdir /var/cache/piaware2
sudo chown piaware /var/cache/piaware2
sudo chown piaware /etc/piaware2.conf
echo ""
echo "Enabling & starting piaware2"
sudo systemctl enable piaware2
sudo systemctl start piaware2

`sudo systemctl restart dump1090-mutability`
`sudo systemctl restart dump1090-mutability2`
`sudo systemctl restart piaware`
`sudo systemctl restart piaware2`

echo -e "\e[32m===============\e[39m"
echo -e "\e[32mALL DONE !\e[39m"
echo -e "\e[32m===============\e[39m"
echo -e "If you dont have stations/feeder-ids for both stations, " 
echo -e "go to following page and claim both NEW Stations"
echo -e "https://flightaware.com/adsb/piaware/claim"
echo -e ""
echo -e "If you have existing feeder-ids, follow steps below:"
echo -e "(1) For 1st feeder: To add feeder ID, edit file piaware.conf:"
echo -e "sudo nano /etc/piaware.conf"
echo -e "Copy-paste following line at the end of this file"
echo -e "feeder-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
echo -e "(replace xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx by actual feeder id)\n"
echo -e "Restart piaware"
echo -e "sudo systemctl restart piaware"
echo -e "(2) For 2nd feeder: To add feeder ID, edit file piaware2.conf:"
echo -e "sudo nano /etc/piaware2.conf"
echo -e "Copy-paste following line at the end of this file"
echo -e "feeder-id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
echo -e "(replace yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy by actual feeder id)\n"
echo -e "Restart piaware2"
echo -e "sudo systemctl restart piaware2"
echo -e "\e[31m(3) Unplug then replug both dongles (if you have not done after serializing),\e[39m\n" 
echo -e "\e[31mthen Reboot RPi\e[39m\n"
echo -e "(4) After reboot, go to your browser and check map on following addresses"
echo -e "http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/dump1090/"
echo -e "http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/dump1090-2/"
echo ""
