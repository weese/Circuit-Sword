## Important:

For the bluetooth driver to work, remove `console=serial0,115200` in the file `/boot/cmdline.txt`, e.g.:

ORIGINAL:
```
console=serial0,115200 console=tty1 root=PARTUUID=0c6a7995-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait loglevel=3 consoleblank=0 plymouth.enable=0
```

PATCHED:
```
console=tty1 root=PARTUUID=0c6a7995-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait loglevel=3 consoleblank=0 plymouth.enable=0
```