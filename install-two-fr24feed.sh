#!/bin/bash

echo -e "\e[32mInstalling fr24feed package...\e[39m"

sudo bash -c "$(wget -O - http://repo.feed.flightradar24.com/install_fr24_rpi.sh)"

sudo systemctl restart fr24feed

echo -e "\e[32mFlightradar24 First feeder Installed and configured......\e[39m"

read -rsp $'Press any key to start creation of files for 2nd instance...\n' -n1 key

echo -e "\e[32mCreating necessary files for 2nd instance of fr24feed......\e[39m"

CONFIG_FILE=/etc/fr24feed.ini
sudo touch ${CONFIG_FILE}
sudo chmod 666 ${CONFIG_FILE}
echo "Writing code to config file fr24feed.ini"
/bin/cat << \EOM >${CONFIG_FILE}
receiver="avr-tcp"
host="127.0.0.1:30002"
fr24key="xxxxxxxxxxxxxxxx"
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
/bin/cat << \EOM >${CONFIG_FILE2}
receiver="avr-tcp"
host="127.0.0.1:31002"
fr24key="xxxxxxxxxxxxxxxx"
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

/bin/cat << \EOM >${SERVICE_FILE2}
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
ExecStartPre=-/bin/touch /dev/shm/decoder2.txt
ExecStartPre=-/bin/chown fr24:fr24 /dev/shm/decoder2.txt /run/fr24feed2 /var/log/fr24feed2
ExecStart=/usr/bin/fr24feed --config-file=/etc/fr24feed2.ini --monitor-file=/dev/shm/decoder2.txt
User=fr24
PermissionsStartOnly=true
StandardOutput=null

[Install]
WantedBy=multi-user.target

EOM
sudo chmod 644 ${SERVICE_FILE2}

sudo systemctl enable fr24feed2
sudo systemctl start fr24feed2



STATUS_FILE2=/usr/bin/fr24feed2-status
sudo touch ${STATUS_FILE2}
sudo chmod 666 ${STATUS_FILE2}

/bin/cat << \EOM >${STATUS_FILE2}
#!/bin/bash

. /lib/lsb/init-functions

MONITOR_FILE=/dev/shm/decoder2.txt

systemctl status fr24feed2 2>&1 >/dev/null || {
    log_failure_msg "FR24-2 Feeder/Decoder Process"
    exit 0
}

log_success_msg "FR24-2
 Feeder/Decoder Process: running"

DATE=`grep time_update_utc_s= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`
log_success_msg "FR24 Stats Timestamp: $DATE"


FEED=`grep 'feed_status=' ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`
if [ "$FEED" == "" ]; then
    FEED="unknown"
fi

if [ "$FEED" == "connected" ]; then
    MODE=`grep feed_current_mode= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`
    log_success_msg "FR24-2 Link: $FEED [$MODE]"
    FEED=`grep feed_alias= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`
    log_success_msg "FR24-2 Radar: $FEED"
    FEED=`grep feed_num_ac_tracked= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`
    log_success_msg "FR24-2 Tracked AC: ${FEED}"
else
    log_failure_msg "FR24-2 Link: $FEED"
fi

RX=`grep rx_connected= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`
RX1=`grep num_messages= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`
RX2=`grep num_resyncs= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`

if [ "$RX" == "1" ]; then
    log_success_msg "Receiver: connected ($RX1 MSGS/$RX2 SYNC)"
else
    log_failure_msg "Receiver: down"
fi

MLAT=`grep 'mlat-ok=' ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`
if [ "$MLAT" == "" ]; then
    MLAT="unknown"
fi

if [ "$MLAT" == "YES" ]; then
    MLAT_MODE=`grep mlat-mode= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`
    log_success_msg "FR24-2 MLAT: ok [$MLAT_MODE]"
    MLAT_SEEN=`grep mlat-number-seen= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2`
    log_success_msg "FR24-2 MLAT AC seen: $MLAT_SEEN"
else
    log_failure_msg "FR24-2 MLAT: not running"
fi

EOM
sudo chmod +x ${STATUS_FILE2}


echo -e "\e[32mCreation of necessary files of 2nd instance \"fr24feed2\" completed...\e[39m"

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
echo -e "\e[01;32m(2) Check Status...\e[39m"
echo -e "\e[01;33m    For 1st Copy of fr24feed:   sudo fr24feed-status  \e[39m"
echo -e "\e[01;35m    For 2nd Copy of fr24feed:   sudo fr24feed2-status  \e[39m"

