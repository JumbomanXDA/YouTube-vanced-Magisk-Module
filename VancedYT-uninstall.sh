#!/system/bin/sh

# Wait till device boot process complets
while [ "$(getprop sys.boot_completed)" != "1" ]; do
	sleep 1
done

sleep 2

# If VancedYT module is uninstalled then uninstall YouTube app on next boot
if [[ ! -d /data/adb/modules/VancedYT || -f /data/adb/modules/VancedYT/remove ]]; then
	pm uninstall com.google.android.youtube
	rm -rf /data/adb/service.d/VancedYT-uninstall.sh
fi

# Remove VancedYT module if YouTube app is uninstalled manually by user
PACKAGE=$(pm list packages | grep com.google.android.youtube | head -n 1 | cut -d ":" -f2-)
if [ "$PACKAGE" != "com.google.android.youtube" ]; then
	rm -rf /data/adb/modules/VancedYT
	rm -rf /data/adb/service.d/VancedYT-uninstall.sh
fi


