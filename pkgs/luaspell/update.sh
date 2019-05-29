#!/usr/bin/env bash

BRANCH="rychly/master"
NIX_FILE="${0%/*}/default.nix"
URL_GIT=$(grep -o 'https://gitlab\.com/[^"]*\.git' "${NIX_FILE}")
URL="${URL_GIT%.git}/commits/${BRANCH}?format=atom"

echo "Checking updates ..."
RSS=$(curl -s "${URL}")
VERSION=$(echo "${RSS}" | grep -m 1 -o "<updated>[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | cut -d ">" -f 2 | tr "-" ".")
TAG_URL=$(echo "${RSS}" | grep -m 1 -o "<id>[^<]*/[a-f0-9]\{32\}" | cut -d ">" -f 2) TAG="${TAG_URL##*/}"
[[ $? -ne 0 ]] && exit 1

echo "Version: ${VERSION}"
if grep -qF "\"${VERSION}\"" "${NIX_FILE}"; then
	echo "File ${NIX_FILE} is already in this version!" >&2
	exit 2
fi

HASH=$(nix-prefetch-git --quiet --url "${URL_GIT}" --rev "${TAG}" | grep -F '"sha256":' | cut -d '"' -f 4)

echo "Updating ${NIX_FILE} for version '${VERSION}' and hash '${HASH}'..."
exec sed -i \
	-e "s/^\\(\\s*version = \"\\)[^\"]*\\(\";.*\$\\)/\\1${VERSION}\\2/" \
	-e "s/^\\(\\s*sha256 = \"\\)[^\"]*\\(\";.*\$\\)/\\1${HASH}\\2/" \
	"${NIX_FILE}"
