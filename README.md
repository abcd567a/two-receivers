# 1 Pi 2 RECEIVERS 

## Installs two independent piaware receivers on one Pi </br>

### (1) Write Raspbian to microSD card, power-up </br>
### (2) Serialize dongles as follows </br>
`sudo apt install rtl-sdr` </br>
`rtl_eeprom -d 0 -s 00000101` </br>
`rtl_eeprom -d 1 -s 00000102` </br>

unplug and replug both dongles. </br>
### (3) Run the following  bash command: </br>

**Alternate 1: To install two receivers using dump1090-fa:** </br>
`sudo bash -c "$(wget -O - https://raw.githubusercontent.com/abcd567a/two-receivers/master/2-receivers-dump-fa.sh)"` 

**Alternate 2: To install two receivers using dump1090-mutability ver 1.15~dev:** </br>
`sudo bash -c "$(wget -O - https://raw.githubusercontent.com/abcd567a/two-receivers/master/2-receivers-dump-mutab.sh)"` 

### (4) Add piaware feeder-id for 2 stations </br>
**First station:**  </br>
`sudo piaware-config feeder-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` </br>
(replace xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx by actual feeder id of 1st feeder) </br>

**Second station:** </br>
`sudo nano /etc/piaware2.conf` </br>
Copy-paste following line at the end </br>
`feeder-id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy` </br>
(replace yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy by actual feeder id of 2nd feeder) </br>
Save file (Ctrl+o) and close file (Ctrl+x) </br>
### (5) REBOOT Pi </br>


### Block Diagram using dump1090-fa
![dump1090-fa](https://raw.githubusercontent.com/abcd567a/two-receivers/master/images/1-Pi-2-Receivers-c.png)

### Block Diagram using dump1090-mutability
![dump1090-mutability](https://raw.githubusercontent.com/abcd567a/two-receivers/master/images/1-Pi-2-Receivers-d.png)
