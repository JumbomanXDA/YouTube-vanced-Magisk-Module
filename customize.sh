#!/system/bin/sh

# Checking for installation environment
# Abort TWRP installation with error message when user tries to install this module in TWRP
if [ $BOOTMODE = false ]; then
	ui_print "- Installing through TWRP Not supported"
	ui_print "- Intsall this module via Magisk Manager"
	abort "- ! Aborting installation !"
fi


ui_print "- Installing YouTube Vanced v17.03.38"

# Uninstall YouTube app
# Keep the data and cache directories around after package removal [-k]
# User with multiple "Work Profiles", YouTube is uninstalled for main user only [--user 0]
PK=com.google.android.youtube
PACKAGE=$(pm list packages | grep $PK | head -n 1 | cut -d ":" -f2-)

if [ "$PACKAGE" = "$PK" ]; then
	if [ -d /data/adb/modules/VancedYT ]; then
		pm uninstall -k $PK > /dev/null 2>&1
	elif [ -d /data/adb/Vanced ]; then
		pm uninstall $PK > /dev/null 2>&1
		rm -rf /data/adb/post-fs-data.d/vanced.sh
		rm -rf /data/adb/service.d/vanced.sh
		rm -rf /data/adb/Vanced
	else
		pm uninstall --user 0 $PK > /dev/null 2>&1
	fi
fi


# Theme configuration
mkdir -p $MODPATH/vanced
SDcard=/storage/emulated/0
if [[ -e $SDcard/ytdark* || -e $SDcard/Ytdark* || -e $SDcard/YTDARK* ]]; then
	mv -f $MODPATH/Theme/dark.apk $MODPATH/vanced/base.apk
	ui_print "- Dark theme selected"
elif [[ -e $SDcard/ytblack* || -e $SDcard/Ytblack* || -e $SDcard/YTBLACK* ]]; then
	mv -f $MODPATH/Theme/black.apk $MODPATH/vanced/base.apk
	ui_print "- Black theme selected"
else
	mv -f $MODPATH/Theme/black.apk $MODPATH/vanced/base.apk
	ui_print "- Dark theme selected [Default Theme]"
fi


# Install official YouTube app [base + split apk's]
Install_Official_YouTube() {
# Change Directory
cd $MODPATH/YouTube

# Get Total size of all apk's
# ls -l | awk '{s+=$5} END {print s}'
Total_Size=$(ls -l | awk '{print $5}' | awk '{s+=$1} END {print s}')

# Get Session ID
ID=$(pm install-create -S $Total_Size | sed 's/.*\[//g;s/\]//g')

# Prepare for stagging apk's
#pm install-write -S $APK_SIZE $ID $INDEX $APK_PATH
ls -l | sed '1d' | awk '{print $5,NR-1,$9}' | sed 's/^/pm install-write -S /' | sed 's/ / '"$ID"' /4' > $MODPATH/stagging_apks

# Stage all apk's
sh $MODPATH/stagging_apks > /dev/null 2>&1

# Commit for installation
pm install-commit $ID > /dev/null 2>&1
}
Install_Official_YouTube


# mount Vanced YouTube with official YouTube
ui_print "- Mounting YouTube Vanced"
PK_Path=$(pm path $PK | cut -d ":" -f2- | grep "base.apk")
echo "mount -o bind /data/adb/modules/VancedYT/vanced/base.apk $PK_Path" >> $MODPATH/service.sh


# Instant mount
chcon u:object_r:apk_data_file:s0 $MODPATH/vanced/base.apk
mount -o bind $MODPATH/vanced/base.apk $PK_Path


# Detach script - Disable Play store updates for vanced YouTube
sleep 1
ui_print "- Adding Detach script for YouTube Vanced"
cat $MODPATH/detach >> $MODPATH/service.sh


# Set proper Permissions for /bin folder
set_perm_recursive $MODPATH/system/bin 0 0 0755 0755


# Instant Detach
PS=com.android.vending
LDB=/data/data/$PS/databases/library.db
LADB=/data/data/$PS/databases/localappstate.db
cmd appops set --uid $PS GET_USAGE_STATS ignore
pm disable $PS > /dev/null 2>&1
$MODPATH/system/bin/sqlite3 $LDB "UPDATE ownership SET doc_type = '25' WHERE doc_id = '$PK'";
$MODPATH/system/bin/sqlite3 $LADB "UPDATE appstate SET auto_update = '2' WHERE package_name = '$PK'";
rm -rf /data/data/$PS/cache/*
pm enable $PS > /dev/null 2>&1


# Uninstall Script
mv -f $MODPATH/VancedYT-uninstall.sh /data/adb/service.d/VancedYT-uninstall.sh
chmod +x /data/adb/service.d/VancedYT-uninstall.sh


# Disable battery optimization for YouTube vanced
sleep 1
ui_print "- Disable Battery Optimization for YouTube vanced"
dumpsys deviceidle whitelist +$PK > /dev/null 2>&1


# Remove Leftovers
for i in $MODPATH/Theme $MODPATH/YouTube $MODPATH/detach $MODPATH/stagging_apks
do
	rm -rf $i > /dev/null 2>&1
done

# Note to other developers who are looking at this script.
# Tell me if you have any suggestions, ideas, improvements etc.

