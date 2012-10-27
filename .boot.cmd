echo "Debug: Demo Image Install"
if test "${beaglerev}" = "xMA"; then
echo "Kernel is not ready for 1Ghz limiting to 800Mhz"
setenv mpurate 800
fi
if test "${beaglerev}" = "xMB"; then
echo "Kernel is not ready for 1Ghz limiting to 800Mhz"
setenv mpurate 800
fi
if test "${beaglerev}" = "xMC"; then
echo "Kernel is not ready for 1Ghz limiting to 800Mhz"
setenv mpurate 800
fi
setenv dvimode BBXM_DVI_RESOLUTION-16@60
setenv usbethaddr BBXM_MAC_ADDRESS
setenv serverip SERVER_IP
setenv netmask MASK
setenv ipaddr BBXM_IP
setenv vram 12MB
setenv bootcmdLKI 'mmc init; fatload mmc 0:1 0x80300000 uImage; fatload mmc 0:1 0x81600000 uInitrd; bootm 0x80300000 0x81600000'
setenv bootargs console=ttyO2,115200n8 console=tty0 ip=BBXM_IP rw root=SERVER_IP:/files/beagle/buildroot-2011.11/output/target rootdelay=1 rootfstype=nfs rootflags=noatime,nolock,tcp,rw nwhwconf=device:usb1,hwaddr:b4:cf:db:00:c4:97 ip=BBXM_IP:BBXM_IP:192.168.1.1:255.255.255.0::usb1:off vram=${vram} omapfb.mode=dvi:${dvimode} fixrtc buddy=${buddy} mpurate=${mpurate}
usb start

