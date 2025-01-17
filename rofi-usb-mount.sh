#!/bin/bash

rofi_cmd='rofi -dmenu show run -lines 5 -opacity "85" -bw 0 -width 30 -padding 20 -i'
usb_re='sd[b-z]\|mmcblk'

usbcheck(){ \
    mounteddrives="$(lsblk -rpo "name,type,size,mountpoint" | grep $usb_re | awk '$2=="part"&&$4!=""{printf "%s (%s)\t  ",$1,$3}')"
    if [ $(echo "$mounteddrives" | wc -w) -gt 0 ]; then
        echo "  #  $mounteddrives"
    else
        if [ $(echo "$usbdrives" | wc -w) -gt 0 ]; then
            echo "  #  "
        else
            echo ""
        fi
    fi
}

mountusb(){ \
    chosen=$(echo "$usbdrives" | $rofi_cmd -p "Mount which drive?" | awk '{print $1}')
    mountpoint=$(udisksctl mount --no-user-interaction -b "$chosen" 2>/dev/null) && notify-send "💻 USB mounting" "$chosen mounted to $mountpoint" && exit 0

}

umountusb(){ \
    chosen=$(echo "$mounteddrives" | $rofi_cmd -p "Unmount which drive?" | awk '{print $1}')
    mountpoint=$(udisksctl unmount --no-user-interaction -b "$chosen" 2>/dev/null) && notify-send "💻 USB unmounting" "$chosen mounted" && exit 0
    udisksctl power-off --no-user-interaction -b "$chosen"
}

umountall(){ \
    for chosen in $(echo $(lsblk -rpo "name,type,size,mountpoint" | grep $usb_re | awk '$2=="part"&&$4!=""{printf "%s\n",$1}')); do
        udisksctl unmount --no-user-interaction -b "$chosen"
        udisksctl power-off --no-user-interaction -b "$chosen"
    done
}


usbdrives="$(lsblk -rpo "name,type,size,mountpoint" | grep $usb_re | awk '$2=="part"&&$4==""{printf "%s (%s)\n",$1,$3}')"
mounteddrives="$(lsblk -rpo "name,type,size,mountpoint" | grep $usb_re | awk '$2=="part"&&$4!=""{printf "%s (%s)\n",$1,$3}')"

case "$1" in
    --check)
        usbcheck
        ;;
    --mount)
        if [ $(echo "$usbdrives" | wc -w) -gt 0 ]; then
            notify-send "USB drive(s) detected."
            mountusb
        else
            notify-send "No USB drive(s) detected." && exit
        fi
        ;;
    --umount)
        if [ $(echo "$mounteddrives" | wc -w) -gt 0 ]; then
            notify-send "USB drive(s) detected."
            umountusb
        else
            notify-send "No USB drive(s) to unmount." && exit
        fi
        ;;
    --umount-all)
        if [ $(echo "$mounteddrives" | wc -w) -gt 0 ]; then
            notify-send "Unmounting all USB drives."
            umountall
        else
            notify-send "No USB drive(s) to unmount." && exit
        fi
        ;;
    *)
        mode="$(echo $'Mount...\nUnmount...\nUnmount all' | $rofi_cmd -p "USB menu")"
        case "$mode" in
            "Mount...") $0 --mount ;;
            "Unmount...") $0 --umount ;;
            "Unmount all") $0 --umount-all ;;
        esac
        ;;
esac
