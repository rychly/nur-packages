#!/usr/bin/env sh

if [[ $# -ne 1 || "${1}" == "--help" ]]; then
	echo "Usage: ${0} <on|off>" >&2
	echo "Activate/deactivate Bluez-ALSA." >&2
	exit 1
fi

case "${1}" in
on)	@out@/bin/bluetooth-reconnect && \
	@out@/bin/bluealsa-amixer sset 50% && \
	@out@/bin/bluealsa-asound on
	;;
off)	@out@/bin/bluealsa-asound off
	@out@/bin/bluetooth-disconnect
	;;
*)	echo "Unknown action '${1}'!" >&2
	exit 2
esac
