#!/bin/bash

# depends: media-libs/flickcurl

if [[ "${1}" == "--help" || $# -lt 2 ]]; then
	echo "Usage:	${0} <url_to_flickr_set> [public=yes|no] [friend=yes|no] [family=yes|no]" \
		"[add-comment=nobody|friends-and-family|contacts|everybody] [add-metadata=nobody|friends-and-family|contacts|everybody]" >&2
	echo "Modify permissions of all photos in the given set/album in a flickr account by flickculr." >&2
	exit -1
fi

function parseperms() {
	local ISPUBLIC ISCONTACT ISFRIEND ISFAMILY PERMCOMMENT ADDMETA
	while [[ $# -ne 0 ]]; do
		local KEY=${1%%=*} VAL=${1#*=}
		case "${KEY}" in
			public)
				[[ "${VAL}" == "yes" ]] && ISPUBLIC=1 || ISPUBLIC=0
			;;
			contact)
				[[ "${VAL}" == "yes" ]] && ISCONTACT=1 || ISCONTACT=0
			;;
			friend)
				[[ "${VAL}" == "yes" ]] && ISFRIEND=1 || ISFRIEND=0
			;;
			family)
				[[ "${VAL}" == "yes" ]] && ISFAMILY=1 || ISFAMILY=0
			;;
			add-comment) case "${VAL}" in
				nobody)
					PERMCOMMENT=0
				;;
				friends-and-family)
					PERMCOMMENT=1
				;;
				contacts)
					PERMCOMMENT=2
				;;
				everybody)
					PERMCOMMENT=3
				;;
				*)
					echo "Wrong value '${VAL}' of parameter '${KEY}'!" >&2
					exit -3
			esac ;;
			add-metadata) case "${VAL}" in
				nobody)
					ADDMETA=0
				;;
				friends-and-family)
					ADDMETA=1
				;;
				contacts)
					ADDMETA=2
				;;
				everybody)
					ADDMETA=3
				;;
				*)
					echo "Wrong value '${VAL}' of parameter '${KEY}'!" >&2
					exit -3
			esac ;;
			*)
				echo "Wrong parameter '${1}'!" >&2
				exit -2
		esac
		shift
	done
	echo ${ISPUBLIC}; echo ${ISFRIEND}; echo ${ISFAMILY}
	echo ${PERMCOMMENT}; echo ${ADDMETA}
}

exec 5>&1

URL=${1%/} SETID=${URL##*/}

shift
# parse args and exit on error
parseperms $* >/dev/null || exit $?
# parse args and set variables
{ read PER_ISPUBLIC; read PER_ISFRIEND; read PER_ISFAMILY; read PER_PERMCOMMENT; read PER_ADDMETA; } < <(parseperms $*)

echo "*** Fetching and sorting list of photos in set ID ${SETID} ***"
# input passed via < <() operators, otherwise subshell prevents external variable modification
while read -d $'\0' LINE; do
	PHOTOID=$(echo "${LINE}" | tail -n +2)
	if [[ "${PER_ISPUBLIC}" && "${PER_ISFRIEND}" && "${PER_ISFAMILY}" && "${PER_PERMCOMMENT}" && "${PER_ADDMETA}" ]]; then
		SET_ISPUBLIC=${PER_ISPUBLIC}
		#SET_ISCONTACT=${PER_ISCONTACT} # not implemented in flickcurl
		SET_ISFRIEND=${PER_ISFRIEND}
		SET_ISFAMILY=${PER_ISFAMILY}
		SET_PERMCOMMENT=${PER_PERMCOMMENT}
		SET_ADDMETA=${PER_ADDMETA}
	else
		echo "*** Getting permissions for photo ID ${PHOTOID} ***"
		PERMS=$(@flickcurl@ --quiet photos.getPerms "${PHOTOID}" \
			| tee >(cat - >&5) \
			| grep -o '\(public: [^ ]*\|contact: [^ ]*\|friend: [^ ]*\|family: [^ ]*\|add comment: .*\|add metadata: .*\)' \
			| sed -e 's/: /=/g' -e 's/ /-/g'
		)
		[[ -z "${PERMS}" ]] && exit -4
		{ read PHOTO_ISPUBLIC; read PHOTO_ISFRIEND; read PHOTO_ISFAMILY; read PHOTO_PERMCOMMENT; read PHOTO_ADDMETA; } < <(parseperms ${PERMS})
		SET_ISPUBLIC=${PER_ISPUBLIC:-${PHOTO_ISPUBLIC}}
		#SET_ISCONTACT=${PER_ISCONTACT:-${PHOTO_ISCONTACT}} # not implemented in flickcurl
		SET_ISFRIEND=${PER_ISFRIEND:-${PHOTO_ISFRIEND}}
		SET_ISFAMILY=${PER_ISFAMILY:-${PHOTO_ISFAMILY}}
		SET_PERMCOMMENT=${PER_PERMCOMMENT:-${PHOTO_PERMCOMMENT}}
		SET_ADDMETA=${PER_ADDMETA:-${PHOTO_ADDMETA}}
		if [[ "${SET_ISPUBLIC}" == "${PHOTO_ISPUBLIC}" \
			&& "${SET_ISFRIEND}" == "${PHOTO_ISFRIEND}" && "${SET_ISFAMILY}" == "${PHOTO_ISFAMILY}" \
			&& "${SET_PERMCOMMENT}" == "${PHOTO_PERMCOMMENT}" && "${SET_ADDMETA}" == "${PHOTO_ADDMETA}" ]]; then
			echo "*** Skipping setting permissions for photo ID ${PHOTOID}, no change ***"
			continue
		fi
	fi
	echo "*** Setting permissions for photo ID ${PHOTOID} ***"
	# photos.setPerms PHOTO-ID IS-PUBLIC IS-FRIEND IS-FAMILY PERM-COMMENT PERM-ADDMETA
	@flickcurl@ --quiet photos.setPerms "${PHOTOID}" "${SET_ISPUBLIC}" "${SET_ISFRIEND}" "${SET_ISFAMILY}" "${SET_PERMCOMMENT}" "${SET_ADDMETA}" \
	|| exit -5
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
