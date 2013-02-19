#! /bin/sh

#
# File      : prepare-bbx-dev-env.sh
# Author    : Mohamed JAAFAR (mohamet.jaafar@gmail.com)
# Purpose   : easy start script
# WhatNext  :
# version   : alpha
# Reference : http://www.aclevername.com/articles/linux-xilinx-tutorial/crosstool-ng-1.3.2.html
#             http://www.labbookpages.co.uk/electronics/beagleBoard/custom.html
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
              "gettext"
              "subversion"
         )

DBG_PKGS=(    "minicom"
              "xinetd"
              "tftpd"
              "tftp"
         )

DEFAULT_BEAGLE_BOARD_PATH=${HOME}/beagle
CROSSTOOL="crosstool-ng-1.9.1"
TOOLCHAIN_CFG_FL=".crosstool-ng.config"
TFTPBOOT_CFG_FL=".boot.cmd"
BBXM_TFTP_CFG="boot.scr"
TOOLCHAIN_URL="http://crosstool-ng.org/download/crosstool-ng/"
TARBALL=".tar.bz2"
SCRIPT_HOME_DIR=$PWD
ECHO="/bin/echo -e" # works under Linux.
COLOR=0             # with screen, tee and friends put 1 here (i.e. no color)
CFG_FL=".config"
UBOOT="u-boot-2010.12-rc3"
UBOOT_URL="ftp://ftp.denx.de/pub/u-boot/"
KERNEL="linux-2.6.36.2"
KERNEL_URL="http://www.kernel.org/pub/linux/kernel/v2.6/"
KERNEL_CFG_FL=".kernel.config"
BUILDROOT_CFG_FL=".buildroot.config"
MLO="MLO"
MLO_URL="http://www.angstrom-distribution.org/demo/beagleboard/"
BUILDROOT="buildroot-2011.11"
BUILDROOT_URL="http://www.buildroot.org/downloads/"
##################################  UBOOT CONFIG ENV  ##################################
TFTP_BOOT_UIMAGE_DWL="tftpboot 0x82000000 uImage"
TFTP_BOOT_UINITRD_DWL="tftpboot 0x88000000 uInitrd"
BOOT_CMD="bootm 0x82000000"
DEFAULT_BBXM_MAC_ADDRESS="22:22:23:54:56:44"
DEFAULT_BBXM_IP_ADDRESS="192.168.1.253" # to improve
#DEFAULT_SERVER_IP_ADDRESS= `for i in $(ifconfig |grep "inet addr"|awk '{print $2}'|cut -d ":" -f 2); do { if [ $i -ne "127.0.0.1" ]; then echo $i fi }; done;`
DEFAULT_SERVER_IP_ADDRESS="192.168.1.252" # to improve
DEFAULT_NETMASK="255.255.255.0"
DEFAULT_BBXM_DVI_RESOLUTION="640x480-16@60"
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

function valid_netmask()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 256 && ${ip[1]} -le 256 \
            && ${ip[2]} -le 256 && ${ip[3]} -le 256 ]]
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

dwl_pkg()
{
  local pkg=$1
  local pkg_url=$2
  local pkg_type=$3
  local stat=1
  blue "    * Download in Progress : "
  blue "       --> PKG : " ${pkg}
  wget --progress=bar:force ${pkg_url}${pkg}${pkg_type} 2>&1 | progressfilt
  if [ -f ${pkg}${pkg_type} ]; then
  blue "    * Unpacking in Progress : "
    pv ${pkg}${pkg_type} |tar xjf - 2> /dev/null
    stat=$?
  fi
 return $stat

}

crosstl_dwl_install_pkg()
{

  blue "   Configure : " $CROSSTOOL
  if dwl_pkg $CROSSTOOL $TOOLCHAIN_URL $TARBALL; then
    cd $CROSSTOOL
    echo ""
    blue "    * Configure in Progress : "
    ./configure --prefix=/opt/beagleBoard-xM
    make
    sudo make install
    export PATH="/opt/beagleBoard-xM/bin:$PATH"
    cd ..
    mkdir ct-build src
    cd ct-build
    cp $SCRIPT_HOME_DIR/${TOOLCHAIN_CFG_FL} ${CFG_FL}
    ct-ng build
  else
    red "Failed to DWL file :" ${CROSSTOOL}${TARBALL}
  fi
}

