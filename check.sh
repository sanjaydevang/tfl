#!/bin/bash

# Define the log file location
LOG_FILE="/home/ubuntu/health_check_report_$(date +%Y-%m-%d).log"

# --- Start of Report ---
echo "Cloudian/MinIO Health Check Report" > $LOG_FILE
echo "Generated on: $(date)" >> $LOG_FILE
echo "-------------------------------------" >> $LOG_FILE
echo "" >> $LOG_FILE

# --- Check 1: Service Process Status ---
echo "--- Service Status ---" >> $LOG_FILE
if pgrep -f "minio server" > /dev/null
then
    echo "MinIO Server Process: RUNNING" >> $LOG_FILE
else
    echo "MinIO Server Process: DOWN" >> $LOG_FILE
fi
echo "" >> $LOG_FILE

# --- Check 2: Disk Space ---
echo "--- Filesystem Disk Space ---" >> $LOG_FILE
df -h / >> $LOG_FILE
echo "" >> $LOG_FILE

# --- Check 3: S3 Bucket Listing ---
echo "--- S3 Bucket Listing ---" >> $LOG_FILE
/usr/local/bin/mc ls myminio >> $LOG_FILE 2>&1
echo "" >> $LOG_FILE

# --- Check 4: Object Count in 'backups' bucket ---
echo "--- Object Count in 'backups' bucket ---" >> $LOG_FILE
# The wc -l command counts the lines, which equals the number of objects
OBJECT_COUNT=$(/usr/local/bin/mc ls myminio/backups | wc -l)
echo "Total objects: $OBJECT_COUNT" >> $LOG_FILE
echo "" >> $LOG_FILE

# --- End of Report ---
echo "-------------------------------------" >> $LOG_FILE
echo "Report finished." >> $LOG_FILE

echo "Health check complete. Report saved to $LOG_FILE"
