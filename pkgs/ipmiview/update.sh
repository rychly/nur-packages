#!/usr/bin/env bash

NIX_FILE="${0%/*}/default.nix"
URL_BASE="ftp://ftp.supermicro.com/utility/IPMIView/Linux/"

echo "Checking updates ..."
FILES=$(curl -s "${URL_BASE}" | grep -o 'IPMIView_.*\.tar\.gz')
[[ $? -ne 0 ]] && exit 1

VER_MAJ=$(echo "${FILES}" | head -1 | cut -d _ -f 2)
VER_MIN=$(echo "${FILES}" | head -1 | cut -d _ -f 3 | tr -d .)
VERSION="${VER_MAJ}${VER_MIN}"

echo "Version: ${VERSION}"
if grep -qF "\"${VERSION}\"" "${NIX_FILE}"; then
	echo "File ${NIX_FILE} is already in this version!" >&2
	exit 2
fi

for I in ${FILES}; do
	URL_DOWNLOAD="${URL_BASE}${I}"
	echo "Fetching ${URL_DOWNLOAD} ..."
	HASH=$(nix-prefetch-url --type sha256 "${URL_DOWNLOAD}")
	echo "Hash of file '${I}': ${HASH}"
	echo "Updating ${NIX_FILE} for file '${I}' ..."
	case "${I}" in	# sed cmd "0,/pattern/s/...pattern.../..." to replace just the first occurence
		*_Linux.*)
			sed -i \
				-e "0,/i686-linux/s/^\\(\\s*\"i686-linux\" = \"\\)[^\"]*\\(\";.*\$\\)/\\1${HASH}\\2/" \
				"${NIX_FILE}"
			;;
		*_Linux_x64.*)
			sed -i \
				-e "0,/x86_64-linux/s/^\\(\\s*\"x86_64-linux\" = \"\\)[^\"]*\\(\";.*\$\\)/\\1${HASH}\\2/" \
				"${NIX_FILE}"
			;;
		*)
			echo "Uknown format of the file-name '${I}'!" >&2
			exit 2
	esac
done

echo "Updating ${NIX_FILE} for version '${VERSION}' ..."
exec sed -i \
	-e "s/^\\(\\s*version = \"\\)[^\"]*\\(\";.*\$\\)/\\1${VERSION}\\2/" \
	"${NIX_FILE}"
