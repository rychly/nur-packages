#!/bin/bash

set -e	# exit on error

# set path to binaries; there is nothing in PATH when called by systemd, i.e., no grep, mkdir, chown, chmod, su, fusermount (called by rclone)
export PATH=/run/current-system/sw/bin

if [[ "${1}" == "--help" ]]; then
	echo "Usage:	${0} "user#in-config-section:/" mountpoint -o option=value,..." >&2
	echo "Usage:	mount "${0}#user#in-config-section:/" mountpoint -t fuse -o option=value,..." >&2
	echo "Mount 'in-config-section:/' by rclone of 'user' into 'mountpoint' with particular options" >&2
	exit 1
fi

REMOTEPATH="${1#*#}"
MOUNTUSER="${1%%#*}"
MOUNTPOINT="$2"
TIMEOUT=20
FLAGS="--auto-confirm --log-level DEBUG --syslog"

if [[ "$3" = "-o" ]]; then
	FLAGS_RCLONE=$(@rclone@ mount --help | grep -o -- '--[-a-z0-9]\+' | sort --unique)
	# for each flag in -o mount option
	for FLAG in ${4//,/$'\n'}; do
		# translate flags that can be done by rclone (need not to send them to fuselib)
		case "$FLAG" in
			allow_other) FLAG="allow-other" ;;
			allow_root) FLAG="allow-root" ;;
			default_permissions) FLAG="default-permissions" ;;
			ro) FLAG="read-only" ;;
		esac
		# check the flag in the list of allowed rclone flags and add to the rclone (allowed) or fuselib (disallowed) flags list
		if echo "$FLAGS_RCLONE" | grep -qF "${FLAG%=*}"; then
			FLAGS="$FLAGS --${FLAG/=/ }"
		else
			FLAGS="$FLAGS --option $FLAG"
		fi
	done
fi

# fusermount called by rclone must have write access to the mountpoint
mkdir -p "$MOUNTPOINT"
chown "$MOUNTUSER:" "$MOUNTPOINT"
chmod u+rwx "$MOUNTPOINT"

# must be executed as config-file owner as it recreates the config-file

# FIXME: rclone (--daemon or not) fails to finish mounting (it is waiting for something) when called by systemd
# However, calling `mount` or `rclone` from terminal is ok, as well as later mounting when started by systemd (even if the initial mounting fails).
# Therefore it cannot be utilised with automount!

## background process (daemon)
exec su - "$MOUNTUSER" -c "@rclone@ mount '$REMOTEPATH' '$MOUNTPOINT' $FLAGS --daemon"

## or foreground process (not daemon)
#exec su - "$MOUNTUSER" -c "
#@rclone@ mount '$REMOTEPATH' '$MOUNTPOINT' $FLAGS &
#while ! grep -qF '$REMOTEPATH $MOUNTPOINT ' /proc/mounts && [[ \$COUNTER -lt $TIMEOUT ]]; do
#	let COUNTER=COUNTER+1;
#	echo \"Waiting for rclone, device '$REMOTEPATH' mountpoint '$MOUNTPOINT' ... \$COUNTER\"
#	sleep 1
#done
#"
