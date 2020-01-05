#!/bin/sh

CAMERA=$(echo /run/media/${USER}/*/DCIM | head -1)
PHOTOS=$(@xdg-user-dir@ PICTURES)
TMPDIR="/tmp/camera-to-pictures.$$"

if ! [[ -d "${CAMERA}" ]]; then
	echo "### karta neni pripojena" >&2
	exit 1
fi

echo "*** stahuji fotky z pametove karty fotoaparatu" >&2

mkdir -p "${TMPDIR}"
find "${CAMERA}" -iname "*.jpg" -exec mv -v {} "${TMPDIR}" \; || exit 2

echo "*** tridim fotky" >&2
cd "${TMPDIR}" \
&& @out@/bin/all-rename-exif --dirs || exit 3

echo "*** presouvam fotky do uloziste obrazku (${TMPDIR} => ${PHOTOS})" >&2
find "${TMPDIR}" -mindepth 1 -type d -exec rsync -aP --remove-source-files {} "${PHOTOS}/" \; || exit 4

echo "*** konec, zavrete okno aplikace, nebo stisknete Enter" >&2
read I
