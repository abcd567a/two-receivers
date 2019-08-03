# 1 Pi 2 RECEIVERS 

Installs two independent piaware receivers on one Pi

### (1) Write Raspbian to microSD card, power-up

### (2) Serialize dongles as follows

`sudo apt install rtl-sdr`

`rtl_eeprom -d 0 -s 00000101`

`rtl_eeprom -d 1 -s 00000102`

unplug and replug both dongles.

### (3) Run the following  bash command:

**Alternate 1: To install two receivers using dump1090-fa:**

`sudo bash -c "$(wget -O - https://raw.githubusercontent.com/abcd567a/two-receivers/master/2-receivers-dump-fa.sh)"`

**Alternate 2: To install two receivers using dump1090-mutability ver 1.15~dev:**

`sudo bash -c "$(wget -O - https://raw.githubusercontent.com/abcd567a/two-receivers/master/2-receivers-dump-mutab.sh)"`


### (4) Add piaware feeder-id for 2 stations

**First station:** 

`sudo piaware-config feeder-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

(replace xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx by actual feeder id of 1st feeder)

**Second station:**

`sudo nano /etc/piaware2.conf`

Copy-paste following line at the end

`feeder-id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy`

(replace yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy by actual feeder id of 2nd feeder)

Save file (Ctrl+o) and close file (Ctrl+x)

### (5) REBOOT Pi

.
.

![BLOCK DIAGRAM](https://i.postimg.cc/FFW27Smf/1-Pi-2-Receivers-c.png)

.

