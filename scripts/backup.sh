#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# Source the common library
source "$(dirname "$0")/../lib/backup-utils.sh"

# Source config
source "$(dirname "$0")/../config/backup-config.sh"

# R2 Configuration
RCLONE_CONFIG="${RCLONE_CONFIG:-/root/.config/rclone/rclone.conf}"
R2_REMOTE_NAME="${R2_REMOTE_NAME:-r2}"
R2_BUCKET_NAME="${R2_BUCKET_NAME:-your-bucket-name}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

# Convert semicolon-separated ignore patterns to rclone format
if [[ -n "${BACKUP_IGNORE_PATTERNS}" ]]; then
    # Convert semicolons to spaces and prepare exclude arguments
    RCLONE_EXCLUDES=$(echo "$BACKUP_IGNORE_PATTERNS" | sed 's/;/ --exclude /g' | sed 's/^/--exclude /')
else
    RCLONE_EXCLUDES=""
fi

# Check prerequisites
check_prerequisites

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    log_message "ERROR: rclone is not installed. Please install it first."
    exit 1
fi

# Check if rclone config exists
if [ ! -f "$RCLONE_CONFIG" ]; then
    log_message "ERROR: rclone config not found at $RCLONE_CONFIG"
    exit 1
fi

# Create base mount directory
mkdir -p "$MOUNT_BASE"

# Start backup process
log_message "----------------------------------------"
log_message "Starting backup to Cloudflare R2"

# Sync each directory
for mapping in "${BACKUP_DIRS[@]}"; do
    log_message "----"
    # Split the mapping into components
    share_name="${mapping%%=*}"
    dest_dir="${mapping#*=}"
    
    # Create mount point path based on share name
    mount_point="$BACKUP_MOUNT_BASE/${share_name//\//_}"
    
    # Mount the share
    if ! mount_share "$share_name" "$mount_point"; then
        log_message "Skipping backup of $share_name due to mount failure"
        continue
    fi
    
    log_message "Syncing $mount_point to $dest_dir..."
    rclone sync "$mount_point" "$R2_REMOTE_NAME:$R2_BUCKET_NAME/$dest_dir" \
        --progress \
        --transfers 8 \
        --checkers 4 \
        --s3-upload-concurrency 16 \
        --s3-chunk-size 32M \
        --buffer-size 32M \
        --fast-list \
        --stats 10s \
        --stats-one-line \
        $RCLONE_EXCLUDES \
        2>> "$LOG_FILE"

    # Check the exit status
    if [ $? -eq 0 ]; then
        log_message "Sync completed successfully for $mount_point"
    else
        log_message "ERROR: Failed to sync $mount_point"
    fi
    
    # Unmount the share
    unmount_share "$mount_point"
    log_message "----"
done

# Clean up old files in R2 (optional)
log_message "Cleaning up old files..."
rclone delete "$R2_REMOTE_NAME:$R2_BUCKET_NAME" --min-age "${RETENTION_DAYS}d" 2>> "$LOG_FILE"

# Clean up base mount directory if empty
rmdir "$MOUNT_BASE" 2>/dev/null

log_message "Backup process completed" 
log_message "----------------------------------------"