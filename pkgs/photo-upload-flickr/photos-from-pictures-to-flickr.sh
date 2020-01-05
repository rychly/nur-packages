#!/bin/sh

PHOTOS=$(@xdg-user-dir@ PICTURES)

echo "*** nahravam fotky na Internet" >&2
find "${PHOTOS}" -mindepth 1 -maxdepth 1 -type d -exec sh -c "cd {} && @out@/bin/all-upload-flickr; cd -" \; \
&& echo "### hotovo" >&2 \
|| echo "### doslo k chybe pri nahravani fotek na internet" >&2

echo "*** konec, zavrete okno aplikace, nebo stisknete Enter" >&2
read I
