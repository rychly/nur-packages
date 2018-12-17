#!/usr/bin/env sh

TIMEOUT=10
ASOUND="${HOME}/.asoundrc"
ASOUND_KEY="defaults.bluealsa.device"

if [[ $# -gt 2 || "${1}" == "--help" ]]; then
	echo "Usage: ${0} [<bluetooth-device-mac> <device-alias>]" >&2
	echo "Connect or reconnect a given bluetooth device." >&2
	echo "If the bluetooth device is not set, try to read it from ${ASOUND} as ${ASOUND_KEY}." >&2
	exit 1
fi

if [[ $# -gt 0 ]]; then
	DEV="${1}"
	ALIAS="${2}"
else
	DEV=$(grep -o "^${ASOUND_KEY} .*" "${ASOUND}" | cut -d '"' -f 2)
	ALIAS="btspeaker"
	if [[ -z "${DEV}" ]]; then
		echo "Cannot get ${ASOUND_KEY} from ${ASOUND} to detect the bluetooth device!" >&2
		exit 2
	fi
fi

echo "Removing device ${DEV} ..." >&2
@bluetoothctl@ remove "${DEV}"

echo "Waiting ${TIMEOUT} seconds for device ${DEV} ..." >&2
@bluetoothctl@ power on
@bluetoothctl@ --timeout "${TIMEOUT}" scan on

echo "Connecting device ${DEV} ..." >&2
@bluetoothctl@ pair "${DEV}" \
&& ( [[ -z "${ALIAS}" ]] || @bluetoothctl@ set-alias "${ALIAS}" ) \
&& @bluetoothctl@ trust "${DEV}" \
&& @bluetoothctl@ connect "${DEV}" \
&& @bluetoothctl@ info "${DEV}" \
&& echo "Done!" >&2 || echo "Error!" >&2
