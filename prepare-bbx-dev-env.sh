#! /bin/sh

#
# File      : prepare-bbx-dev-env.sh
# Author    : Mohamed JAAFAR (mohamet.jaafar@gmail.com)
# Purpose   : easy start script
# WhatNext  :
# version   : alpha
# Reference : http://www.aclevername.com/articles/linux-xilinx-tutorial/crosstool-ng-1.3.2.html
#

##################################  HOST CONFIG ENV   ##################################
EXPECTED_ARGS=1
CMP_PKGS="automake bison curl cvs flex g++ gawk libncurses5-dev libtool texinfo"
DBG_PKGS="minicom xinetd tftpd tftp"
DEFAULT_BEAGLE_BOARD_PATH=${HOME}/beagle
CROSSTOOL="crosstool-ng-1.9.1"
TOOLCHAIN_URL="http://crosstool-ng.org/download/crosstool-ng/"
TARBALL=".tar.bz2"
SCRIPT_HOME_DIR=$PWD

##################################  UBOOT CONFIG ENV  ##################################
BOOT_CMD="bootm 0x82000000"
TFTP_BOOT_UIMAGE_DWL="tftpboot 0x82000000 uImage"
TFTP_BOOT_UIMAGE_DWL="tftpboot 0x88000000 uInitrd"
DEFAULT_BBXM_MAC_ADDRESS="22:22:23:54:56:44"
DEFAULT_BBXM_IP_ADDRESS="192.168.1.253" # to improve
#DEFAULT_SERVER_IP_ADDRESS= `for i in $(ifconfig |grep "inet addr"|awk '{print $2}'|cut -d ":" -f 2); do { if [ $i -ne "127.0.0.1" ]; then echo $i fi }; done;`
DEFAULT_SERVER_IP_ADDRESS="192.168.1.252" # to improve
##################################   SCRIPT START     ##################################
install_comp_pkg()
{
for i in $PACKAGE_LIST;
do
  echo "    * Installing package "$i; sudo apt-get install -y $i 1> /dev/null |grep "error" > /dev/null;
  if [ $? == 0 ];
    then echo "error found while installing package" $i;
  fi; done;
}

progressfilt ()
{
    local flag=false c count cr=$'\r' nl=$'\n'
    while IFS='' read -d '' -rn 1 c
    do
        if $flag
        then
            printf '%c' "$c"
        else
            if [[ $c != $cr && $c != $nl ]]
            then
                count=0
            else
                ((count++))
                if ((count > 1))
                then
                    flag=true
                fi
            fi
        fi
    done
}

crosstl_dwl_install_pkg()
{
  echo "    * Download in Progress : "
  wget --progress=bar:force ${TOOLCHAIN_URL}${CROSSTOOL}${TARBALL} 2>&1 | progressfilt
  if [ -f ${CROSSTOOL}${TARBALL} ]
  then
  echo "    * Installing in Progress : "
    pv ${CROSSTOOL}${TARBALL} |tar xjf -
    cd $CROSSTOOL
    echo ""
    ./configure --prefix=/opt/beagleBoard-xM
    make
    sudo make install
    export PATH="/opt/beagleBoard-xM/bin:$PATH"
    cd ..
    mkdir ct-build src
    cd ct-build
    cp $SCRIPT_HOME_DIR/.config .
    ct-ng build
  else
    echo "Failed to DWL file :" ${CROSSTOOL}${TARBALL}
  fi
}

dwl_install_crosstool()
{
echo "   Install Toolchain using Crosstool-NG : "
PKG_DIR=$CROSSTOOL
PKG_TARBALL="${PKG_DIR}.tar.bz2"
PKG_URL="${TOOLCHAIN_URL}${PKG_TARBALL}"
  echo "    * Download in Progress : "
  wget --progress=bar:force $PKG_URL 2>&1 | progressfilt
  if [ -f $PKG_TARBALL ]
  then
  echo "    * Installing in Progress : "
    pv $PKG_TARBALL |tar xjf -
    cd $PKG_DIR
    sh -c "./configure --prefix=/opt/beagleBoard-xM"
    sh -c "make"
    sh -c "sudo make install"
  else
    echo "Failed to DWL file :" $PKG_TARBALL
  fi
}

