#!/usr/bin/env sh

ALSA_DEV="bluealsa"

if [[ $# -gt 2 || "${1}" == "--help" ]]; then
	echo "Usage: ${0} [<amixer-command> <command-parameters>]" >&2
	echo "Command-line mixer for ALSA soundcard driver of Bluez-ALSA proxy (device '${ALSA_DEV}')." >&2
	exit 1
fi

CMD="${1:-sget}"
shift

CTRL="$(amixer -D "${ALSA_DEV}" scontrols | head -1 | cut -d "'" -f 2)"

exec amixer -D "${ALSA_DEV}" "${CMD}" "${CTRL}" $@
