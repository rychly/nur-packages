{ stdenv, fetchFromGitHub, makeWrapper, writeScript
, pythonPackages
, kmod
}:

let
  inherit (pythonPackages) python;

  version = "2017.05.07";

  systemd-service-disable-c6 = {
    description = "Disable AMD Ryzen processor C-State C6";
    wantedBy = [ "basic.target" ];
    after = [ "sysinit.target" "local-fs.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = writeScript "disable-c6-state" ''
      grep -q "^msr " /proc/modules || ${kmod}/bin/modprobe msr
      ${zenstates}/bin/zenstates --c6-disable --list
    '';
  };

  zenstates = pythonPackages.buildPythonApplication rec {

    name = "zenstates-${version}";

    src = fetchFromGitHub {
      owner = "r4m0n";
      repo = "ZenStates-Linux";
      rev = "0bc27f4740e382f2a2896dc1dabfec1d0ac96818";
      sha256 = "1h1h2n50d2cwcyw3zp4lamfvrdjy1gjghffvl3qrp6arfsfa615y";
    };

    dontConfigure = true;
    dontBuild = true;
    doCheck = false;	# there are no tests (missing nix_run_setup executed by python)

    installPhase = let
      pythonSiteDir = "${python.sitePackages}";
    in ''
      runHook preInstall
      install -D -m 444 -t $out/${pythonSiteDir} zenstates.py
      makeWrapper ${python.interpreter} $out/bin/zenstates \
        --set PYTHONPATH "$PYTHONPATH:$(toPythonPath $out)" \
        --add-flags $out/${pythonSiteDir}/zenstates.py
      runHook postInstall
    '';

    meta = with stdenv.lib; {
      description = "Tool to dynamically edit AMD Ryzen processor P-States by the msr kernel module";
      homepage = https://github.com/r4m0n/ZenStates-Linux;
      license = licenses.mit;
      #maintainers = [ maintainers.rychly ];	# TODO: register as the package maintainer
      platforms = platforms.linux;
    };

    passthru = {
      inherit systemd-service-disable-c6;
    };
  };

in zenstates
