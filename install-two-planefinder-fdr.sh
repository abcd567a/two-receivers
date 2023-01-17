#!/bin/bash

CLIENT_PKG=pfclient_5.0.161_armhf.deb
CLIENT_URL=http://client.planefinder.net/${CLIENT_PKG}

INIT_FILE2=/etc/init.d/pfclient2
echo -e "\e[01;32mCreating System-V init file for 2nd instance:" ${INIT_FILE2}  " \e[39m"
sudo touch ${INIT_FILE2} 
sudo chmod +x ${INIT_FILE2}


echo -e "\e[01;32mWriting code to file: " ${INIT_FILE2} " \e[39m"
/bin/cat <<\EOM >${INIT_FILE2}
#!/bin/sh
### BEGIN INIT INFO
# Provides:          pfclient2
# Required-Start:    $local_fs $remote_fs $network $time $syslog
# Required-Stop:     $local_fs $remote_fs $network $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: planefinder.net ads-b decoder2
# Description:       pfclient2 decodes ADS-B data and shares to planefinder.net
### END INIT INFO

. /lib/lsb/init-functions

DAEMON2=/usr/bin/pfclient2

PIDFILE2=/var/run/pfclient2.pid
LOGFILE2=/var/log/pfclient2
CONFIGFILE2=/etc/pfclient-config2.json

get_pid()
{
    cat "$PIDFILE2"
}

is_running()
{
    [ -f "$PIDFILE2" ] && ps `get_pid` > /dev/null 2>&1
}

start()
{
  log_daemon_msg "Starting pfclient2" "pfclient2"
  log_daemon_msg ""

  if [ ! -d /var/log/pfclient2 ]; then
      mkdir /var/log/pfclient2
  fi

  start-stop-daemon --start --exec $DAEMON2 -- --web_port=30063 --echo_port=30064 -d -i $PIDFILE2 -z $CONFIGFILE2 -y $LOGFILE2 $ 2>/var/log/pfclient2/error.log

  status=$?
  log_end_msg $status
}

stop() {
 log_daemon_msg "Stopping pfclient2" "pfclient2"
 log_daemon_msg ""

 PFPID2=`cat ${PIDFILE2} 2>/dev/null`

    if [ "${PFPID2}" != "" ] && [ -e "/proc/${PFPID2}" ]; then
      kill $PFPID2 #2>/dev/null
      ATTEMPT2=0
      while [ -e "/proc/${PFPID2}" ] && [ "${ATTEMPT2}" -le 80 ]; do
        sleep 0.25
        ATTEMPT2=$((ATTEMPT2+1))
      done

      if [ -e "/proc/${PFPID2}" ]; then
        echo "Killing all children processes"
        pkill -9 -P ${PFPID2}
        kill -9 ${PFPID2}
      fi
    fi

    log_end_msg $?
    return
}

status()
{
  if is_running; then
        echo "Running"
    else
        echo "Stopped"
        exit 1
    fi

  return;
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
  status
        ;;
    restart)
        stop && sleep 2 && start
        ;;
    reload)
  exit 3
  ;;
    status)
  status_of_proc $DAEMON2 "pfclient2"
  ;;
    *)
  echo "Usage: $0 {start|stop|restart|status}"
  exit 2
  ;;
esac
EOM

echo -e "\e[01;32mInstalling System-V init file for 2nd instance pfclient2 \e[39m"
sudo update-rc.d pfclient2 defaults

echo -e "\e[01;32mInstalling pfclient package \e[39m"
wget -O ${PWD}/${CLIENT_PKG}  ${CLIENT_URL}  
sudo dpkg -i ${CLIENT_PKG}  

echo -e "\e[01;32mCreating 2nd copy of linux binary....\e[39m"
sudo cp /usr/bin/pfclient /usr/bin/pfclient2

echo " "

echo " "

echo -e "\e[01;32mTwo instances of Planefinder feeder have been installed \e[39m"
echo -e "\e[01;32mConfigure them as follows:\e[39m"
echo " "
echo -e "\e[01;31mCAUTION: Do NOT use same share-code in both instances \e[39m"
echo " "
echo -e "\e[01;33mFeeder 1:\e[39m In Browser, go to page <IP-of-Pi>:\e[01;33m30053\e[39m and configure \e[39m"
echo -e "\e[01;33mFeeder 1:\e[39m Use host 127.0.0.1 port \e[01;33m30005 \e[39m"
echo " "
echo -e "\e[01;35mFeeder 2:\e[39m In Browser, go to page <IP-of-Pi>:\e[01;35m30063\e[39m and configure \e[39m"
echo -e "\e[01;35mFeeder 2:\e[39m Use host 127.0.0.1 port \e[01;35m31005 \e[39m"

echo " "

