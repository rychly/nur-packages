#!/bin/bash

# depends: media-libs/flickcurl

if [[ "${1}" == "--help" ]]; then
	echo "Usage:	${0}" >&2
	echo "Sort descendingly sets/albums by their titles in a flickr account by flickculr." >&2
	exit 1
fi

DELIM=","

exec 5>&1

echo "*** Fetching and sorting list of sets/albums ***"
# input passed via < <() operators, otherwise subshell prevents external variable modification
while read -d $'\0' LINE; do
	SETIDS+=$(echo "${LINE}${DELIM}" | tail -n +2)
done < <(
	@flickcurl@ --quiet photosets.getList \
	| tee >(cat - >&5) \
	| grep -o 'Found photoset with ID [0-9]* .* title: .*$' \
	| while read SETLINE; do
		printf '%s\n%s\0' \
			"$(echo "${SETLINE}" | cut -d "'" -f 4)" \
			"$(echo "${SETLINE}" | cut -d ' ' -f 5)"
	done \
	| sort --zero-terminated --reverse
)

echo "*** Reordering sets/albums ***"
exec @flickcurl@ --quiet photosets.orderSets "${SETIDS:0:-1}"
