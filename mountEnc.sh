#!/bin/bash

## Exit codes
# 0: All OK.
# 1: Device not found.
# 2: Device specified is not a luks partition.
# 3: Mount failed more info from standard output.
# 4: Bad key file.
# 5: Error unlocking.


# Display help.
if [ $1 == "-h" ] || [ $1 == "--help" ] ; then
	echo "This script quickly mounts encrypted volumes."
	echo
	echo "Copyright (C) 2017 Rillian Grant <rillian.grant@hotmail.com>"
	echo "This softwhere is avalable under the GPL v3.0. See LICENCE.txt for more info."
	echo
	echo "<thisScript> [UUID] [MAPPER_NAME] [MOUNT_PATH] [KEY_FILE]"
	echo
	echo
	echo "UUID: The UUID of your device."
	echo "MAPPER_NAME: what to name the block device of the unencrypted volume found in /dev/mapper/."
	echo "MOUNT_PATH: The path to mount the unencrypted volume."
	echo "KEY_FILE: The path to the key file."
	echo
	echo

	exit 0
fi

# Partition details
UUID=$1
MAPPER_NAME=$2
MOUNT_PATH=$3
KEY_FILE=$4

# Check if the device is plugged in.
if [ -L /dev/disk/by-uuid/$UUID ] ; then
	echo "Found UUID: $UUID. Unlocking..."

	# Checking if the UUID corrasponds to a valid Luks partition.
	cryptsetup isLuks /dev/disk/by-uuid/$UUID
	if [ $? -eq 0 ] ; then
		# These if statements check if the device needs to be unlocked of has problems.
		cryptsetup luksOpen /dev/disk/by-uuid/$UUID --key-file $KEY_FILE $MAPPER_NAME 
		if [ $? -eq 0 ] ; then
			echo "Unlocked UUID $UUID. Attempting to mount /dev/mapper/$MAPPER_NAME at $MOUNT_PATH"

		elif [ $? -eq 2 ] ; then
			echo "$KEY_FILE is bad. Exiting."
			exit 4

		elif [ $? -eq 5 ] || [ $? -eq 2 ] || [ $? -eq 1 ] ; then
			echo "Device already open. Attempting to mount /dev/mapper/$MAPPER_NAME at $MOUNT_PATH"

		else
			echo "Error unlocking device. Exiting."
			exit 5
		fi


	else
		echo "Device $UUID is not a luks partition. Exiting."
		exit 2
	fi

	mount /dev/mapper/$MAPPER_NAME $MOUNT_PATH
	if [ $? -eq 0 ] ; then
		echo "Mount sucessfull."

	else
		echo "Mount failed. Exiting."
		exit 3
	fi

else
	echo "UUID $UUID not found in /dev/disk/by-uuid/ or is not an symbolic link. Exiting."
	exit 1
fi

exit 0
