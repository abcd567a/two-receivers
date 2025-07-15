#!/bin/bash 
PIAWARE_VER=9.0
echo  -e "\e[33mSetting up piaware repository....\e[39m"
wget https://www.flightaware.com/adsb/piaware/files/packages/pool/piaware/f/flightaware-apt-repository/flightaware-apt-repository_1.2_all.deb
sudo dpkg -i flightaware-apt-repository_1.2_all.deb
sudo apt-get update
echo  -e "\e[33mInstalling piaware .....\e[39m"
sudo apt-get install -y piaware
sudo piaware-config uat-receiver-type none
sudo piaware-config allow-auto-updates yes
sudo piaware-config allow-manual-updates yes
echo -e "\e[32mInstallation of Piaware completed....\e[39m"

echo  -e "\e[33mStarting installation of dump1090-fa....\e[39m"
sudo apt-get install -y dump1090-fa

sudo sed -i 's/^RECEIVER_SERIAL=.*/RECEIVER_SERIAL=101/' /etc/default/dump1090-fa


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
# and either starts dump1090-fa with the configured
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

if [ "$ENABLED2" != "yes" ]
then
    echo "dump1090-fa not enabled in /etc/default/dump1090-fa2" >&2
    exit 64
fi

# process options

# if there's no CONFIG_STYLE, infer a version
if [ -z "$CONFIG_STYLE2" ]
then
   if [ -n "$RECEIVER_OPTIONS2" -o -n "$DECODER_OPTIONS2" -o -n "$NET_OPTIONS2" -o -n "$JSON_OPTIONS2" ]
   then
       CONFIG_STYLE2=5
   else
       CONFIG_STYLE2=6
   fi
fi

is_slow_cpu() {
    case "$SLOW_CPU2" in
        yes) return 0 ;;
        auto)
            case $(uname -m) in
                armv6*) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        *) return 1 ;;
    esac
}

if [ "$CONFIG_STYLE2" = "5" ]
then
    # old style config file
    echo "/etc/default/dump1090-fa2 is using the old config style, please consider updating it" >&2
    OPTS2="$RECEIVER_OPTIONS2 $DECODER_OPTIONS2 $NET_OPTIONS2 $JSON_OPTIONS2"
elif [ -n "$OVERRIDE_OPTIONS2" ]
then
    # ignore all other settings, use only provided options
    OPTS="$OVERRIDE_OPTIONS"
