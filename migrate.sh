#!/bin/bash

# Function to check if a ZFS pool exists
check_pool_exists() {
    if ! zpool status "$1" >/dev/null 2>&1; then
        echo "Error: ZFS pool '$1' does not exist."
        return 1
    fi
    return 0
}

# Ask for source and destination pools
read -p "Enter the source ZFS pool name (e.g., rpool): " source_pool
read -p "Enter the destination ZFS pool name (e.g., nvme-pool): " dest_pool

# Verify that both pools exist
if ! check_pool_exists "$source_pool" || ! check_pool_exists "$dest_pool"; then
    exit 1
fi

# Create a new dataset in the destination pool
echo "Creating new dataset in $dest_pool..."
zfs create "$dest_pool/root"

# Create a snapshot of the source pool
snapshot_name="${source_pool}/ROOT@migration_$(date +%Y%m%d%H%M%S)"
echo "Creating snapshot: $snapshot_name"
zfs snapshot -r "$snapshot_name"

# Transfer the data
echo "Transferring data from $source_pool to $dest_pool..."
zfs send -R "$snapshot_name" | zfs receive -F "$dest_pool/root"

# Update the boot configuration
echo "Updating boot configuration..."
sed -i "s/$source_pool/$dest_pool/g" /etc/kernel/cmdline

# Update GRUB
echo "Updating GRUB..."
update-grub

# Reinstall the bootloader
echo "Reinstalling bootloader..."
proxmox-boot-tool init

echo "Migration complete. Please review the changes and reboot the system."
echo "After reboot, verify that the system is booting from $dest_pool:"
echo "zfs get mountpoint $dest_pool/root"
echo "If everything is working correctly, you can remove the old pool with:"
echo "zpool destroy $source_pool"
echo "WARNING: Be absolutely certain that the new setup is working before destroying the old pool."

read -p "Do you want to reboot now? (y/n): " reboot_choice
if [[ $reboot_choice =~ ^[Yy]$ ]]; then
    reboot
fi
