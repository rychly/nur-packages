#!/bin/bash
# depends: media-gfx/exiv2

shopt -s extglob
MASK=*.@(jpg|JPG)
PATTERN='%Y-%m-%d_%H-%M-%S_:basename:'
#PATTERN=':basename:--%Y-%m-%d'

if [[ "${1}" == "--help" || $(ls -- $MASK 2>/dev/null | wc -l) -eq 0 ]]; then
	echo "Usage: ${0} [--dirs]" >&2
	echo "Rename all JPG photos in current directory accroding to file number and EXIF date (pattern = ${PATTERN})." >&2
	exit -1
fi

echo "Images:"
ls -- ${MASK}

echo "Rename to sort by Exif date and time..."
@exiv2@ -v -t -F -r '_%Y%m%d%H%M%S' rename ${MASK}

echo -n "Number of files: "
COUNT=$(ls --color=never -- ${MASK} | wc -l)
echo ${COUNT}

# the logarithm of {n2} to base {n1}
# http://phodd.net/gnu-bc/bcfaq.html#bashlog
log() {
	local x=${1} n=2 l=-1
	if [[ "${2}" != "" ]]; then
		n=${x}
		x=${2}
	fi
	while ((x)); do	# these are really just double brackets without a dolar sign, i.e., not $((x))
		let l+=1 x/=n
	done
	echo ${l}
}

echo -n "Digits in seq. number: "
DIGITS=$(log 10 "${COUNT}")
echo $((++DIGITS))

echo "Rename to sequence..."
C=1; for I in ${MASK}; do
	N=$((C++))
	NAME=$(printf "%0${DIGITS}d" ${N})
	EXT=$(echo ${I##*.} | tr '[:upper:]' '[:lower:]')
	mv -nv "$I" "${NAME}.${EXT}"
done

echo "Rename to sequence with date..."
@exiv2@ -v -r ${PATTERN} rename ${MASK}

if [[ "${1}" == "--dirs" ]]; then
	echo "Moving to year-month directories..."
	find . -iname '*.jpg' -exec bash -c 'F="{}" FILE="${F##*/}"; DIR="${FILE:0:7}"; mkdir -pv "${DIR}"; mv -v "{}" "${DIR}"' \;
fi