else
    # build a list of options based on config settings
    OPTS=""

    if [ "${RECEIVER2:-none}" = "none" ]
    then
        OPTS2="$OPTS2 --device-type none"
    else
        if [ -n "$RECEIVER2" ]; then OPTS2="$OPTS2 --device-type $RECEIVER2"; fi
        if [ -n "$RECEIVER_SERIAL2" ]; then OPTS2="$OPTS2 --device-index $RECEIVER_SERIAL2"; fi
        if [ -n "$RECEIVER_GAIN2" ]; then OPTS2="$OPTS2 --gain $RECEIVER_GAIN2"; fi
        if [ -n "$WISDOM2" -a -f "$WISDOM2" ]; then OPTS2="$OPTS2 --wisdom $WISDOM2"; fi

        if [ "$ADAPTIVE_DYNAMIC_RANGE2" = "yes" ]; then OPTS2="$OPTS2 --adaptive-range"; fi
        if [ -n "$ADAPTIVE_DYNAMIC_RANGE_TARGET2" ]; then OPTS2="$OPTS2 --adaptive-range-target $ADAPTIVE_DYNAMIC_RANGE_TARGET2"; fi
        if [ "$ADAPTIVE_BURST2" = "yes" ]; then OPTS2="$OPTS2 --adaptive-burst"; fi
        if [ -n "$ADAPTIVE_MIN_GAIN2" ]; then OPTS2="$OPTS2 --adaptive-min-gain $ADAPTIVE_MIN_GAIN2"; fi
        if [ -n "$ADAPTIVE_MAX_GAIN2" ]; then OPTS2="$OPTS2 --adaptive-max-gain $ADAPTIVE_MAX_GAIN2"; fi

        if is_slow_cpu
        then
            OPTS2="$OPTS2 --adaptive-duty-cycle 10 --no-fix-df"
        fi
    fi

    if [ "$ERROR_CORRECTION2" = "yes" ]; then OPTS2="$OPTS2 --fix"; fi

    if [ -n "$RECEIVER_LAT" -a -n "$RECEIVER_LON" ]; then
        OPTS2="$OPTS2 --lat $RECEIVER_LAT --lon $RECEIVER_LON"
    elif  [ -n "$PIAWARE_LAT" -a -n "$PIAWARE_LON" ]; then
        OPTS2="$OPTS2 --lat $PIAWARE_LAT --lon $PIAWARE_LON"
    fi

    if [ -n "$MAX_RANGE2" ]; then OPTS2="$OPTS2 --max-range $MAX_RANGE2"; fi

    if [ -n "$NET_RAW_INPUT_PORTS2" ]; then OPTS2="$OPTS2 --net-ri-port $NET_RAW_INPUT_PORTS2"; fi
    if [ -n "$NET_RAW_OUTPUT_PORTS2" ]; then OPTS2="$OPTS2 --net-ro-port $NET_RAW_OUTPUT_PORTS2"; fi
    if [ -n "$NET_SBS_OUTPUT_PORTS2" ]; then OPTS2="$OPTS2 --net-sbs-port $NET_SBS_OUTPUT_PORTS2"; fi
    if [ -n "$NET_BEAST_INPUT_PORTS2" ]; then OPTS2="$OPTS2 --net-bi-port $NET_BEAST_INPUT_PORTS2"; fi
    if [ -n "$NET_BEAST_OUTPUT_PORTS2" ]; then OPTS2="$OPTS2 --net-bo-port $NET_BEAST_OUTPUT_PORTS2"; fi

    if [ -n "$JSON_LOCATION_ACCURACY2" ]; then OPTS2="$OPTS2 --json-location-accuracy $JSON_LOCATION_ACCURACY2"; fi

    if [ -n "$EXTRA_OPTIONS2" ]; then OPTS2="$OPTS2 $EXTRA_OPTIONS2"; fi
fi

exec /usr/bin/dump1090-fa --quiet $OPTS2 "$@"
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

# dump1090-fa2 won't automatically start unless ENABLED=yes
ENABLED2=yes

# SDR device type. Use "none" for a net-only configuration
RECEIVER2=rtlsdr
# serial number or device index of device to use (only needed if there is more than one SDR connected)
RECEIVER_SERIAL2=202
# Initial receiver gain, in dB. If adaptive gain is enabled (see below) the actual gain
# may change over time
RECEIVER_GAIN2=60

# Adjust gain to try to achieve optimal dynamic range / noise floor?
ADAPTIVE_DYNAMIC_RANGE2=yes
# Target dynamic range in dB (leave blank to autoselect based on SDR type)
ADAPTIVE_DYNAMIC_RANGE_TARGET2=
# Reduce gain when loud message bursts from nearby aircraft are seen?
ADAPTIVE_BURST2=no
# Gain range to allow when changing gain, in dB (empty = no limit)
ADAPTIVE_MIN_GAIN2=
ADAPTIVE_MAX_GAIN2=

# Turn on options to reduce load on slower CPUs, at the expense of slightly worse decoder performance.
# Setting "auto" will enable these options only if the CPU appears to be a slow CPU (currently this
# means armv6 only, e.g. Pi Zero)
SLOW_CPU2=auto
# Local wisdom file used to select DSP implementations; uses built-in ranking if the file is missing
WISDOM2=/etc/dump1090-fa/wisdom2.local

# Correct CRC errors where possible
ERROR_CORRECTION2=yes

# Receiver location, used for some types of position decoding. Provide the location as
# signed decimal degrees. If not given here, dump1090 will also try to read a receiver
# location from /var/cache/piaware/location.env (written automatically by PiAware, if installed)
RECEIVER_LAT2=
RECEIVER_LON2=
# Maximum range, in NM. Positions more distant than this are ignored. No limit if not set.
MAX_RANGE2=360

