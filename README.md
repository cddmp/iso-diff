# iso-diff
A quick hack to verify CDs/DVDs against ISO images.

## Usage
Just pass the ISO image as first parameter. For the second parameter pass the device (optional). If you do not pass a device, the script will try to use ```/dev/sr0```.

Examples:

```iso-diff.sh someimage.iso```

```iso-diff.sh someimage.iso /dev/cdrom```