cfg_BBxM_uboot()
{
  echo "   Configure UBOOT : "
  echo "     * Configure TFTPBOOT: "
  echo "       --> Enter BBxM MAC_ADDRESS :"
  read BBXM_MAC_ADDRESS
  if [ -z "$BBXM_MAC_ADDRESS" ]; then
    echo "       ==> No mac address ? using default :" $DEFAULT_BBXM_MAC_ADDRESS
  else
     if [[ ! "$BBXM_MAC_ADDRESS" =~ "^([0-9a-fA-F][0-9a-fA-F]:){5}([0-9a-fA-F][0-9a-fA-F])$" ]]; then
       echo "       ==> Wrong mac address ? using default :" $DEFAULT_BBXM_MAC_ADDRESS
     else
       echo "       ==> using mac address :" $DEFAULT_BBXM_MAC_ADDRESS
     fi
  fi
  echo "       --> Enter BBxM IP_ADDRESS :"
  read BBXM_IP_ADDRESS
  if [ -z "$BBXM_IP_ADDRESS" ]; then
    echo "       ==> No ip address ? using default :" $DEFAULT_BBXM_IP_ADDRESS
  else
     if [[ ! "$BBXM_IP_ADDRESS" =~ "^([0-9][0-9]|[0-9a][0-9][0_9].){2}([0-9a][0-9]|[0-9a][0-9][0_9])$" ]]; then
       echo "       ==> Wrong ip address ? using default :" $DEFAULT_BBXM_IP_ADDRESS
     else
       echo "       ==> using ip address :" $DEFAULT_BBXM_IP_ADDRESS
     fi
  fi
  echo "       --> Enter SERVER IP_ADDRESS :"
  read SERVER_IP_ADDRESS
  if [ -z "$SERVER_IP_ADDRESS" ]; then
    echo "       ==> No ip address ? using default :" $DEFAULT_SERVER_IP_ADDRESS
  else
     if [[ ! "$SERVER_IP_ADDRESS" =~ "^([0-9][0-9]|[0-9a][0-9][0_9].){2}([0-9a][0-9]|[0-9a][0-9][0_9])$" ]]; then
       echo "       ==> Wrong ip address ? using default :" $DEFAULT_SERVER_IP_ADDRESS
     else
       echo "       ==> using ip address :" $DEFAULT_SERVER_IP_ADDRESS
     fi
  fi
}

# Software requirement.
echo ""
echo " |=========================================|"
echo " |  Welcome to BBxM prepare environnement  |"
echo " |=========================================|"
echo ""
echo "   Install path preference : "

if [ $# -ne $EXPECTED_ARGS ]
then
  INSTALL_PATH=$DEFAULT_BEAGLE_BOARD_PATH
  echo "    INSTALL_PATH preferred : none."
  echo "    INSTALL_PATH=$DEFAULT_BEAGLE_BOARD_PATH"
else
  INSTALL_PATH="${1}/beagle"
  echo "    INSTALL_PATH preferred : detected."
  echo "    INSTALL_PATH=$INSTALL_PATH"
fi

sed -i "s/INSTALL_PATH/$(echo $INSTALL_PATH |sed 's/\//\\\//g')/g" ".config"

echo ""
echo "   Install necessary packages for compilation : "
PACKAGE_LIST=$CMP_PKGS;
install_comp_pkg
echo ""
echo "   Install necessary packages for debug : "
PACKAGE_LIST=$DBG_PKGS;
install_comp_pkg
echo ""
mkdir -p $INSTALL_PATH
cd $INSTALL_PATH

crosstl_dwl_install_pkg
PKG_DIR=$CROSSTOOL
PKG_TARBALL="${PKG_DIR}.tar.bz2"
PKG_URL="${TOOLCHAIN_URL}${PKG_TARBALL}"

