{ stdenv, fetchFromGitHub, pkgconfig, librsvg
, withGtk2 ? false, gtk2 ? null
, withGtk3 ? true, gtk3 ? null
, withQt4 ? false, qt4 ? null
, withQt5 ? false, qt5 ? null
, withLibnotify ? true, libnotify ? null
}:

assert withGtk2 -> !withGtk3 && gtk2 != null;
assert withGtk3 -> !withGtk2 && gtk3 != null;
assert withQt4 -> !withQt5 && qt4 != null;
assert withQt5 -> !withQt4 && qt5 != null;
assert withLibnotify -> libnotify != null
  && !(withQt5 || withQt4);	# notifications in dhcpcd-qt require `kde4-config` and `libkdeui.so` to link with `-lkdeui` which is not available in nixpkgs (no KDE4)

let
  version = "2019.12.11";
in

stdenv.mkDerivation rec {

  name = "dhcpcd-ui-${version}";

  src = fetchFromGitHub {
    owner = "rsmarples";
    repo = "dhcpcd-ui";
    rev = "0b8924c666f3dddb18cd7028e55573bb";
    sha256 = "0kkplp8xfchxcvnir9a575ygay3l3b28cihlfphwa0n6szc74fhd";
  };

  nativeBuildInputs = [ pkgconfig
    librsvg	# to make PNG from SVG icons by rsvg-convert
  ];
  buildInputs = [ ]
    ++ stdenv.lib.optionals (withGtk2) [ gtk2 ]
    ++ stdenv.lib.optionals (withGtk3) [ gtk3 ]
    ++ stdenv.lib.optionals (withQt4) [ qt4 ]
    ++ stdenv.lib.optionals (withQt5) [ qt5.qtbase ]
    ++ stdenv.lib.optionals (withLibnotify) [ libnotify ];

  configureFlags = [ "--with-dhcpcd-online"
    (if (withLibnotify) then "--enable-notification" else "--disable-notification") ]
    ++ stdenv.lib.optionals (withGtk2) [ "--with-gtk=gtk+-2.0" "--with-icons" ]
    ++ stdenv.lib.optionals (withGtk3) [ "--with-gtk=gtk+-3.0" "--with-icons" ]
    ++ stdenv.lib.optionals (withQt4 || withQt5) [ "--with-qt" "--with-icons" ];

  meta = with stdenv.lib; {
    description = "A graphical interface to dhcpcd";
    homepage = https://github.com/rsmarples/dhcpcd-ui;
    license = licenses.bsd2;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.linux;
  };
}
