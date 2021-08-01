#!/system/bin/sh
# Disable Play store updates for vanced YouTube

LDB="/data/data/com.android.vending/databases/library.db"
LADB="/data/data/com.android.vending/databases/localappstate.db"

# Force stop Play store
am force-stop com.android.vending

sqlite3 $LDB "UPDATE ownership SET doc_type = '25' where doc_id = 'com.google.android.youtube'";
sqlite3 $LADB "UPDATE appstate SET auto_update = '2' where package_name = 'com.google.android.youtube'";

# Disable Fallback broadcast
pm disable "com.android.vending/com.google.android.finsky.scheduler.FallbackReceiver"
cmd appops set $VEN RUN_IN_BACKGROUND ignore

# Log
echo "$(date)" > /data/detach_YT.log

