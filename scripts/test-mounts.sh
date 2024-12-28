#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# Source the common library
source "$(dirname "$0")/../lib/backup-utils.sh"

# Source config
source "$(dirname "$0")/../config/backup-config.sh"

# Check prerequisites
check_prerequisites

# Create base mount directory
 log_message "----------------------------------------"
log_message "Creating base mount directory: $MOUNT_BASE"
mkdir -p "$MOUNT_BASE"

# Start testing process
log_message "Starting Samba connection tests"
log_message "Using server: $SMB_SERVER"

# Test each share
for mapping in "${BACKUP_DIRS[@]}"; do
    # Split the mapping into components
    share_name="${mapping%%=*}"
   
    # Create mount point path based on share name
    mount_point="$BACKUP_MOUNT_BASE/${share_name//\//_}"
    
    log_message "----"
    log_message "Testing share: $share_name"
    log_message "Mount point: $mount_point"
    log_message "Full SMB path: //$SMB_SERVER/$share_name"
    
    # Try to mount
    if mount_share "$share_name" "$mount_point"; then
        # Test if we can read the directory
        if ls "$mount_point" > /dev/null 2>&1; then
            log_message "✓ Successfully read directory contents"
        else
            log_message "✗ Could not read directory contents"
        fi
        
        # Wait a moment to ensure stable mount
        sleep 2
        
        # Try to unmount
        unmount_share "$mount_point"
    fi
    
    log_message "----"
done

# Clean up base mount directory if empty
if rmdir "$MOUNT_BASE" 2>/dev/null; then
    log_message "Cleaned up base mount directory"
fi

log_message "All tests completed" 
 log_message "----------------------------------------"