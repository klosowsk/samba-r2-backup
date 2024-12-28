#!/bin/bash

# Read backup directories from environment variable
# If BACKUP_DIRS_CONFIG is not set, use default empty array
if [[ -z "${BACKUP_DIRS_CONFIG}" ]]; then
    BACKUP_DIRS=()
else
    # Convert the semicolon-separated string to array
    IFS=';' read -ra BACKUP_DIRS <<< "$BACKUP_DIRS_CONFIG"
fi

# Validate that we have at least one backup directory configured
if [ ${#BACKUP_DIRS[@]} -eq 0 ]; then
    echo "WARNING: No backup directories configured in BACKUP_DIRS_CONFIG"
fi


