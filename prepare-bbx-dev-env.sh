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

CMP_PKGS=(    "automake"
              "bison"
              "curl"
              "cvs"
              "flex"
              "g++"
              "gawk"
              "libncurses5-dev"
              "libtool"
              "texinfo"
         )

DBG_PKGS=(    "minicom"
              "xinetd"
              "tftpd"
              "tftp"
         )

DEFAULT_BEAGLE_BOARD_PATH=${HOME}/beagle
CROSSTOOL="crosstool-ng-1.9.1"
TOOLCHAIN_URL="http://crosstool-ng.org/download/crosstool-ng/"
TARBALL=".tar.bz2"
SCRIPT_HOME_DIR=$PWD
ECHO="/bin/echo -e" # works under Linux.
COLOR=0             # with screen, tee and friends put 1 here (i.e. no color)

##################################  UBOOT CONFIG ENV  ##################################
BOOT_CMD="bootm 0x82000000"
TFTP_BOOT_UIMAGE_DWL="tftpboot 0x82000000 uImage"
TFTP_BOOT_UIMAGE_DWL="tftpboot 0x88000000 uInitrd"
DEFAULT_BBXM_MAC_ADDRESS="22:22:23:54:56:44"
DEFAULT_BBXM_IP_ADDRESS="192.168.1.253" # to improve
#DEFAULT_SERVER_IP_ADDRESS= `for i in $(ifconfig |grep "inet addr"|awk '{print $2}'|cut -d ":" -f 2); do { if [ $i -ne "127.0.0.1" ]; then echo $i fi }; done;`
DEFAULT_SERVER_IP_ADDRESS="192.168.1.252" # to improve

###################################### FUNCTIONS ######################################
# some functions for text:
off() {
  if [ $COLOR = 0 ]; then $ECHO "\033[0;37m "; fi
}

blue() {
  if [ $COLOR = 0 ]; then $ECHO "\033[1;34m$* "; else $ECHO "$* "; fi
  off
}

yellow() {
  if [ $COLOR = 0 ]; then $ECHO "\033[1;33m$* "; else $ECHO "$* "; fi
  off
}

red() {
  if [ $COLOR = 0 ]; then $ECHO "\033[1;31m$* "; else $ECHO "**$*** "; fi
  off
}

orange() {
  if [ $COLOR = 0 ]; then $ECHO "\033[5;33m$* "; else $ECHO "$* "; fi
  off
}

green() { 
  if [ $COLOR = 0 ]; then $ECHO "\033[1;32m$* "; else $ECHO "$* "; fi
  off
}

bold() {
  $ECHO "\033[1m$1"
  off
}

chk_parms()
{
  local PARAMS_NUM=$1
  local PREF_DIR_INSTALL=$2

  if [ $PARAMS_NUM -ne $EXPECTED_ARGS ]
  then
    INSTALL_PATH=$DEFAULT_BEAGLE_BOARD_PATH
    orange "    INSTALL_PATH preferred : none."
    orange "    INSTALL_PATH=$DEFAULT_BEAGLE_BOARD_PATH"
  else
    INSTALL_PATH="${PREF_DIR_INSTALL}/beagle"
    green "    INSTALL_PATH preferred : detected."
    green "    INSTALL_PATH=$INSTALL_PATH"
  fi
}

