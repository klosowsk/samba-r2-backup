#!/bin/bash

# Common Configuration
MOUNT_BASE="${BACKUP_MOUNT_BASE:-/tmp/backup_mounts}"
LOG_FILE="${BACKUP_LOG_FILE:-/var/log/backup.log}"

# Samba connection details (only server is required)
if [[ -z "$SMB_SERVER" ]]; then
    echo "ERROR: SMB_SERVER environment variable not set."
    exit 1
fi

# Detect OS type
OS_TYPE="$(uname -s)"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to mount a Samba share
mount_share() {
    local share_name="$1"
    local mount_point="$2"
    
    # Create mount point if it doesn't exist
    if mkdir -p "$mount_point"; then
        log_message "Created mount point: $mount_point"
    else
        log_message "ERROR: Failed to create mount point: $mount_point"
        return 1
    fi
    
    # Mount the share based on OS type
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        # macOS mount command
        log_message "Using macOS mount command"
        if [[ -n "$SMB_USER" ]] && [[ -n "$SMB_PASS" ]]; then
            log_message "Command: mount_smbfs '//$SMB_USER:****@$SMB_SERVER/$share_name' '$mount_point'"
            mount_smbfs "//$SMB_USER:$SMB_PASS@$SMB_SERVER/$share_name" "$mount_point" 2>> "$LOG_FILE"
        else
            log_message "Command: mount_smbfs '//$SMB_SERVER/$share_name' '$mount_point'"
            mount_smbfs "//guest@$SMB_SERVER/$share_name" "$mount_point" 2>> "$LOG_FILE"
        fi
    else
        # Linux mount command
        log_message "Using Linux mount command"
        local mount_opts="vers=3.0"
        if [[ -n "$SMB_USER" ]] && [[ -n "$SMB_PASS" ]]; then
            mount_opts="${mount_opts},username=$SMB_USER,password=$SMB_PASS"
        else
            mount_opts="${mount_opts},guest"
        fi
        log_message "Command: mount -t cifs '//$SMB_SERVER/$share_name' '$mount_point' -o '$mount_opts'"
        mount -t cifs "//$SMB_SERVER/$share_name" "$mount_point" -o "$mount_opts" 2>> "$LOG_FILE"
    fi
    
    if [ $? -eq 0 ]; then
        log_message "✓ Successfully mounted $share_name to $mount_point"
        return 0
    else
        log_message "✗ Failed to mount $share_name to $mount_point"
        return 1
    fi
}

# Function to unmount a share
unmount_share() {
    local mount_point="$1"
    
    log_message "Attempting to unmount $mount_point"
    
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        umount "$mount_point" 2>> "$LOG_FILE"
    else
        umount "$mount_point" 2>> "$LOG_FILE"
    fi
    
    if [ $? -eq 0 ]; then
        log_message "✓ Successfully unmounted $mount_point"
        if rmdir "$mount_point" 2>/dev/null; then
            log_message "✓ Removed mount point directory"
        fi
        return 0
    else
        log_message "✗ Failed to unmount $mount_point"
        return 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    # Check if running as root
    if [ "$(id -u)" != "0" ]; then
        log_message "ERROR: This script must be run as root"
        exit 1
    fi

    # Check for required tools based on OS
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        # macOS doesn't need additional packages
        return 0
    else
        # Linux needs cifs-utils
        if ! command -v mount.cifs &> /dev/null; then
            log_message "ERROR: cifs-utils is not installed. Please install it first."
            log_message "For Debian/Ubuntu: sudo apt-get install cifs-utils"
            log_message "For RHEL/CentOS: sudo yum install cifs-utils"
            log_message "For Alpine: sudo apk add cifs-utils"
            exit 1
        fi
    fi
} 