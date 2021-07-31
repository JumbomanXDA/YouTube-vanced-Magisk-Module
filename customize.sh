#!/system/bin/sh

ui_print "- Installing vanced YouTube"

# Uninstall stock YouTube app
# Keep the data and cache directories around after package removal ( -k )
PACKAGE=$(pm list packages | grep com.google.android.youtube | head -n 1 | cut -d ":" -f2-)
if [ "$PACKAGE" = "com.google.android.youtube" ]; then
	pm uninstall -k --user 0 com.google.android.youtube > /dev/null 2>&1
fi

# Uninstall Official Vanced YouTube
if [ -d /data/adb/Vanced ]; then
	rm -rf /data/adb/post-fs-data.d/vanced.sh
	rm -rf /data/adb/service.d/vanced.sh
	rm -rf /data/adb/Vanced
fi

# sqlite3 binary
mkdir -p $MODPATH/system/bin
if [ "$ARCH" = "arm" ]; then
	mv $MODPATH/sqlite3/sqlite3-arm $MODPATH/system/bin/sqlite3
elif [ "$ARCH" = "arm64" ]; then
	mv $MODPATH/sqlite3/sqlite3-arm64 $MODPATH/system/bin/sqlite3
fi
set_perm $MODPATH/system/bin/sqlite3 0 0 0755

# Install official YouTube client [split apk's]
Install_Official_YouTube() {
# Create TMP directory
TMP=/data/tmp_vanced
rm -rf $TMP > /dev/null 2>&1
mkdir -p $TMP
chmod +x $TMP

# Change Directory
cd $MODPATH/YouTube

# Get Total size of all apk's
Total_Size=`ls -l | awk '{print $5}' | awk '{s+=$1} END {print s}'`

# Get Session ID
ID=`pm install-create -S $Total_Size | sed 's/.*\[//g;s/\]//g'`

# Prepare for stagging apk's
ls -l | awk '{print $5}' | sed '1d' | sed 's/^/pm install-write -S /' | sed 's/$/ '"$ID"'/' | awk '{print $0 " " i++}' > $TMP/pminstall
ls -1 > $TMP/APK_PATH # Get APK_PATH
paste $TMP/pminstall $TMP/APK_PATH -d " " > $TMP/stagging_all_apks # combine all files

# Stage all apk's
#pm install-write -S $APK_SIZE $ID $INDEX $APK_PATH
sh $TMP/stagging_all_apks > /dev/null 2>&1

# Commit for installation
pm install-commit $ID > /dev/null 2>&1
}
Install_Official_YouTube

# mount Vanced YouTube with official YouTube
ui_print "- Mounting Vanced YouTube"
YT=`pm path com.google.android.youtube | cut -d ":" -f2- | grep "base.apk"`
echo "mount -o bind /data/adb/modules/VancedYT/vanced/base.apk $YT" >> $MODPATH/service.sh
chcon u:object_r:apk_data_file:s0 $MODPATH/vanced/base.apk
mount -o bind $MODPATH/vanced/base.apk $YT

# Disable Play store updates for vanced YouTube
# Detach script
ui_print "- Adding Detach script for vanced YouTube"

echo "
# Disable Play store updates for vanced YouTube
# Wait 
sleep 60

LDB=\"/data/data/com.android.vending/databases/library.db\"
LADB=\"/data/data/com.android.vending/databases/localappstate.db\"

# Force stop Play store
am force-stop com.android.vending

sqlite3 \$LDB \"UPDATE ownership SET doc_type = '25' where doc_id = 'com.google.android.youtube'\";
sqlite3 \$LADB \"UPDATE appstate SET auto_update = '2' where package_name = 'com.google.android.youtube'\";

# Disable Fallback broadcast
pm disable \"\$VEN/com.google.android.finsky.scheduler.FallbackReceiver\"
cmd appops set \$VEN RUN_IN_BACKGROUND ignore
" >> $MODPATH/service.sh

# Uninstall Script
# If VancedYT module is uninstalled then
# uninstall YouTube official app on next boot
echo "#!/system/bin/sh

# Wait till device boot process complets
while [ \"\$(getprop sys.boot_completed)\" != \"1\" ]; do
	sleep 1
done

sleep 2

# If VancedYT module is uninstalled then uninstall YouTube app on next boot
if [[ ! -d /data/adb/modules/VancedYT || -f /data/adb/modules/VancedYT/remove ]]; then
	pm uninstall com.google.android.youtube
	rm -rf /data/adb/service.d/VancedYT-uninstall.sh
fi

# Remove VancedYT module if YouTube app is uninstalled manually by user
PACKAGE=\$(pm list packages | grep com.google.android.youtube | head -n 1 | cut -d \":\" -f2-)
if [ \"\$PACKAGE\" != \"com.google.android.youtube\" ]; then
	rm -rf /data/adb/modules/VancedYT
	rm -rf /data/adb/service.d/VancedYT-uninstall.sh
fi
" > /data/adb/service.d/VancedYT-uninstall.sh

chmod +x /data/adb/service.d/VancedYT-uninstall.sh

# Remove Junk
rm -rf $TMP
rm -rf $MODPATH/sqlite3
rm -rf $MODPATH/YouTube

