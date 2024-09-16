#!/bin/bash

# Based on: https://github.com/LuckfoxTECH/luckfox-pico/issues/66#issuecomment-2057153795 + ChatGPT 
# Usage: ./create_image.sh /dev/sdX

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 IMAGE /dev/DEVICE"
  exit 1
fi

IMAGE="$1"
DEVICE="$2"

# Ensure the device file exists
if [ ! -e "$DEVICE" ]; then
  echo "Error: Device $DEVICE does not exist."
  exit 1
fi

cd "$IMAGE"/ || (echo "Image does not exist"; exit 1)

# Define image file paths
IMAGE_OUT="full.img"
ENV_IMG="env.img"
IDBLOCK_IMG="idblock.img"
UBOOT_IMG="/home/nikita/src/luckfox-pico/blob/uboot_rv1106.img"
BOOT_IMG="boot.img"
OEM_IMG="oem.img"
USERDATA_IMG="userdata.img"
ROOTFS_IMG="rootfs.img"

# Copy the environment image
echo "Copying environment image to $DEVICE..."
dd if="$ENV_IMG" of="$IMAGE_OUT" status=progress conv=fdatasync

# Write the idblock image
echo "Writing idblock image..."
dd bs=1k seek=32 if="$IDBLOCK_IMG" of="$IMAGE_OUT" status=progress conv=fdatasync

# Write the uboot image
echo "Writing uboot image..."
dd bs=1k seek=$(dc -e '32 512 + p') if="$UBOOT_IMG" of="$IMAGE_OUT" status=progress conv=fdatasync

# Write the boot image
echo "Writing boot image..."
dd bs=1k seek=$(dc -e '32 512 256 + + p') if="$BOOT_IMG" of="$IMAGE_OUT" status=progress conv=fdatasync

# Write the OEM image
echo "Writing OEM image..."
dd bs=1k seek=$(dc -e '32 512 256 32 1024 * + + + p') if="$OEM_IMG" of="$IMAGE_OUT" status=progress conv=fdatasync

# Write the userdata image
echo "Writing userdata image..."
dd bs=1k seek=$(dc -e '32 512 256 32 1024 * 512 1024 * + + + + p') if="$USERDATA_IMG" of="$IMAGE_OUT" status=progress conv=fdatasync

# Write the root filesystem image
echo "Writing root filesystem image..."
dd bs=1k seek=$(dc -e '32 512 256 32 1024 * 512 1024 * 256 1024 * + + + + + p') if="$ROOTFS_IMG" of="$IMAGE_OUT" status=progress conv=fdatasync

# Eject the device
echo "Ejecting $DEVICE..."
eject "$DEVICE"

echo "Image creation complete. $IMAGE_OUT has been updated."
