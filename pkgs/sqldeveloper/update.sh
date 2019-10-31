#!/usr/bin/env bash

NIX_FILE="${0%/*}/default.nix"
URL_BASE="https://www.oracle.com/technetwork/developer-tools/sql-developer/downloads/index.html"

echo "Checking updates ..."
FILES=$(curl -Ls "${URL_BASE}" | grep -m 1 -o "[^'\" ]*/sqldeveloper-[0-9.]*-no-jre.zip")
[[ $? -ne 0 ]] && exit 1

VERSION=$(echo ${FILES##*/} | cut -d - -f 2)

echo "Version: ${VERSION}"
if grep -qF "\"${VERSION}\"" "${NIX_FILE}"; then
	echo "File ${NIX_FILE} is already in this version!" >&2
	exit 2
fi

for I in ${FILES}; do
	FILE="/tmp/${I##*/}"
	echo "Opening ${URL_BASE} ..."
	echo "* accept the OTN License Agreement"
	echo "* download https:${I} with login into OTN"
	echo "* save the downloaded file as ${FILE}"
	echo "* press Enter to continue..."
	read
	HASH=$(nix-prefetch-url --type sha256 "file://${FILE}")
	if [[ $? -eq 0 ]]; then
		echo "Hash of file '${FILE}': ${HASH}"
		echo "Updating ${NIX_FILE} for file '${FILE}' ..."
		sed -i \
			-e "s/^\\(\\s*sha256 = \"\\)[^\"]*\\(\";.*\$\\)/\\1${HASH}\\2/" \
			"${NIX_FILE}"
	else
		echo "Cannot find the downloaded file ${FILE}" >&2
		exit 3
	fi
done

echo "Updating ${NIX_FILE} for version '${VERSION}' ..."
exec sed -i \
	-e "s/^\\(\\s*version = \"\\)[^\"]*\\(\";.*\$\\)/\\1${VERSION}\\2/" \
	"${NIX_FILE}"
