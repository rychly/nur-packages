{ stdenv, requireFile, stardict-tools, dict
}:

let
  version = "4.0";
in

stdenv.mkDerivation rec {

  name = "stardict-lingea-lexicon-${version}";

  src = requireFile rec {
      name = "stardict-lingea-lexicon-${version}.tgz";
      url = "file:///etc/nixos/files.public/.requiredFiles/${name}";
      sha256 = "030z1rdfqyfmvmsmlj31lda1na5a8h8295s4lkv4b1pgr1fnvaf5";
      message = ''
        This Nix expression requires that ${name} already be part of the store. To
        obtain it you need to add the file to the Nix store using either:
          nix-store --add-fixed sha256 ${stdenv.lib.removePrefix "file://" url}
        or
          nix-prefetch-url --type sha256 "${url}"
      '';
    };

  sourceRoot = ".";
  dontConfigure = true;

  postUnpack = ''
    mv "tabs-html-${version}" stardict	# will use HTML, not XHTML
  '';

  buildInputs = [
    stardict-tools	# provides stardict_tabfile
    dict	# provides dictzip required by stardict_tabfile
  ];

  buildPhase = ''
    runHook preBuild
    compile_tab() {
      ## compile *.tab file
      ## params: <file.tab> <booknames-directory>
      # init
      local DECERR="!!! RECORD STRUCTURE DECODING ERROR !!!"
      local TABFILE="$1"
      local BNFILE="$2/$(basename $TABFILE .tab).txt"
      local IFOFILE="''${TABFILE%.tab}.ifo"
      # process
      if grep -q "$DECERR" "$TABFILE"; then
        echo "compile error for '$TABFILE': $DECERR" &>2
      else
        sed -i 's/\\\([^n]\)/\1/g' "$TABFILE"
        stardict_tabfile "$TABFILE"
        # set info
        local BOOKNAME=$(head -1 "$BNFILE" | cut -d . -f 1)
        sed -i \
          -e "s/^\\(bookname=\\).*\$/\\1$BOOKNAME/" \
          -e 's/^\(sametypesequence=\).*$/\1g/' \
          "$IFOFILE"
      fi
    }
    compile_tab_dir() {
      ## compile all *.tab files in the directory and removes them after the compilation
      ## params: <tab-directory> <booknames-directory>
      for TABFILE in "$1"/*.tab; do
        compile_tab "$TABFILE" "$2"
        rm "$TABFILE"
      done
    }
    compile_tab_dir stardict "booknames-${version}"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D -m 444 -t $out/share/stardict/dic stardict/*
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "StarDict dictionaries from Lexicon application developed and marketed by Lingea s.r.o.";
    homepage = https://www.lingea.cz/elektronicke-slovniky.asp;
    license = licenses.unfree;
    #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
    platforms = platforms.all;
  };
}