# Network ports to listen on for connections
NET_RAW_INPUT_PORTS2=
NET_RAW_OUTPUT_PORTS2=31002
NET_SBS_OUTPUT_PORTS2=31003
NET_BEAST_INPUT_PORTS2=31004,31104
NET_BEAST_OUTPUT_PORTS2=31005

# Accuracy of location written to JSON output
JSON_LOCATION_ACCURACY2=1

# Additional options can be added here:
EXTRA_OPTIONS2=""

# If OVERRIDE_OPTIONS is set, only those options are used; all other options
# in this config file are ignored.
OVERRIDE_OPTIONS2=""

# This is a marker to make it easier for scripts to identify a v6-style config file
CONFIG_STYLE2=6

EOT

sudo chmod 644 $CONFIG_FILE_dump
echo ""
echo -e "\e[33m(4) Creating lighttpd Config file......\e[39m"
CONFIG_FILE_lighttpd=/etc/lighttpd/conf-available/89-skyaware2.conf
sudo touch $CONFIG_FILE_lighttpd
sudo chmod 666 $CONFIG_FILE_lighttpd
sudo cat <<\EOT > $CONFIG_FILE_lighttpd
# Allows access to the static files that provide the dump1090 map view,
# and also to the dynamically-generated json parts that contain aircraft
# data and are periodically written by the dump1090 daemon.

# Enable alias module
#
## This module is normally already enabled in lighttpd, so you should not
## need to uncommment this line.
## There are some cases (e.g. when installing this on a Raspberry Pi
## that runs PiHole) in which the module has been removed from the
## default configuration, and the dump1090-fa web interface no longer
## loads properly.
## If this is what you are experiencing, or if you see messages in your
## error log like:
## (server.c.1493) WARNING: unknown config-key: alias.url (ignored)
## then uncommenting this line and then restarting lighttpd could fix
## the issue.
## This is not enabled by default as standard lighttpd will not start if
## modules are loaded multiple times.
#
# server.modules += ( "mod_alias" )

alias.url += (
  "/skyaware2/data/" => "/run/dump1090-fa2/",
  "/skyaware2/data-978/" => "/run/skyaware978/",
  "/skyaware2/" => "/usr/share/skyaware/html/"
)

# redirect the slash-less URL
url.redirect += (
  "^/skyaware2$" => "/skyaware/"
)

# Listen on port 8181 and serve the map there, too.
$SERVER["socket"] == ":8181" {
  alias.url += (
    "/data/" => "/run/dump1090-fa2/",
    "/data-978/" => "/run/skyaware978/",
    "/" => "/usr/share/skyaware/html/"
  )
}

# Add CORS header
server.modules += ( "mod_setenv" )
$HTTP["url"] =~ "^/skyaware2/data/.*\.json$" {
  setenv.set-response-header = ( "Access-Control-Allow-Origin" => "*" )
}

# Uncomment this section to enable SSL traffic (HTTPS) - especially useful
# for .dev domains
## Listen on 8443 for SSL connections
#server.modules += ( "mod_openssl" )
#$HTTP["host"] == "piaware.example.com" {
#  $SERVER["socket"] == ":8443" {
#    ssl.engine = "enable"
#    ssl.pemfile = "/etc/ssl/certs/combined.pem"
#    ssl.ca-file =  "/etc/ssl/certs/fullchain.cer"
#    ssl.honor-cipher-order = "enable"
#    ssl.cipher-list = "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH"
#    ssl.use-sslv2 = "disable"
#    ssl.use-sslv3 = "disable"
#
#  alias.url += (
#    "/data/" => "/run/dump1090-fa2/",
#    "/" => "/usr/share/skyware/html/"
#  )
#  }
#}
#
## Redirect HTTP to HTTPS
#$HTTP["scheme"] == "http" {
#  $HTTP["host"] =~ ".*" {
#    url.redirect = (".*" => "https://%0$0")
#  }


EOT

sudo chmod 644 $CONFIG_FILE_lighttpd

sudo lighty-enable-mod skyaware2
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

sudo systemctl restart dump1090-fa
sudo systemctl restart dump1090-fa2
sudo systemctl restart piaware
sudo systemctl restart piaware2

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
echo -e "http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/skyaware/"
echo -e "http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/skyaware2/"
echo ""
