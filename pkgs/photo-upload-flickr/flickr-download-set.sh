#!/bin/bash

# depends: media-libs/flickcurl, net-misc/aria2 (optional)

if [[ "${1}" == "--help" || $# -ne 1 ]]; then
	echo "Usage:	${0} <url_to_flickr_set>" >&2
	echo "Download photos in the given set/album by flickculr." >&2
	exit 1
fi

exec 5>&1

URL=${1%/} SETID=${URL##*/}

echo "*** Fetching list of photos in set ID ${SETID} ***"
declare -A PHOTOS
# input passed via < <() operators, otherwise subshell prevents external variable modification
while read PHOTOLINE && read TITLELINE; do
	PHOTOS[$(echo "${PHOTOLINE}" | cut -d ' ' -f 6)]=$(echo "${TITLELINE}" | cut -d "'" -f 2)
done < <(
	@flickcurl@ --quiet photosets.getPhotos "${SETID}" \
	| tee >(cat - >&5) \
	| grep -o '\(photo with URI [^ ]* ID [0-9]* and [0-9]* tags\)\|\(field title ([0-9]*) with string value:.*$\)'
)

for PHOTOID in "${!PHOTOS[@]}"; do
	PHOTOTITLE="${PHOTOS[$PHOTOID]}"
	echo "*** Getting available sizes for set/photo ID ${SETID}/${PHOTOID}, title: ${PHOTOTITLE} ***"
	REPLY=$(@flickcurl@ --quiet photos.getSizes "${PHOTOID}" \
		| tee >(cat - >&5))
	ORIGURL=$(echo "${REPLY}" \
		| grep -A 1 "type 'photo' label 'Original'" | tail -n 1 | grep -o 'https://[^ ]*')
	[[ -z "${ORIGURL}" ]] && # if Original unavailable, fetch the largest/latest available
		ORIGURL=$(echo "${REPLY}" \
			| grep -A 1 "type 'photo' label" | tail -n 1 | grep -o 'https://[^ ]*')
	FILE="${PHOTOID}--${PHOTOTITLE// /_}.${ORIGURL##*.}"
	echo "*** Downloading set/photo ID ${SETID}/${PHOTOID} original from ${ORIGURL} ***"
	if [[ -x "@aria2c@" ]]; then
		@aria2c@ --continue=true --check-certificate=false \
			--out="${FILE}" "${ORIGURL}" || exit -2
	elif [[ -x "@wget@" ]]; then
		@wget@ --continue --no-check-certificate \
			--output-document="${FILE}" "${ORIGURL}" || exit -2
	else
		"No aria2c or wget to download '${ORIGURL}' into '${FILE}'!" >&2
	fi
done