function install_comp_pkg
{
  # Setting the shell's Internal Field Separator to null
  OLD_IFS=$IFS
  IFS=''
  local array_string="$1[*]"
  local pkg_list=(${!array_string})
  IFS=$OLD_IFS
  idx=1

  for item in ${pkg_list[*]};
  do
  echo "    * Installing package "$item; sudo apt-get install -y $item 1> /dev/null |grep "error" > /dev/null;
  if [ $? == 0 ];
    then red "error found while installing package" $item;
  fi;
  done;
}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function valid_mac()
{
    local  mac=$1
    local  stat=1
    if [[ $mac =~ ^([0-9a-fA-F][0-9a-fA-F]:){5}([0-9a-fA-F][0-9a-fA-F])$ ]]; then
        OIFS=$IFS
        IFS=':'
        mac=($mac)
        IFS=$OIFS
       stat=$?
    fi
    return $stat
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
  blue "    * Download in Progress : "
  wget --progress=bar:force ${TOOLCHAIN_URL}${CROSSTOOL}${TARBALL} 2>&1 | progressfilt
  if [ -f ${CROSSTOOL}${TARBALL} ]
  then
  blue "    * Installing in Progress : "
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
    red "Failed to DWL file :" ${CROSSTOOL}${TARBALL}
  fi
}

dwl_install_crosstool()
{
echo "   Install Toolchain using Crosstool-NG : "
PKG_DIR=$CROSSTOOL
PKG_TARBALL="${PKG_DIR}.tar.bz2"
PKG_URL="${TOOLCHAIN_URL}${PKG_TARBALL}"
  blue "    * Download in Progress : "
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
    red "Failed to DWL file :" $PKG_TARBALL
  fi
}

cfg_BBxM_uboot()
{
  echo "   Configure UBOOT : "
  echo "     * Configure TFTPBOOT: "
  echo "       --> Enter BBxM MAC_ADDRESS :"
  read BBXM_MAC_ADDRESS
  if [ -z "$BBXM_MAC_ADDRESS" ]; then
    orange "       ==> No mac address ? using default :" $DEFAULT_BBXM_MAC_ADDRESS
  else
     if valid_mac $BBXM_MAC_ADDRESS; then
       green "       ==> using mac address :" $BBXM_MAC_ADDRESS
     else
       red "       ==> Wrong mac address ? using default :" $DEFAULT_BBXM_MAC_ADDRESS
     fi
  fi
  echo "       --> Enter BBxM IP_ADDRESS :"
  read BBXM_IP_ADDRESS
  if [ -z "$BBXM_IP_ADDRESS" ]; then
    orange "       ==> No ip address ? using default :" $DEFAULT_BBXM_IP_ADDRESS
  else
    if valid_ip $BBXM_IP_ADDRESS; then
       green "       ==> using ip address :" $BBXM_IP_ADDRESS
     else
       red "       ==> Wrong ip address ? using default :" $DEFAULT_BBXM_IP_ADDRESS
     fi
  fi
  echo "       --> Enter SERVER IP_ADDRESS :"
  read SERVER_IP_ADDRESS
  if [ -z "$SERVER_IP_ADDRESS" ]; then
    orange "       ==> No ip address ? using default :" $DEFAULT_SERVER_IP_ADDRESS
  else
    if valid_ip $SERVER_IP_ADDRESS; then
       green "       ==> using ip address :" $SERVER_IP_ADDRESS
     else
       red "       ==> Wrong ip address ? using default :" $DEFAULT_SERVER_IP_ADDRESS
     fi
  fi
}

##################################   SCRIPT START     ##################################
yellow ""
yellow " |=========================================|"
yellow " |  Welcome to BBxM prepare environnement  |"
yellow " |=========================================|"
yellow ""
yellow "   Install path preference : "

chk_parms $# $1


sed -i "s/INSTALL_PATH/$(echo $INSTALL_PATH |sed 's/\//\\\//g')/g" ".config"

blue ""
blue "   Install necessary packages for compilation : "
install_comp_pkg CMP_PKGS

blue ""
blue "   Install necessary packages for debug : "
install_comp_pkg DBG_PKGS

echo ""
mkdir -p $INSTALL_PATH
cd $INSTALL_PATH

crosstl_dwl_install_pkg
PKG_DIR=$CROSSTOOL
PKG_TARBALL="${PKG_DIR}.tar.bz2"
PKG_URL="${TOOLCHAIN_URL}${PKG_TARBALL}"

