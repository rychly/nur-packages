#!/bin/bash

# depends: media-libs/flickcurl

if [[ "${1}" == "--help" || $# -ne 1 ]]; then
	echo "Usage:	${0} <url_to_flickr_set>" >&2
	echo "Sort ascendingly photos by their titles in the given set/album in a flickr account by flickculr." >&2
	exit 1
fi

DELIM=","

exec 5>&1

URL=${1%/} SETID=${URL##*/}

echo "*** Fetching and sorting list of photos in set ID ${SETID} ***"
# input passed via < <() operators, otherwise subshell prevents external variable modification
while read -d $'\0' LINE; do
	PHOTOIDS+=$(echo "${LINE}${DELIM}" | tail -n +2)
done < <(
	@flickcurl@ --quiet photosets.getPhotos "${SETID}" \
	| tee >(cat - >&5) \
	| grep -o '\(photo with URI [^ ]* ID [0-9]* and [0-9]* tags\)\|\(field title ([0-9]*) with string value:.*$\)' \
	| while read PHOTOLINE && read TITLELINE; do
		printf '%s\n%s\0' \
			"$(echo "${TITLELINE}" | cut -d "'" -f 2)" \
			"$(echo "${PHOTOLINE}" | cut -d ' ' -f 6)"
	done \
	| sort --zero-terminated
)

echo "*** Reordering photos in set ID ${SETID} ***"
exec @flickcurl@ --quiet photosets.reorderPhotos "${SETID}" "${PHOTOIDS:0:-1}"
