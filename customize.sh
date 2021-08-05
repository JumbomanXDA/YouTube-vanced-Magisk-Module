#!/system/bin/sh

# Checking for installation environment
# Abort TWRP installation with error message when user tries to install this module in TWRP
if [ $BOOTMODE = false ]; then
	ui_print "- Installing through TWRP Not supported"
	ui_print "- Intsall this module via Magisk Manager"
	abort "- ! Aborting installation !"
fi

ui_print "- Installing YouTube vanced"

# Uninstall YouTube app
# Keep the data and cache directories around after package removal [-k]
# User with multiple "Work Profiles", YouTube is uninstalled for main user only [--user 0]
YT=com.google.android.youtube
PACKAGE=$(pm list packages | grep $YT | head -n 1 | cut -d ":" -f2-)
if [ "$PACKAGE" = "$YT" ]; then
	pm uninstall -k --user 0 $YT > /dev/null 2>&1
fi

# Uninstall Official Vanced YouTube
if [ -d /data/adb/Vanced ]; then
	rm -rf /data/adb/post-fs-data.d/vanced.sh
	rm -rf /data/adb/service.d/vanced.sh
	rm -rf /data/adb/Vanced
fi

# SQLite3 and busybox binary
# SQLite3 binary is needed for detach script
if [ "$ARCH" = "arm" ]; then
	mv $MODPATH/sqlite3/sqlite3-arm $MODPATH/system/bin/sqlite3
	mv $MODPATH/busybox/busybox-arm $MODPATH/system/bin/busybox
elif [ "$ARCH" = "arm64" ]; then
	mv $MODPATH/sqlite3/sqlite3-arm64 $MODPATH/system/bin/sqlite3
	mv $MODPATH/busybox/busybox-arm64 $MODPATH/system/bin/busybox
fi
set_perm_recursive $MODPATH/system/bin 0 0 0755 0755

# Install official YouTube app [base + split apk's]
Install_Official_YouTube() {
# Change Directory
cd $MODPATH/YouTube

# Get Total size of all apk's
# ls -l | awk '{s+=$5} END {print s}'
Total_Size=`ls -l | awk '{print $5}' | awk '{s+=$1} END {print s}'`

# Get Session ID
ID=`pm install-create -S $Total_Size | sed 's/.*\[//g;s/\]//g'`

# Prepare for stagging apk's
TMP=$MODPATH/sqlite3
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
ui_print "- Mounting YouTube Vanced"
YT_Path=`pm path $YT | cut -d ":" -f2- | grep "base.apk"`
echo "mount -o bind /data/adb/modules/VancedYT/vanced/base.apk $YT_Path" >> $MODPATH/service.sh

# Instant mount
chcon u:object_r:apk_data_file:s0 $MODPATH/vanced/base.apk
mount -o bind $MODPATH/vanced/base.apk $YT_Path

# Disable Play store updates for vanced YouTube
# Detach script
sleep 1
ui_print "- Adding Detach script for YouTube Vanced"

PS=com.android.vending
LDB=/data/data/$PS/databases/library.db
LADB=/data/data/$PS/databases/localappstate.db

echo "
# Disable Play store updates for YouTube Vanced
# Wait 
sleep 60

LDB=$LDB
LADB=$LADB

GET_LDB=\`sqlite3 \$LDB \"SELECT doc_type,doc_id FROM ownership\" | grep $YT | head -n 1 | grep -o 25\`
GET_LADB=\`sqlite3 \$LADB \"SELECT auto_update,package_name FROM appstate\" | grep $YT | head -n 1 | grep -o 2\`

if [[ \"\$GET_LDB\" != \"25\" || \"\$GET_LADB\" != \"2\" ]]; then
	# Force Disable Play store
	pm disable $PS > /dev/null 2>&1
	
	# Update database
	sqlite3 \$LDB \"UPDATE ownership SET doc_type = '25' where doc_id = '$YT'\"
	sqlite3 \$LADB \"UPDATE appstate SET auto_update = '2' where package_name = '$YT'\"
	
	# Re-enable Play store
	pm enable $PS > /dev/null 2>&1
fi
" >> $MODPATH/service.sh

# Instant Detach
pm disable $PS > /dev/null 2>&1
$MODPATH/system/bin/sqlite3 $LDB "UPDATE ownership SET doc_type = '25' where doc_id = '$YT'"
$MODPATH/system/bin/sqlite3 $LADB "UPDATE appstate SET auto_update = '2' where package_name = '$YT'"
pm enable $PS > /dev/null 2>&1

# Run crond demon on boot
echo "
# Run crond demon on boot
busybox crond -b -c /data/adb/modules/VancedYT/crontabs
" >> $MODPATH/service.sh

# Uninstall Script
# If VancedYT module is uninstalled then
# uninstall YouTube official app on next boot
VancedYT_uninstall=/data/adb/service.d/VancedYT-uninstall.sh
echo "#!/system/bin/sh

# Wait till device boot process complets
while [ \"\$(getprop sys.boot_completed)\" != \"1\" ]; do
	sleep 1
done

sleep 2

# If VancedYT module is uninstalled then uninstall YouTube app on next boot
if [[ ! -d /data/adb/modules/VancedYT || -f /data/adb/modules/VancedYT/remove ]]; then
	pm uninstall $YT
	rm -rf $VancedYT_uninstall
fi

# Remove VancedYT module if YouTube app is uninstalled manually by user
PACKAGE=\$(pm list packages | grep $YT | head -n 1 | cut -d \":\" -f2-)
if [ \"\$PACKAGE\" != \"com.google.android.youtube\" ]; then
	rm -rf /data/adb/modules/VancedYT
	rm -rf $VancedYT_uninstall
fi
" > $VancedYT_uninstall
chmod +x $VancedYT_uninstall

# Disable battery optimization for YouTube vanced
# Reboot the device to apply this setting
sleep 1
ui_print "- Disable Battery Optimization for YouTube vanced"
dumpsys deviceidle whitelist +$YT > /dev/null 2>&1

# Disable MIUI optimization
# This is not required for this module
# This can be done manually
## First enable developer options : Settings --> About phone --> Tap on the MIUI version until it shows "you are now a developer".
## Now go back to Settings main menu
## Settings --> Additional Settings --> Developer Options --> Scroll down to the bottom and turn off "MIUI optimizations".
Disable_MIUI_Optimization() {
if grep -q 'miui' /system/build.prop; then
sleep 1
ui_print "- MIUI Detected. Disable MIUI optimization"
echo "
# Disable MiUI optimization
persist.sys.miui_optimization=false
" >> $MODPATH/system.prop
fi
}
#Disable_MIUI_Optimization


# Remove Leftovers
rm -rf $MODPATH/busybox $MODPATH/sqlite3 $MODPATH/YouTube

# Note to other developers who are looking at this script.
# Tell me if you have any suggestions, ideas, improvements etc.

