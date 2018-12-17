#!/usr/bin/env sh

ASOUND="${HOME}/.asoundrc"
ASOUND_KEY="defaults.bluealsa.device"

if [[ $# -gt 1 || "${1}" == "--help" ]]; then
	echo "Usage: ${0} [<bluetooth-device-mac>]" >&2
	echo "Disconnect a given bluetooth device." >&2
	echo "If the bluetooth device is not set, try to read it from ${ASOUND} as ${ASOUND_KEY}." >&2
	exit 1
fi

if [[ $# -gt 0 ]]; then
	DEV="${1}"
else
	DEV=$(grep -o "^${ASOUND_KEY} .*" "${ASOUND}" | cut -d '"' -f 2)
	if [[ -z "${DEV}" ]]; then
		echo "Cannot get ${ASOUND_KEY} from ${ASOUND} to detect the bluetooth device!" >&2
		exit 2
	fi
fi

echo "Removing device ${DEV} ..." >&2
@bluetoothctl@ remove "${DEV}" \
&& echo "Done!" >&2 || echo "Error!" >&2
