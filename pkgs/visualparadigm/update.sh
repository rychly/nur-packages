#!/usr/bin/env bash

NIX_FILE="${0%/*}/default.nix"

echo "Checking updates ..."
XML_UPDATE=$(curl -s "https://www.visual-paradigm.com/download/productupdate/lz.jsp")
[[ $? -ne 0 ]] && exit 1

URL_UPDATE=$(echo "${XML_UPDATE}" | grep -o 'server address="[^"]*"' | cut -d '"' -f 2)
VER_MAJ=$(echo "${URL_UPDATE}" | cut -d / -f 5 | grep -o '[0-9]\+\.[0-9]\+')
VER_MIN=$(echo "${URL_UPDATE}" | cut -d / -f 6)
URL_DOWNLOAD="${URL_UPDATE%/*}/Visual_Paradigm_${VER_MAJ//./_}_${VER_MIN}_Linux64_InstallFree.tar.gz"

echo "Version: ${VER_MAJ}"
echo "Build number: ${VER_MIN}"
echo "Download: ${URL_DOWNLOAD}"

if grep -qF "\"${VER_MAJ}build${VER_MIN}\"" "${NIX_FILE}"; then
	echo "File ${NIX_FILE} is already in this version!" >&2
	exit 2
fi

echo "Fetching ..."
HASH=$(nix-prefetch-url --type sha256 "${URL_DOWNLOAD}")

echo "Hash: ${HASH}"

echo "Updating ${NIX_FILE} ..."
exec sed -i \
	-e "s/^\\(\\s*version = \"\\)[^\"]*\\(\";.*\$\\)/\\1${VER_MAJ}build${VER_MIN}\\2/" \
	-e "s/^\\(\\s*sha256 = \"\\)[^\"]*\\(\";.*\$\\)/\\1${HASH}\\2/" \
	"${NIX_FILE}"
