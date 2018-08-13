#!/bin/bash
# requires: x11-misc/xdotool, app-admin/pass, x11-misc/rofi (can be replaced by gnome-extra/zenity), x11-libs/libnotify (compatible with x11-misc/dunst)

if [[ "${1}" == "--help" ]]; then
	echo "Usage:	${0} [--timeout=<seconds>] [--selection=clipboard|primary|secondary] [--username-confirmation-key=tab|enter|none] [URL]" >&2
	echo "Search pass for pass-name matching a given URL and its sub-paths, and, if found, enter its user-name and copy its password into a clipboard" >&2
	echo "(if the URL or its sub-path ends with '/**', search pass-names in all its directories, otherwise search in its current directory only)." >&2
	echo "If an URL is unspecified, read it from the active windowd's WM_NAME property (the window's title), from the beginning of the property value or enquoted by '<' and '>' marks" >&2
	echo "(use 'Url in title' Chrome extension to set the Chrome window's title to '{title} <{protocol}://{hostname}{port}/{path}{args}{hash}>', see https://chrome.google.com/webstore/detail/url-in-title/ignpacbgnbnkaiooknalneoeladjnfgb)." >&2
	echo "The timeout parameter can set the pass-name list dialog timeout in seconds and the number of seconds to wait before restoring the clipboard (default 15 seconds)." >&2
	echo "The selection parameter can specify which X selection to use, options are 'primary' to use XA_PRIMARY, 'secondary' for XA_SECONDARY or 'clipboard' for XA_CLIPBOARD (default)." >&2
	echo "The username confirmation key parameter can specify a key that will be sent to the active window after the selected user name, usually to switch from a user-name input box to a password input box (default none)." >&2
	exit 1
fi

if [[ "${1:0:10}" == "--timeout=" ]]; then
	TIMEOUT="${1:10}"
	shift
else
	TIMEOUT=15
fi

if [[ "${1:0:12}" == "--selection=" ]]; then
	SELECTION="${1:12}"
	shift
else
	SELECTION="clipboard"
fi

if [[ "${1:0:28}" == "--username-confirmation-key=" ]]; then
	case "${1:28}" in
		tab)	UNC_KEY=$'\t'; ;;
		enter)	UNC_KEY=$'\n'; ;;
		none)	UNC_KEY=""; ;;
		*)
			echo "Unknown username-confirmation-key value '${1:28}'" >&2
			exit 2
	esac
	shift
else
	UNC_KEY=""
fi

#ACTWIN_ID=$(@xprop@ -root _NET_ACTIVE_WINDOW | cut -d '#' -f 2)
ACTWIN_ID=$(@xdotool@ getactivewindow)

if [[ -n "$1" ]]; then
	URL="${1}"
else
	#ACTWIN_NAME=$(@xprop@ -id "${ACTWIN_ID}" WM_NAME) \
	ACTWIN_NAME=$(@xdotool@ getwindowname "${ACTWIN_ID}")
	# URL is an active window's name for non-HTML authentization (i.e., HTTPAuth) or in the active window's name enclosed by <> for HTML authenization (i.e., form-based)
	[[ "${ACTWIN_NAME:0:7}" == "http://" || "${ACTWIN_NAME:0:8}" == "https://" || "${ACTWIN_NAME:0:6}" == "ftp://" ]] \
	&& URL="${ACTWIN_NAME%% *}" \
	|| URL=$(echo "${ACTWIN_NAME}" | grep -o '<[^<>]\+>' | tail -n 1 | tr -d '<>')
fi

PASSDIR=~/.password-store

function list_passnames_in_subpaths() {
	local new_url="${1%/}"
	local url
	cd "${PASSDIR}"
	while [[ "${new_url}" != "${url}" ]]; do
		url="${new_url}"
		if [[ "${url%/\*\*}" != "${url}" ]]; then
			url="${url%/\*\*}"
			find "${url}" -name "*.gpg" 2>/dev/null
		else
			find "${url}" -maxdepth 1 -name "*.gpg" 2>/dev/null
		fi
		new_url="${url%[#?/]*}"
	done
}

function switch_to_alternative_protocol() {
	local url="${1}"
	[[ "${url:0:7}" == "http://" ]] && echo "https://${url#http://}" \
	|| [[ "${url:0:8}" == "https://" ]] && echo "http://${url#https://}"
}

# output passed via < <() operator, otherwise a subshell prevents external variable modification (requires bash)
read PASSNAME < <(IFS=$'\n'; for I in $(
	list_passnames_in_subpaths "${URL}"
	list_passnames_in_subpaths $(switch_to_alternative_protocol "${URL}")
); do
	I="${I%.gpg}"
	# username
	echo -n "<b>${I##*/}</b> "
	# url
	echo "<i>${I%/*}</i>"
	# passname
	#echo "${I}"
done \
| @rofi@ -dmenu -mesg "Pass: <i>${URL//&/&amp;}</i>" -p "user-name" -i -no-custom -markup-rows \
| sed 's|^<b>\(.*\)</b> <i>\(.*\)</i>$|\2/\1|g' )
#| @zenity@ --title=Pass "--text=Select a user-name for\n<i>${URL//&/&amp;}</i>" --width=800 "--timeout=${TIMEOUT}" --list --column=user-name --column=URL --column=pass-name --hide-column=3 --print-column=3 --hide-header \

# @xdotool@ type --window "${ACTWIN_ID}" ... does not work for Chrome and Firefox as thay ignore XSendEvent when a specific window flag is enabled, we need to activate the window first and than to type
[[ -n "${PASSNAME}" ]] \
&& PASSWORD_STORE_CLIP_TIME="${TIMEOUT}" PASSWORD_STORE_X_SELECTION="${SELECTION}" @pass@ show --clip "${PASSNAME}" \
&& @notify-send@ -a Pass -t $((TIMEOUT*1000)) "The password copied into <u>${SELECTION}</u> for the next <u>${TIMEOUT} seconds</u>." \
&& @xdotool@ windowactivate --sync "${ACTWIN_ID}" type --delay 0 --clearmodifiers --args 1 "${PASSNAME##*/}${UNC_KEY}"
