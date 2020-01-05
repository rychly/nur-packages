#!/bin/bash
# depends: media-libs/flickcurl

LISTFILE=flickr.txt

exec 5>&1
shopt -s extglob
# Photo natively supported file types (other formats will be converted to JPEG)
# https://help.yahoo.com/kb/flickr/upload-limitations-flickr-sln15628.html
MASK=*.@(jpg|JPG|jpeg|JPEG|gif|GIF|png|PNG)

if [[ "${1}" == "--help" || $(ls -- $MASK 2>/dev/null | wc -l) -eq 0 ]]; then
	echo "Usage: ${0}" >&2
	echo "Upload all Jpeg, Gif, and Png photos in the current directory (except for files in ${LISTFILE}) to a new set in the flickr account by flickcurl tool." >&2
	exit -1
fi

echo "Photos:"
ls -- $MASK

ALBUM=$(basename $(realpath "${PWD}"))
echo "Album: ${ALBUM}"

echo "Uploading photos ..."
for I in $MASK; do
	echo "*** Uploading ${I} ***"
	if grep --max-count=1 -F "${I}" "${LISTFILE}" 2>/dev/null; then
		echo "Skipping, already uploaded, listed in ${LISTFILE}" >&2
		continue
	fi
	TAIL=$(@flickcurl@ upload "${I}" \
		title "$(basename ${I%.*})" \
		safety_level 'safe' \
		content_type 'photo' \
		hidden 'hidden' \
		| tee >(cat - >&5) | tail -n 1)
	if ! echo "${TAIL}" | grep -qF 'Photo ID'; then
		echo "*** ERROR ***" >&2
		exit -2
	fi
	PHOTOID=$(echo "${TAIL}" | cut -d ':' -f 2 | tr -d ' ')
	echo "*** OK, photo ID ${PHOTOID} ***"
	echo "*** Getting short URL for photo ID ${PHOTOID} ***"
	TAIL=$(@flickcurl@ shorturi "${PHOTOID}" \
		| tee >(cat - >&5) | tail -n 1)
	if ! echo "${TAIL}" | grep -qF 'Short URI for photo ID'; then
		echo "*** ERROR ***" >&2
		exit -3
	fi
	PHOTOURL=$(echo "${TAIL}" | cut -d ' ' -f 9)
	echo "${I}	${PHOTOID}	${PHOTOURL}" >>${LISTFILE}
	echo "*** OK, URL is ${PHOTOURL} ***"
	if [[ -z "${SETID}" ]]; then
		echo "*** Searching album/set ${ALBUM} in ${LISTFILE} ***"
		TAIL=$(grep --max-count=1 -F "../${ALBUM}" "${LISTFILE}" 2>/dev/null \
			| tee >(cat - >&5))
		if [[ -n "${TAIL}" ]]; then
			# cut: no DELIM means TAB is the field delimiter
			SETID=$(echo "${TAIL}" | cut -f 2)
			SETURL=$(echo "${TAIL}" | cut -f 3)
			echo "*** Found, album/set ${ALBUM} has ID ${SETID} and URL ${SETURL} ***"
		else
			echo "*** Album/set not found! ***"
		fi
	fi
	if [[ -z "${SETID}" ]]; then
		echo "*** Creating album/set ${ALBUM} with photo ID ${PHOTOID} ***"
		TAIL=$(@flickcurl@ photosets.create "${ALBUM}" "" "${PHOTOID}" \
			| tee >(cat - >&5) | tail -n 1)
		if ! echo "${TAIL}" | grep -q 'Photoset [0-9]* created'; then
			echo "*** ERROR ***" >&2
			exit -4
		fi
		SETID=$(echo "${TAIL}" | cut -d ' ' -f 3)
		SETURL=$(echo "${TAIL}" | cut -d ' ' -f 7)
		echo "../${ALBUM}	${SETID}	${SETURL}" >>${LISTFILE}
		echo "*** OK, set ID ${SETID} and URL ${SETURL} ***"
	else
		echo "*** Adding photo ID ${PHOTOID} into set/album ID ${SETID} ***"
		if ! @flickcurl@ photosets.addPhoto "${SETID}" "${PHOTOID}"; then
			echo "*** ERROR ***" >&2
			exit -5
		fi
		echo "*** OK ***"
	fi
done

echo "Done."
