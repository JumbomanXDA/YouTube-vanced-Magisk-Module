#!/system/bin/shsh

while [ "$(getprop sys.boot_completed | tr -d '\r')" != "1" ]; do sleep 1; done
sleep 1

# Mount vanced YouTube
chcon u:object_r:apk_data_file:s0 /data/adb/modules/VancedYT/vanced/base.apk
