#!/bin/bash

INSTALL_DIRECTORY=/usr/share/

sudo apt update
sudo apt install -y git
sudo apt install -y cmake
sudo apt install -y build-essential
sudo apt install -y libusb-1.0-0-dev

#Download and install the RTL-SDR V3 Bias Tee software.

cd  ${INSTALL_DIRECTORY}
git clone https://github.com/rtlsdrblog/rtl_biast  biastee
cd biastee
mkdir build
cd build
cmake .. -DDETACH_KERNEL_DRIVER=ON
make

DROPIN_DIR=/usr/lib/systemd/system/dump1090-fa.service.d
DROPIN_DIR2=/usr/lib/systemd/system/dump1090-fa2.service.d
sudo mkdir ${DROPIN_DIR}
sudo mkdir ${DROPIN_DIR2}
CONFIG_FILE=${DROPIN_DIR}/biastee.conf
CONFIG_FILE2=${DROPIN_DIR2}/biastee2.conf

echo "Writing code to dropin file biastee.conf"
/bin/cat <<EOM >${CONFIG_FILE}
[Service]
ExecStartPre=/usr/share/biastee/build/src/rtl_biast -b 1 -d 0

EOM
sudo chmod 644 ${CONFIG_FILE}

echo "Writing code to dropin file biastee2.conf"
/bin/cat <<EOM >${CONFIG_FILE2}
[Service]
ExecStartPre=/usr/share/biastee/build/src/rtl_biast -b 1 -d 1

EOM
sudo chmod 644 ${CONFIG_FILE2}

sudo systemctl daemon-reload 

sudo systemctl restart dump1090-fa 

sudo systemctl restart dump1090-fa2