uboot_dwl_install_pkg()
{
  blue "   Configure : " $UBOOT
  if dwl_pkg $UBOOT $UBOOT_URL $TARBALL; then
    cd $UBOOT
    blue "    * Configure in Progress : "
    echo ""
    export CROSS_COMPILE=arm-unknown-linux-gnueabi-
    export PATH=${INSTALL_PATH}"/x-tools/bin:$PATH"
    make distclean
    make omap3_beagle_config
    make
    sudo cp ${INSTALL_PATH}"/"${UBOOT}"/tools/mkimage" "/opt/beagleBoard-xM/bin"
    export PATH="/opt/beagleBoard-xM/bin:$PATH"
  else
    red "Failed to DWL file :" ${UBOOT}${TARBALL}
  fi

}

kernel_dwl_install_pkg()
{
  blue "   Configure : " $KERNEL
  if dwl_pkg $KERNEL $KERNEL_URL $TARBALL; then
    cd $KERNEL
    blue "    * Configure in Progress : "
    echo ""
    cp ${SCRIPT_HOME_DIR}"/"${KERNEL_CFG_FL} ${CFG_FL}
    make ARCH=arm menuconfig
    export CROSS_COMPILE=arm-unknown-linux-gnueabi-
    export PATH=${INSTALL_PATH}"/x-tools/bin:$PATH"
    make -j3 ARCH=arm uImage
    cp ${INSTALL_PATH}"/"${KERNEL}"/"arch/arm/boot/uImage ${INSTALL_PATH}
  else
    red "Failed to DWL file :" ${KERNEL}${TARBALL}
  fi

}

