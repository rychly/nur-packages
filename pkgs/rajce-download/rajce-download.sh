#!/bin/sh

if [[ $# != 1 || "${1}" == "--help" ]]; then
	echo "Usage:	$0 <url_to_rajce_gallery>" >&2
	exit 1
fi

URL="$1"

echo "Processing page '${URL}' ..."
curl --user-agent 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.4) Gecko/20100707 Gentoo Namoroka/3.6.4' "${URL}" \
| tr -d '\\' \
| grep -o '"//img[0-9]*\.rajce\.idnes\.cz/[^"]*/\(video\|images\)/[^"]*"' \
| tr -d '"' \
| while read ITEMURL; do
	echo "Processing URL ${ITEMURL} ..."
	wget -c "https:${ITEMURL}" || break
done

# <a id="p_1305880971" href="//img25.rajce.idnes.cz/d2502/15/15413/15413060_d7abe28491b74419044478445aa8b390/images/MVI_7360.jpg" class="videoThumb complete" title="">

# "\/\/img33.rajce.idnes.cz\/d3303\/15\/15413\/15413060_d7abe28491b74419044478445aa8b390\/video\/1305880971"
# <a id="p_1305880971" href="//img25.rajce.idnes.cz/d2502/15/15413/15413060_d7abe28491b74419044478445aa8b390/images/MVI_7360.jpg" class="videoThumb complete" title="">
# https://img33.rajce.idnes.cz/d3303/15/15413/15413060_d7abe28491b74419044478445aa8b390/video/1305880971
