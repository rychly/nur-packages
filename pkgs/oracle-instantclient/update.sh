#!/usr/bin/env bash

NIX_FILE="${0%/*}/default.nix"
URL_BASE="https://www.oracle.com/technetwork/database/database-technologies/instant-client/downloads/index.html"

echo "Checking updates for x86-32 ..."
URL_BASE_X86="https://www.oracle.com"$(curl -s "${URL_BASE}" | grep -m 1 -o "[^'\" ]*/linuxsoft[^'\" ]*")
PAGE_X86="$(curl -s "${URL_BASE_X86}")"
FILES_X86="$(echo "${PAGE_X86}" | grep -o "[^'\" ]*/instantclient-basic-linux-[^'\" ]*.zip" | sort -r | head -1)
$(echo "${PAGE_X86}" | grep -o "[^'\" ]*/instantclient-sdk-linux-[^'\" ]*.zip" | sort -r | head -1)
$(echo "${PAGE_X86}" | grep -o "[^'\" ]*/instantclient-sqlplus-linux-[^'\" ]*.zip" | sort -r | head -1)
$(echo "${PAGE_X86}" | grep -o "[^'\" ]*/instantclient-odbc-linux-[^'\" ]*.zip" | sort -r | head -1)"
[[ $? -ne 0 ]] && exit 1

VERSION_X86=$(FILE=${FILES_X86##*/}; echo ${FILE%.zip} | head -1 | cut -d - -f 4)

echo "Checking updates for x86-64 ..."
URL_BASE_X64="https://www.oracle.com"$(curl -s "${URL_BASE}" | grep -m 1 -o "[^'\" ]*/linuxx86-64soft[^'\" ]*")
PAGE_X64="$(curl -s "${URL_BASE_X64}")"
FILES_X64="$(echo "${PAGE_X64}" | grep -o "[^'\" ]*/instantclient-basic-linux.x64-[^'\" ]*.zip" | sort -r | head -1)
$(echo "${PAGE_X64}" | grep -o "[^'\" ]*/instantclient-sdk-linux.x64-[^'\" ]*.zip" | sort -r | head -1)
$(echo "${PAGE_X64}" | grep -o "[^'\" ]*/instantclient-sqlplus-linux.x64-[^'\" ]*.zip" | sort -r | head -1)
$(echo "${PAGE_X64}" | grep -o "[^'\" ]*/instantclient-odbc-linux.x64-[^'\" ]*.zip" | sort -r | head -1)"
[[ $? -ne 0 ]] && exit 1

VERSION_X64=$(FILE=${FILES_X64##*/}; echo ${FILE%.zip} | head -1 | cut -d - -f 4)

VERSION="${VERSION_X86}_${VERSION_X64}"

echo "Version: ${VERSION}"
if grep -qF "\"${VERSION}\"" "${NIX_FILE}"; then
	echo "File ${NIX_FILE} is already in this version!" >&2
	exit 2
fi

for I in ${FILES_X86}; do
	FILE="/tmp/${I##*/}"
	echo "Opening ${URL_BASE_X86} ..."
	echo "* accept the OTN License Agreement"
	echo "* download ${I} with login into OTN"
	echo "* save the downloaded file as ${FILE}"
	echo "* press Enter to continue..."
	read
	HASH=$(nix-prefetch-url --type sha256 "file://${FILE}")
	if [[ $? -eq 0 ]]; then
		echo "Hash of file '${FILE}': ${HASH}"
		echo "Updating ${NIX_FILE} for file '${FILE}' ..."
		case "${I}" in	# sed cmd "0,/pattern/s/...pattern.../..." to replace just the first occurence
		*-basic-*)
			sed -i \
				-e '/"i686-linux" = \[/,/;$/s/^\(.*"basic".*\)\("[^"]*"\)\([^"]*$\)/\1"'"${HASH}"'"\3/' \
				"${NIX_FILE}"
			;;
		*-sdk-*)
			sed -i \
				-e '/"i686-linux" = \[/,/;$/s/^\(.*"sdk".*\)\("[^"]*"\)\([^"]*$\)/\1"'"${HASH}"'"\3/' \
				"${NIX_FILE}"
			;;
		*-sqlplus-*)
			sed -i \
				-e '/"i686-linux" = \[/,/;$/s/^\(.*"sqlplus".*\)\("[^"]*"\)\([^"]*$\)/\1"'"${HASH}"'"\3/' \
				"${NIX_FILE}"
			;;
		*-odbc-*)
			sed -i \
				-e '/"i686-linux" = \[/,/;$/s/^\(.*"odbc".*\)\("[^"]*"\)\([^"]*$\)/\1"'"${HASH}"'"\3/' \
				"${NIX_FILE}"
			;;
		*)
			echo "Uknown format of the file-name '${I}'!" >&2
			exit 2
		esac
	else
		echo "Cannot find the downloaded file ${FILE}" >&2
		exit 1
	fi
done

for I in ${FILES_X64}; do
	FILE="/tmp/${I##*/}"
	echo "Opening ${URL_BASE_X64} ..."
	echo "* accept the OTN License Agreement"
	echo "* download ${I} with login into OTN"
	echo "* save the downloaded file as ${FILE}"
	echo "* press Enter to continue..."
	read
	HASH=$(nix-prefetch-url --type sha256 "file://${FILE}")
	if [[ $? -eq 0 ]]; then
		echo "Hash of file '${FILE}': ${HASH}"
		echo "Updating ${NIX_FILE} for file '${FILE}' ..."
		case "${I}" in	# sed cmd "0,/pattern/s/...pattern.../..." to replace just the first occurence
		*-basic-*)
			sed -i \
				-e '/"x86_64-linux" = \[/,/;$/s/^\(.*"basic".*\)\("[^"]*"\)\([^"]*$\)/\1"'"${HASH}"'"\3/' \
				"${NIX_FILE}"
			;;
		*-sdk-*)
			sed -i \
				-e '/"x86_64-linux" = \[/,/;$/s/^\(.*"sdk".*\)\("[^"]*"\)\([^"]*$\)/\1"'"${HASH}"'"\3/' \
				"${NIX_FILE}"
			;;
		*-sqlplus-*)
			sed -i \
				-e '/"x86_64-linux" = \[/,/;$/s/^\(.*"sqlplus".*\)\("[^"]*"\)\([^"]*$\)/\1"'"${HASH}"'"\3/' \
				"${NIX_FILE}"
			;;
		*-odbc-*)
			sed -i \
				-e '/"x86_64-linux" = \[/,/;$/s/^\(.*"odbc".*\)\("[^"]*"\)\([^"]*$\)/\1"'"${HASH}"'"\3/' \
				"${NIX_FILE}"
			;;
		*)
			echo "Uknown format of the file-name '${I}'!" >&2
			exit 2
		esac
	else
		echo "Cannot find the downloaded file ${FILE}" >&2
		exit 1
	fi
done

echo "Updating ${NIX_FILE} for version '${VERSION}' ..."
exec sed -i \
	-e "s/^\\(\\s*version = \"\\)[^\"]*\\(\";.*\$\\)/\\1${VERSION}\\2/" \
	"${NIX_FILE}"
done
