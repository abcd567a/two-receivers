#!/bin/bash
echo  -e "\e[33mSetting up piaware repository....\e[39m"
wget http://flightaware.com/adsb/piaware/files/packages/pool/piaware/p/piaware-support/piaware-repository_3.7.1_all.deb 
sudo dpkg -i piaware-repository_3.7.1_all.deb 
sudo apt-get update 
echo  -e "\e[33mInstalling piaware .....\e[39m"
sudo apt-get install -y piaware 
sudo piaware-config uat-receiver-type none
sudo piaware-config allow-auto-updates yes
sudo piaware-config allow-manual-updates yes
echo -e "\e[32mInstallation of Piaware completed....\e[39m"

echo  -e "\e[33mStarting installation of dump1090-fa....\e[39m"
sudo apt-get install -y dump1090-fa 

indexnow=`sed -n 's/.*--device-index \([^ ]*\).*/\1/p' /etc/default/dump1090-fa`
sudo sed -i 's/--device-index '$indexnow'/--device-index 00000101/' /etc/default/dump1090-fa

echo -e "\e[32mPiaware and dump1090-fa Installed and configured......\e[39m"

read -rsp $'Press any key to start creation of files for 2nd instance...\n' -n1 key

echo -e "\e[33m(1) Creating dump1090-fa2 service file......\e[39m"
SERVICE_FILE_dump=/lib/systemd/system/dump1090-fa2.service
sudo touch $SERVICE_FILE_dump
sudo chmod 666 $SERVICE_FILE_dump
sudo cat <<\EOT > $SERVICE_FILE_dump
# dump1090-fa2 service for systemd
[Unit]
Description=dump1090 ADS-B receiver (FlightAware customization)
Documentation=https://flightaware.com/adsb/piaware/
Wants=network.target
After=network.target
[Service]
User=dump1090
RuntimeDirectory=dump1090-fa2
RuntimeDirectoryMode=0755
ExecStart=/bin/bash /usr/share/dump1090-fa/start-dump1090-fa2 --write-json %t/dump1090-fa2 --quiet
SyslogIdentifier=dump1090-fa2
Type=simple
Restart=on-failure
RestartSec=30
RestartPreventExitStatus=64
Nice=-5
[Install]
WantedBy=default.target
EOT

sudo chmod 644 $SERVICE_FILE_dump
echo ""
echo -e "\e[33m(2) Creating dump1090-fa2 startup file......\e[39m"
STARTUP_FILE_dump=/usr/share/dump1090-fa/start-dump1090-fa2
sudo touch $STARTUP_FILE_dump
sudo chmod 766 $STARTUP_FILE_dump
sudo cat <<\EOT > $STARTUP_FILE_dump
#!/bin/sh
# Helper script that reads /etc/default/dump1090-fa2
# and either starts dump1090-fa2 with the configured
# arguments, or exits with status 64 to tell systemd
# not to auto-restart the service.
if [ -f /etc/default/dump1090-fa2 ]
then
    . /etc/default/dump1090-fa2
fi
if [ -f /var/cache/piaware2/location.env ]
then
    . /var/cache/piaware2/location.env
fi
if [ "x$ENABLED" != "xyes" ]
then
    echo "dump1090-fa2 not enabled in /etc/default/dump1090-fa2" >&2
    exit 64
fi
if [ -n "$PIAWARE_LAT" -a -n "$PIAWARE_LON" ]
then
    POSITION="--lat $PIAWARE_LAT --lon $PIAWARE_LON"
fi
exec /usr/bin/dump1090-fa \
     $RECEIVER_OPTIONS2 $DECODER_OPTIONS2 $NET_OPTIONS2 $JSON_OPTIONS2 $POSITION \
     "$@"
# exec failed, do not restart
exit 64
EOT
sudo chmod 755 $STARTUP_FILE_dump

echo -e "\e[33mENABLING AUTO STARTUP....\e[39m"
sudo systemctl enable dump1090-fa2
echo ""
echo -e "\e[33m(3) Creating dump1090-fa2 Config file......\e[39m"
CONFIG_FILE_dump=/etc/default/dump1090-fa2
sudo touch $CONFIG_FILE_dump
sudo chmod 666 $CONFIG_FILE_dump
sudo cat <<\EOT > $CONFIG_FILE_dump
# dump1090-fa2 configuration
# This is sourced by /usr/share/dump1090-fa/start-dump1090-fa2 as a
# shellscript fragment.
# If you are using a PiAware sdcard image, this config file is regenerated
# on boot based on the contents of piaware-config.txt; any changes made to this
# file will be lost.
# dump1090-fa2 won't automatically start unless ENABLED=yes
ENABLED=yes
RECEIVER_OPTIONS2="--device-index 00000102 --gain -10 --ppm 0 --net-bo-port 31005"
DECODER_OPTIONS2="--max-range 360"  
NET_OPTIONS2="--net --net-heartbeat 60 --net-ro-size 1000 --net-ro-interval 1 --net-ri-port 0 --net-ro-port 31002 --net-sbs-port 31003 --net-bi-port 31004,31104 --net-bo-port 31005"  
JSON_OPTIONS2="--json-location-accuracy 1"  
EOT

sudo chmod 644 $CONFIG_FILE_dump
echo ""
echo -e "\e[33m(4) Creating lighttpd Config file......\e[39m"
CONFIG_FILE_lighttpd=/etc/lighttpd/conf-available/89-dump1090-fa2.conf
sudo touch $CONFIG_FILE_lighttpd
sudo chmod 666 $CONFIG_FILE_lighttpd
sudo cat <<\EOT > $CONFIG_FILE_lighttpd
# Allows access to the static files that provide the dump1090 map view,
# and also to the dynamically-generated json parts that contain aircraft
# data and are periodically written by the dump1090 daemon.
alias.url += (
  "/dump1090-fa2/data/" => "/run/dump1090-fa2/",
  "/dump1090-fa2/" => "/usr/share/dump1090-fa/html/"
)
# redirect the slash-less URL
url.redirect += (
  "^/dump1090-fa2$" => "/dump1090-fa2/"
)
# Listen on port 8181 and serve the map there, too.
$SERVER["socket"] == ":8181" {
  alias.url += (
    "/data/" => "/run/dump1090-fa2/",
    "/" => "/usr/share/dump1090-fa/html/"
  )
}
# Add CORS header
$HTTP["url"] =~ "^/dump1090-fa2/data/.*\.json$" {
  setenv.add-response-header = ( "Access-Control-Allow-Origin" => "*" )
}
EOT

sudo chmod 644 $CONFIG_FILE_lighttpd

sudo lighty-enable-mod dump1090-fa2
sudo service lighttpd force-reload
echo ""
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
StandardOutput=file:/var/log/piaware2.log
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
mlat-results-format beast,connect,localhost:31104
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
echo -e "(2) For 2nd feeder: To add feeder ID, edit file piaware2.conf:"
echo -e "sudo nano /etc/piaware2.conf"
echo -e "Copy-paste following line at the end of this file"
echo -e "feeder-id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
echo -e "(replace yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy by actual feeder id)\n"
echo -e "\e[31m(3) REBOOT RPi\e[39m\n"
echo -e "(4) After reboot, go to your browser and check map on following addresses"
echo -e "http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/dump1090-fa/"
echo -e "http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/dump1090-fa2/"
echo ""
