{ stdenv, requireFile, dpkg, makeWrapper, makeDesktopItem
, glib, gtk2, libXtst	# required by libswt-pi-gtk-*.so extracted and linked by eclipse runtime
, libXt, alsaLib	# required by libxpcom
, jre
# GTK+2 for org.eclipse.swt.SWTError: No more handles [Unknown Mozilla path (MOZILLA_FIVE_HOME not set)]
# and set env variable SWT_GTK3=0 in ${MODELIO_PATH}/modelio.sh to use GTK+2 instead of GTK+3
# for org.eclipse.e4.core.di.InjectionException: org.eclipse.swt.SWTError: No more handles [Browser style SWT.MOZILLA and Java system property org.eclipse.swt.browser.DefaultType=mozilla are not supported with GTK 3 as XULRunner is not ported for GTK 3 yet] org.eclipse.swt.SWTError: No more handles [Browser style SWT.MOZILLA and Java system property org.eclipse.swt.browser.DefaultType=mozilla are not supported with GTK 3 as XULRunner is not ported for GTK 3 yet]
# FIXED: 1.9.2.x XULRunner releases provide require API (not available in later versions of XULRunner)
, xulrunner192
# wrapping for plugins
, plugins, symlinkJoin
}:

let
  version = "3.7.1build201803142330";	# from dpkg:/control file, Version attribute
  fileNamePrefixWithoutPlat = "modelio-3.7.1-modeler-";
  # sha256 by nix-prefetch-url --type sha256 file://${fileName}
  sha256x86 = "0pmh8w4dccvgw4wv8vvgswppcckrylqqj2rhsah7q7lgf1j9rcc8";
  sha256x64 = "0c0ixigcvnssw4waxf2sy079s13x6ih5scs8x884n2128gs6vbj9";
in

import ./common.nix {
  inherit version fileNamePrefixWithoutPlat sha256x86 sha256x64;
  inherit stdenv requireFile dpkg makeWrapper makeDesktopItem
    glib gtk2 libXtst
    libXt alsaLib
    jre
    xulrunner192
    plugins symlinkJoin;
}
