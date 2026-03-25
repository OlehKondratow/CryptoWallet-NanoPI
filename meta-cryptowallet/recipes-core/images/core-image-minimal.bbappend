# Pull CryptoWallet service into the same image used for NFS root (netboot).
IMAGE_INSTALL:append = " cryptowallet "
