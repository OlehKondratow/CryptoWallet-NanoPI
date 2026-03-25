# UART boot log excerpt — successful NFS root (reference)

Captured from Orange Pi One + Yocto **6.6.x** / **Poky 5.0.16**, lab network **192.168.126.0/23**, NFS export matching **`boot.cmd`** `nfsroot` path. Serial **115200 8N1**.

## Kernel command line (must match `/etc/exports` path)

```text
Kernel command line: console=ttyS0,115200 root=/dev/nfs nfsroot=192.168.126.3:/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot,nfsvers=3,tcp,nolock ip=192.168.127.166::192.168.126.1:255.255.254.0::eth0:off rw
```

Do **not** add bogus parameters: e.g. **`nfsrootdebug`** is **not** a valid Linux 6.6 boot option and produces:

```text
Unknown kernel command line parameters "nfsrootdebug", will be passed to user space.
```

## IP configuration and NFS root mount

```text
IP-Config: Complete:
     device=eth0, hwaddr=..., ipaddr=192.168.127.166, mask=255.255.254.0, gw=192.168.126.1
     bootserver=255.255.255.255, rootserver=192.168.126.3, rootpath=
VFS: Mounted root (nfs filesystem) on device 0:13.
Run /sbin/init as init process
INIT: version 3.04 booting
```

## Userland and login

```text
Poky (Yocto Project Reference Distro) 5.0.16 orange-pi-one /dev/ttyS0
orange-pi-one login:
```

## Benign messages on NFS root (often safe to ignore)

With **`ip=`** already set in the kernel command line, SysV init may still run `ifup`; you may see:

```text
Configuring network interfaces... ip: RTNETLINK answers: File exists
ifup skipped for nfsroot interface eth0
run-parts: /etc/network/if-pre-up.d/nfsroot: exit status 1
```

If NFS mounted and **sshd** / **login** appear, networking is already sufficient for the root FS.
