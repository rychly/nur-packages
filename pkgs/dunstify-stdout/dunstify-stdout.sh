#!/bin/sh

if [[ -z "${1}" || "${1}" == "--help" ]]; then
	echo "Usage: ${0} <message> [icon] [timeout]" >&2
	echo "Send the synchronous message and stdout to dunst with the icon and the timeout." >&2
	exit 1
fi

MSG="${1}"
ICN="${2}"
TIM="${3:-5000}"

HASH=$(echo "${MSG}" | sha1sum | cut -d ' ' -f 1)
FILE="/dev/shm/dustify_id_${USER}_${HASH}"
ID=$((`cat "${FILE}" 2>/dev/null`))

exec @dunstify@ -p -r "${ID}" "--icon=${ICN}" "--timeout=${TIM}" "${MSG} $(cat)" -h "string:synchronous:${HASH}" >${FILE}
