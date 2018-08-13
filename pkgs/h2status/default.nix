{ stdenv, fetchgit
, i3status
}:

let
  version = "2013.12.30";
  xdgConfig = "h2status/config";
in

stdenv.mkDerivation rec {

  name = "h2status-${version}";

  src = fetchgit {
    url = "https://gist.github.com/memeplex/8115385";
    rev = "ceaf47ca4b6ffc0947447a201f6b24bca60dd487";
    sha256 = "02xw1pl02kic1y3fbnq38m5skvgzj42b0463i05q8yv2azgbw41a";
  };

  buildInputs = [ i3status ];

  postPatch = ''
    substituteInPlace ./h2status \
      --replace i3status ${i3status}/bin/i3status \
      --replace "tmp=/tmp/h2status_" "tmp=\$(mktemp --tmpdir h2status_XXXXXXXXXX_)" \
      --replace ". ~/.h2statusrc" "if [[ -e ~/.config/${xdgConfig} ]]; then . ~/.config/${xdgConfig}; elif [[ -e /etc/xdg/${xdgConfig} ]]; then . /etc/xdg/${xdgConfig}; fi"
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m 555 -t $out/bin/ h2status
    install -D -m 444 -t $out/etc/ h2statusrc
    # patchShebangs will be done automatically (e.g., in the default postInstall phase)
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Simple i3status bash wrapper with json, mouse events and asynchronous update support";
    homepage = https://gist.github.com/memeplex/8115385;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.unix;
  };
}
