# SMB to R2 Backup Script

🔄 A simple automated script to automatically backup Samba/CIFS network shares to Cloudflare R2 storage. Originally created to backup homelab machines and NAS devices to cloud storage for disaster recovery.

Features:
- 🐧 Supports both Linux and macOS systems
- 🔑 Handles authenticated and guest SMB access
- 📁 Flexible directory mapping
- ⚙️ Environment-based configuration
- 🚫 Configurable file exclusions
- 📝 Detailed logging

Ideal for backing up Proxmox, Synology, TrueNAS, and other Samba-compatible devices to Cloudflare R2.

## Files

- `scripts/backup.sh` - The main script to backup SMB shares to R2
- `scripts/test-mounts.sh` - Test SMB connectivity before running backups
- `config/backup-config.sh` - Configuration for backup paths, Samba, and R2
- `lib/backup-utils.sh` - Common functions for backup operations

## Prerequisites

### Linux

- `cifs-utils` (for Linux)
- `mount.cifs` (for Linux)
- `rclone` (for Linux)

### macOS

- `mount_smbfs` (for macOS)
- `rclone` (for macOS)

## Usage

1. Copy `.env.example` to `.env` and set your environment variables
2. Run `chmod +x scripts/*.sh` to make the scripts executable
3. Run `sudo ./scripts/test-mounts.sh` to test SMB connectivity
4. Run `sudo ./scripts/backup.sh` to backup your shares to R2

## Homelab Use Case

Perfect for backing up:
- Home servers
- NAS devices
- Network storage shares
- VM backups
- Docker volumes
- Configuration files

## Notes

- Tests SMB connectivity before running backups
- Supports both authenticated and guest SMB access
- Works with any Samba-compatible device (Proxmox CIFS/SMB Storage, Synology, TrueNAS, etc.)
- Uses rclone for efficient cloud transfers
- Environment variables keep credentials secure

## Environment Variables Explanation

### Backup Path Settings
- `BACKUP_MOUNT_BASE`: The local directory where SMB shares will be temporarily mounted
  - Example: `/mnt/backup`
- `BACKUP_LOG_FILE`: Full path to the log file where backup operations will be recorded
  - Example: `/var/log/backup.log`

### Samba (SMB) Configuration
- `SMB_SERVER`: IP address or hostname of your SMB/CIFS server
  - Example: `192.168.1.100` or `nas.local`
- `SMB_USER`: Username for authenticated SMB access
  - Optional: Comment out or remove for guest access
  - Example: `backup_user`
- `SMB_PASS`: Password for authenticated SMB access
  - Optional: Comment out or remove for guest access
  - Example: `your_secure_password`

### Cloudflare R2 Configuration
- `R2_REMOTE_NAME`: The name of your rclone remote configuration for R2
  - Example: `r2`
- `R2_BUCKET_NAME`: Your Cloudflare R2 bucket name
  - Example: `your-bucket-name`
- `RCLONE_CONFIG`: Full path to your rclone configuration file
  - Example: `/root/.config/rclone/rclone.conf`
- `RETENTION_DAYS`: Number of days to retain backups in R2
  - Example: `30`

### Backup Directory Mapping
- `BACKUP_DIRS_CONFIG`: Maps SMB shares to R2 destination folders
  - Format: `"share_name=destination_folder"`
  - Multiple entries separated by semicolons
  - Example: `"documents=backup/docs;photos=backup/pics"`
  - This means:
    - `\\SMB_SERVER\documents` → `R2_BUCKET_NAME/backup/docs`
    - `\\SMB_SERVER\photos` → `R2_BUCKET_NAME/backup/pics`

### File Exclusion Patterns
- `BACKUP_IGNORE_PATTERNS`: Files to exclude from backup
  - Multiple patterns separated by semicolons
  - Supports standard glob patterns
  - Common examples:
    - `*.tmp`: Temporary files
    - `*.temp`: Temporary files
    - `~*`: Backup files (common in text editors)
    - `.DS_Store`: macOS system files
    - `desktop.ini`: Windows system files
    - `*.bak`: Backup files