buildroot_dwl_install_pkg()
{
  blue "   Configure : " $BUILDROOT
  if dwl_pkg $BUILDROOT $BUILDROOT_URL $TARBALL; then
    umask 022
    cd $BUILDROOT
    blue "    * Configure in Progress : "
    echo ""
    cp ${SCRIPT_HOME_DIR}"/"${BUILDROOT_CFG_FL} ${CFG_FL}
    sed -i "s/INSTALL_PATH/$(echo $INSTALL_PATH |sed 's/\//\\\//g')/g" ${CFG_FL}
    make menuconfig
    make
  else
    red "Failed to DWL file :" ${BUILDROOT}${TARBALL}
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
    BBXM_MAC_ADDRESS=$DEFAULT_BBXM_MAC_ADDRESS
  else
     if valid_mac $BBXM_MAC_ADDRESS; then
       green "       ==> using mac address :" $BBXM_MAC_ADDRESS
     else
       red "       ==> Wrong mac address ? using default :" $DEFAULT_BBXM_MAC_ADDRESS
       BBXM_MAC_ADDRESS=$DEFAULT_BBXM_MAC_ADDRESS
     fi
  fi

  echo "       --> Enter BBxM IP_ADDRESS :"
  read BBXM_IP_ADDRESS
  if [ -z "$BBXM_IP_ADDRESS" ]; then
    orange "       ==> No ip address ? using default :" $DEFAULT_BBXM_IP_ADDRESS
    BBXM_IP_ADDRESS=$DEFAULT_BBXM_IP_ADDRESS
  else
    if valid_ip $BBXM_IP_ADDRESS; then
       green "       ==> using ip address :" $BBXM_IP_ADDRESS
     else
       red "       ==> Wrong ip address ? using default :" $DEFAULT_BBXM_IP_ADDRESS
       BBXM_IP_ADDRESS=$DEFAULT_BBXM_IP_ADDRESS
     fi
  fi

  echo "       --> Enter SERVER IP_ADDRESS :"
  read SERVER_IP_ADDRESS
  if [ -z "$SERVER_IP_ADDRESS" ]; then
    orange "       ==> No ip address ? using default :" $DEFAULT_SERVER_IP_ADDRESS
    SERVER_IP_ADDRESS=$DEFAULT_SERVER_IP_ADDRESS
  else
    if valid_ip $SERVER_IP_ADDRESS; then
       green "       ==> using ip address :" $SERVER_IP_ADDRESS
     else
       red "       ==> Wrong ip address ? using default :" $DEFAULT_SERVER_IP_ADDRESS
       SERVER_IP_ADDRESS=$DEFAULT_SERVER_IP_ADDRESS
     fi
  fi

  echo "       --> Enter NETWORK_MASK      :"
  read NETWORK_MASK
  if [ -z "$NETWORK_MASK" ]; then
    orange "       ==> No network mask? using default :" $DEFAULT_NETMASK
    NETWORK_MASK=$DEFAULT_NETMASK
  else
    if valid_netmask $NETWORK_MASK; then
       green "       ==> using network mask :" $NETWORK_MASK
     else
       red "       ==> Wrong ip network mask ? using default :" $DEFAULT_NETMASK
       NETWORK_MASK=$DEFAULT_NETMASK
     fi
  fi

  cp ${SCRIPT_HOME_DIR}"/"${TFTPBOOT_CFG_FL} ${INSTALL_PATH}
  echo "       --> Patching BeagleBoardxM TFTPBOOT environnement"
  echo "           ==> Warning the DVI mode supported is 640x480-16@60"
  sed -i "s/BBXM_MAC_ADDRESS/$(echo $BBXM_MAC_ADDRESS |sed 's/\//\\\//g')/g" ${TFTPBOOT_CFG_FL}
  sed -i "s/SERVER_IP/$(echo $SERVER_IP_ADDRESS |sed 's/\//\\\//g')/g" ${TFTPBOOT_CFG_FL}
  sed -i "s/BBXM_IP/$(echo $BBXM_IP_ADDRESS |sed 's/\//\\\//g')/g" ${TFTPBOOT_CFG_FL}
  sed -i "s/NETMASK/$(echo $NETWORK_MASK |sed 's/\//\\\//g')/g" ${TFTPBOOT_CFG_FL}
  sed -i "s/BBXM_DVI_RESOLUTION/$(echo $DEFAULT_BBXM_DVI_RESOLUTION |sed 's/\//\\\//g')/g" ${TFTPBOOT_CFG_FL}
  sed -i "s/INSTALL_PATH/$(echo $INSTALL_PATH |sed 's/\//\\\//g')/g" ${TFTPBOOT_CFG_FL}
  echo $TFTP_BOOT_UIMAGE_DWL  >> ${TFTPBOOT_CFG_FL}
  echo $TFTP_BOOT_UINITRD_DWL >> ${TFTPBOOT_CFG_FL}
  echo $BOOT_CMD              >> ${TFTPBOOT_CFG_FL}
  mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n 'Boot script' -d ${TFTPBOOT_CFG_FL} ${BBXM_TFTP_CFG}
  dwl_pkg $MLO
}

##################################   SCRIPT START     ##################################
yellow ""
yellow " |=========================================|"
yellow " |  Welcome to BBxM prepare environnement  |"
yellow " |=========================================|"
yellow ""
yellow "   Install path preference : "

chk_parms $# $1


sed -i "s/INSTALL_PATH/$(echo $INSTALL_PATH |sed 's/\//\\\//g')/g" ${TOOLCHAIN_CFG_FL}

blue ""
blue "   Install necessary packages for compilation : "
install_comp_pkg CMP_PKGS

blue ""
blue "   Install necessary packages for debug : "
install_comp_pkg DBG_PKGS

echo ""
mkdir -p $INSTALL_PATH
cd $INSTALL_PATH

#TOOLCHAIN_CFG
crosstl_dwl_install_pkg
cd $INSTALL_PATH

#UBOOT_CFG
uboot_dwl_install_pkg
cd $INSTALL_PATH

#UBOOT_ENV
cfg_BBxM_uboot
cd $INSTALL_PATH

#KERNEL_CFG
kernel_dwl_install_pkg
cd $INSTALL_PATH

#BUILDROOT_CFG
buildroot_dwl_install_pkg
cd $INSTALL_PATH
