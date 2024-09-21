## Transferring OS from rpool to nvme-pool in Proxmox

This guide outlines the process of transferring the operating system (OS) from one ZFS pool (rpool) to another (nvme-pool) in Proxmox.

## Prerequisites

- Proxmox VE installed
- Two ZFS pools:
  - `rpool`: The source pool containing the OS
  - `nvme-pool`: The destination pool (empty)

## Steps

1. **Verify the pools**

   First, check the status of both pools:

   ```
   zpool status rpool
   zpool status nvme-pool
   ```

2. **Create a new dataset in nvme-pool**

   Create a new dataset in the destination pool to receive the OS data:

   ```
   zfs create nvme-pool/root
   ```

3. **Transfer the data**

   Use ZFS send/receive to transfer the data:

   ```
   zfs send -R rpool/ROOT@snapshot | zfs receive -F nvme-pool/root
   ```

   Replace `@snapshot` with an appropriate snapshot name if one exists, or create a new snapshot before sending.
   <br>

4. **Update the boot configuration**

   Edit `/etc/kernel/cmdline` to point to the new pool:
   ```
   sed -i 's/rpool/nvme-pool/g' /etc/kernel/cmdline
   ```

5. **Update GRUB**

   Update GRUB to boot from the new pool:

   ```
   update-grub
   ```

6. **Reinstall the bootloader**

   Reinstall the bootloader to the new pool:

   ```
   proxmox-boot-tool init
   ```

7. **Reboot**

   Reboot the system to apply changes:

   ```
   reboot
   ```

8. **Verify the boot**

   After reboot, verify that the system is now booting from nvme-pool:

   ```
   zfs get mountpoint nvme-pool/root
   ```

9. **Clean up (optional)**

   If everything is working correctly, you can remove the old pool:

   ```
   zpool destroy rpool
   ```

   Be absolutely certain that the new setup is working before destroying the old pool.
