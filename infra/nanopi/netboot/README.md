# NanoPi NEO Netboot (TFTP + NFS)

## Host-side prep

```bash
cd infra/nanopi/netboot
./scripts/setup-netboot-host.sh
```

Populate `tftp/` with:

- `zImage`
- `sun8i-h3-nanopi-neo.dtb`
- optional `initramfs.cpio.gz`

Populate `nfsroot/` with extracted rootfs.

## U-Boot test commands (NanoPi NEO)

Replace host IP if отличается (в лабе TFTP/NFS на `192.168.126.3`):

```bash
setenv serverip 192.168.126.3
dhcp
tftp 0x42000000 zImage
tftp 0x43000000 sun8i-h3-nanopi-neo.dtb
setenv bootargs 'console=ttyS0,115200 root=/dev/nfs nfsroot=192.168.126.3:/srv/cryptowallet-netboot/nfsroot,vers=3,tcp ip=dhcp rootwait panic=10'
bootz 0x42000000 - 0x43000000
```

Persist only after successful boot:

```bash
saveenv
```
