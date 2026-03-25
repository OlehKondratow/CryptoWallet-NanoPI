# Server and NFS root path
setenv serverip 192.168.126.3
setenv nfsroot /srv/cryptowallet-netboot/nfsroot

# Kernel args for NFS boot (UART console on ttyS0)
setenv bootargs "console=ttyS0,115200 root=/dev/nfs nfsroot=${serverip}:${nfsroot},v3,tcp ip=dhcp rw"

# Load kernel and device tree from TFTP
echo "Loading kernel and fdt from ${serverip}..."
tftp ${kernel_addr_r} uImage
tftp ${fdt_addr_r} sun8i-h3-orangepi-one.dtb

# Boot uImage with device tree
echo "Booting Orange Pi One via Network..."
bootm ${kernel_addr_r} - ${fdt_addr_r}