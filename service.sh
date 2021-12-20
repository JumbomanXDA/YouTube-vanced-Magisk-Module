#!/system/bin/sh

# Wait till device boot process complets
while [ "$(getprop sys.boot_completed)" != "1" ]; do
	sleep 1
done
sleep 5

# mount Vanced YouTube with official YouTube
chcon u:object_r:apk_data_file:s0 /data/adb/modules/VancedYT/vanced/base.apk

