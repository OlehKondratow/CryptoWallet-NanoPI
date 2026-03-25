# LAN is 192.168.126.0/23 (mask 255.255.254.0): .126.* and .127.* are the same L2 segment as server 192.168.126.3.
# A /24 mask on the board wrongly puts 192.168.126.3 in another subnet -> TFTP ARP failures via gateway.
setenv ipaddr 192.168.127.166
setenv netmask 255.255.254.0
setenv gatewayip 192.168.126.1

# TFTP + NFS server
setenv serverip 192.168.126.3
# Server path must match /etc/exports exactly (here: repo nfsroot, not /srv/... unless you export there).
setenv nfsroot /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot

# Kernel: NFS root + same static IP on eth0 (replaces ip=dhcp)
# ip= format: client::gw:netmask:hostname:device:off
# Do not pass fake options (e.g. nfsrootdebug) — Linux 6.6 rejects them as unknown boot params.
setenv bootargs "console=ttyS0,115200 root=/dev/nfs nfsroot=${serverip}:${nfsroot},nfsvers=3,tcp,nolock ip=${ipaddr}::${gatewayip}:${netmask}::eth0:off rw"

echo "Net: static ${ipaddr} gw ${gatewayip} -> TFTP ${serverip}..."
# Load kernel and device tree from TFTP
tftp ${kernel_addr_r} uImage
tftp ${fdt_addr_r} sun8i-h3-orangepi-one.dtb

echo "Booting Orange Pi One via Network..."
bootm ${kernel_addr_r} - ${fdt_addr_r}
