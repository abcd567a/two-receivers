# 1 Pi 2 RECEIVERS 

## Installs two independent piaware receivers on one RPi </br>

## Please do NOT use a microSD card which already has dump1090-mutability or dump1090-fa installed. 
## This script requires a fresh 32-bit or 64-bit Raspberry Pi OS image written to microSD card. The script will itself install dump1090 (mutability or flightwaware, whichever you choose). </br>

## (1) Write Raspberry Pi OS (32-bit or 64-bit) to microSD card, enable SSH, enable WiFi (if needed), Power-up </br>
## (2) Serialize dongles as follows </br>
(a) Plug-in both DVB-T dongles into RPi </br></br>
(b) Issue following command to install serialization software: </br>
`sudo apt install rtl-sdr` </br></br>
(c) Issue following commands. Say yes when asked for confirmation to chang serial number. </br></br>
To serialize first dongle: </br>
`rtl_eeprom -d 0 -s 101` </br></br>
To serialize second dongle: </br>
`rtl_eeprom -d 1 -s 202` </br>

**IMPORTANT:** After completing above commands, unplug and then replug both dongles. </br>
## (3) Run the following  bash command: </br>

### Alternate 1: To install two receivers using dump1090-fa: </br>
```
sudo bash -c "$(wget -O - https://github.com/abcd567a/two-receivers/raw/master/2-receivers-dump-fa.sh)"  
``` 
</br></br>
### Alternate 2: To install two receivers using dump1090-mutability EB_VER: </br>
```
sudo bash -c "$(wget -O - https://github.com/abcd567a/two-receivers/raw/master/2-receivers-dump-mutab.sh)"  
``` 

## (4) Add piaware feeder-id for 2 stations </br>
**First station:**  </br>
`sudo piaware-config feeder-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` </br>
(replace xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx by actual feeder id of 1st feeder) </br>

**Second station:** </br>
`sudo nano /etc/piaware2.conf` </br>
Copy-paste following line at the end </br>
`feeder-id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy` </br>
(replace yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy by actual feeder id of 2nd feeder) </br>
Save file (Ctrl+o) and close file (Ctrl+x) </br>
## (5) REBOOT Pi  </br>
## (6) AFTER REBOOTING Pi:
**For dump1090-fa install:** </br>
If after reboot, the station location & range rings are not NOT displayed, restart dump1090-fa and dump1090-fa2 </br>

**For dump1090-mutability install:** </br>
The station location & range rings will not NOT be displayed, unless you edit files "/etc/default/dump1090-mutability" and  "/etc/default/dump1090-mutability2", and restart dump1090-mutability and dump1090-mutability2  </br>
## POST INSTALL COMMANDS (to restart & check status) </br>
**piaware** </br>

`sudo systemctl restart piaware ` </br>
`sudo systemctl status piaware ` </br>

`sudo systemctl restart piaware2 ` </br>
`sudo systemctl status piaware2 ` </br></br>
**dump1090-fa** </br>

`sudo systemctl restart dump1090-fa ` </br>
`sudo systemctl status dump1090-fa ` </br>

`sudo systemctl restart dump1090-fa2 ` </br>
`sudo systemctl status dump1090-fa2 ` </br></br>
**dump1090-mutability** </br>

`sudo systemctl restart dump1090-mutability ` </br>
`sudo systemctl status dump1090-mutability ` </br>

`sudo systemctl restart dump1090-mutability2 ` </br>
`sudo systemctl status dump1090-mutability2 ` </br>

</br>

## (6) OPTIONAL
### (6.1) Add Biastee control for RTL-SDR V3 Dongle (on dump1090-fa & dump1090-fa2 )
```
sudo bash -c "$(wget -O - https://github.com/abcd567a/two-receivers/raw/master/install-biastee-dump1090-fa.sh)"  
```


</br>

### (6.2) Install two instances of Flightradar24 Feeder 
```
sudo bash -c "$(wget -O - https://github.com/abcd567a/two-receivers/raw/master/install-two-fr24feed.sh)"  
```

</br>

### (6.3) Install two instances of Planefinder Feeder 
```
sudo bash -c "$(wget -O - https://github.com/abcd567a/two-receivers/raw/master/install-two-planefinder-fdr.sh)"  
```

</br></br>

## Block Diagram using dump1090-fa
![dump1090-fa](https://raw.githubusercontent.com/abcd567a/two-receivers/master/images/1-Pi-2-Receivers-c.png)

### Block Diagram using dump1090-mutability
![dump1090-mutability](https://raw.githubusercontent.com/abcd567a/two-receivers/master/images/1-Pi-2-Receivers-d.png)

</br></br>

