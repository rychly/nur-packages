#!/usr/bin/env sh

ALSA_DEV="bluealsa"
ASOUND="${HOME}/.asoundrc"
COMMENT_BEGIN="# BEGIN ${ALSA_DEV}"
COMMENT_END="# END ${ALSA_DEV}"

if [[ $# -gt 2 || "${1}" == "--help" ]]; then
	echo "Usage: ${0} [on|off|toggle]" >&2
	echo "Usage: ${0} <bluetooth-device-mac> [on|off|toggle]" >&2
	echo "Set/unset or toggle (by default) Bluez-ALSA proxy (device '${ALSA_DEV}') to a given bluetooth device (optional) as the default sound device for the current user." >&2
	exit 1
fi

if [[ $# -eq 2 ]]; then
	DEV="${1}"
	ACTION="${2}"
elif [[ $# -eq 1 ]]; then
	if [[ "${1}" == "on" || "${1}" == "off" || "${1}" == "toggle" ]]; then
		ACTION="${1}"
	else
		DEV="${1}"
		ACTION="toggle"
	fi
else
	ACTION="toggle"
fi

action_on() {
	echo "Enabling ${ALSA_DEV} as the default ALSA device ..." >&2
	if grep -qF "${COMMENT_BEGIN}" "${ASOUND}" 2>/dev/null; then
		echo "Already enabled." >&2
	else
		echo "${COMMENT_BEGIN}" >> "${ASOUND}"
		[[ -n "${DEV}" ]] && echo "defaults.bluealsa.device \"${DEV}\"" >> "${ASOUND}"
		cat <<EOF >> "${ASOUND}"
pcm.!default {
	type plug
	slave.pcm "${ALSA_DEV}"
}
ctl.!default {
	type ${ALSA_DEV}
}
${COMMENT_END}
EOF
		echo "Enabled." >&2
	fi
}

action_off() {
	echo "Disabling ${ALSA_DEV} as the default ALSA device ..." >&2
	sed -i "/${COMMENT_BEGIN}/,/${COMMENT_END}/d" "${ASOUND}" 2>/dev/null
	echo "Disabled." >&2
}

action_toggle() {
	if grep -qF "${COMMENT_BEGIN}" "${ASOUND}" 2>/dev/null; then
		action_off
	else
		action_on
	fi
}

case "${ACTION}" in
	on)	action_on ;;
	off)	action_off ;;
	toggle)	action_toggle ;;
esac

echo "Done!" >&2
