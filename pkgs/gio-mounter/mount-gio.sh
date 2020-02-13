#!/bin/sh

CONF="${HOME}/.config/gio-mounter.conf"

CFG=$(@grep@ -v -e '^\s*#' -e '^$' "${CONF}" 2>/dev/null | @grep@ "^${1}=" | cut -d '=' -f 2)

if [ -z "${CFG}" ]; then
	echo "Usage:	${0##*/} <gio-cfg-id>" >&2
	echo "Mount a predefined storage via GIO/GVFS according to the configuration in ${CONF}." >&2
	echo "The following storages have beed predefined in the configuration file:" >&2
	grep -v -e '^\s*#' -e '^$' "${CONF}" >&2
	exit 1
fi

if @gio@ mount --list | @grep@ -qF -- "-> ${CFG}"; then
	echo "# Unmounting ${CFG} ..." >&2
	@gio@ mount -u "${CFG}" \
	&& echo "# ... unmounted" >&2
else
	echo "# Mounting ${CFG} ..." >&2
	@gio@ mount "${CFG}" \
	&& echo "# ... mounted" >&2
fi

[ -d "/run/user/${UID}/gvfs" ] && ls "/run/user/${UID}/gvfs"
