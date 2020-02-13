#!/usr/bin/env bash

function getLatestSrcUrl() {
	unset BRANCH VERSION REV URL HASH
	if grep -qF fetchFromGitLab "${1}"; then
		local OWNER=$(grep -o '\sowner\s*=\s*"[^"]*"' "${1}" | cut -d '"' -f 2)
		local REPO=$(grep -o '\srepo\s*=\s*"[^"]*"' "${1}" | cut -d '"' -f 2)
		BRANCH=$(grep -o '[\s#]branch\s*=\s*"[^"]*"' "${1}" | cut -d '"' -f 2)
		[ -z "${BRANCH}" ] && BRANCH="master"
		local REV_ORIG=$(grep -o '\srev\s*=\s*"[^"]*"' "${1}" | cut -d '"' -f 2)
		local RSS=$(curl -s "https://gitlab.com/${OWNER}/${REPO}/commits/${BRANCH}?format=atom")
		VERSION=$(echo "${RSS}" | grep -m 1 -o "<updated>[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | cut -d ">" -f 2 | tr "-" ".")
		REV=$(echo "${RSS}" | grep -m 1 -o "<id>[^<]*/[a-f0-9]\{32\}" | cut -d ">" -f 2 | sed 's|.*/||')
		URL="https://gitlab.com/${OWNER}/${REPO}/-/archive/${REV}/convert-charsets-${REV}.tar.gz"
		HASH=$(nix-prefetch-url --unpack "${URL}" 2>/dev/null)
	elif grep -qF fetchFromGitHub "${1}"; then
		local OWNER=$(grep -o '\sowner\s*=\s*"[^"]*"' "${1}" | cut -d '"' -f 2)
		local REPO=$(grep -o '\srepo\s*=\s*"[^"]*"' "${1}" | cut -d '"' -f 2)
		BRANCH=$(grep -o '[\s#]branch\s*=\s*"[^"]*"' "${1}" | cut -d '"' -f 2)
		[ -z "${BRANCH}" ] && BRANCH="master"
		local REV_ORIG=$(grep -o '\srev\s*=\s*"[^"]*"' "${1}" | cut -d '"' -f 2)
		local RSS=$(curl -s "https://github.com/${OWNER}/${REPO}/commits/${BRANCH}.atom")
		VERSION=$(echo "${RSS}" | grep -m 1 -o "<updated>[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | cut -d ">" -f 2 | tr "-" ".")
		REV=$(echo "${RSS}" | grep -m 1 -o "<id>[^<]*/[a-f0-9]\{32\}" | cut -d ">" -f 2 | sed 's|.*/||')
		URL="https://github.com/${OWNER}/${REPO}/archive/${REV}.tar.gz"
		HASH=$(nix-prefetch-url --unpack "${URL}" 2>/dev/null)
	fi
	return $?
}

NIX_FILE="${0%/*}/default.nix"

echo "Checking updates ..."
getLatestSrcUrl ${NIX_FILE} || exit 1

echo "Version: ${VERSION}"
if grep -qF "\"${VERSION}\"" "${NIX_FILE}"; then
	echo "File ${NIX_FILE} is already in this version!" >&2
	exit 2
fi

echo "Source: ${URL}"
echo "Updating ${NIX_FILE} for version '${VERSION}', git-branch/rev '${BRANCH}/${REV}' and hash '${HASH}' ..."
exec sed -i \
	-e "s/^\\(\\s*version = \"\\)[^\"]*\\(\";.*\$\\)/\\1${VERSION}\\2/" \
	-e "s/^\\(\\s*rev = \"\\)[^\"]*\\(\";.*\$\\)/\\1${REV}\\2/" \
	-e "s/^\\(\\s*sha256 = \"\\)[^\"]*\\(\";.*\$\\)/\\1${HASH}\\2/" \
	"${NIX_FILE}"
