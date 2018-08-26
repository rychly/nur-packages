{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.security.nss;

in {

  options.rychly.security.nss = {

    fromPki = mkOption {
      type = types.bool;
      default = true;
      description = "Generate NSS PKI certificates in the system NSS db from the system SSL PKI sertificates.";
    };

    useSystemDb = mkOption {
      type = types.bool;
      default = cfg.fromPki;
      description = "Modify <code>~/.pki/nssdb/pkcs11.txt</code> to search the system NSS db while looking into a user NSS db.";
    };

  };

  config = {

    system.activationScripts = mkIf cfg.fromPki {
      nss-from-pki = ''
        nssFromPki() {
          local nssDb="$1"
          local sslDb="$2"
          if [[ ! -e "$nssDb/cert9.db" || "$nssDb/cert9.db" -ot "$sslDb" ]]; then
            # new database
            mkdir -p "$nssDb"
            rm $nssDb/* 2>/dev/null || true
            ${pkgs.nss.tools}/bin/certutil -N -d "sql:$nssDb" --empty-password -f /dev/null
            # add SSL certificates
            local buffer=""
            local name=""
            local line
            local sum
            while read line; do
              case "$line" in
                "-----BEGIN CERTIFICATE-----")
                  name="''${buffer%,*}"
                  buffer="$line"$'\n'
                  ;;
                "-----END CERTIFICATE-----")
                  buffer="$buffer"$'\n'"$line"
                  sum=$(echo "$buffer" | sha1sum | cut -d ' ' -f 1)
                  echo "$buffer" | ${pkgs.nss.tools}/bin/certutil -A -d "sql:$nssDb" -n "$name|$sum" -t "C,C,C" -f /dev/null
                  buffer=""
                  ;;
                *)
                  buffer="$buffer$line"
              esac
            done < "$sslDb"
            # make accessible
            chmod go+r $nssDb/*
          fi
        }
        nssFromPki /etc/pki/nssdb /etc/ssl/certs/ca-certificates.crt
      '';
    };

    rychly.machine.homeFiles = mkIf (cfg.useSystemDb) {
      ".pki/nssdb/pkcs11.txt" = user: {	# text '' below is prefixed by single ' so it is '''
        text = ''
          library=libnsssysinit.so
          name=NSS Internal PKCS #11 Module
          parameters=configdir='sql:${user.nixOsUser.home}/.pki/nssdb' certPrefix=''' keyPrefix=''' secmod='secmod.db' flags=optimizeSpace updatedir=''' updateCertPrefix=''' updateKeyPrefix=''' updateid=''' updateTokenDescription='''
          NSS=Flags=moduleDBOnly,internal,critical trustOrder=75 cipherOrder=100 slotParams=(1={slotFlags=[ECC,RSA,DSA,DH,RC2,RC4,DES,RANDOM,SHA1,MD5,MD2,SSL,TLS,AES,Camellia,SEED,SHA256,SHA512] askpw=any timeout=30})
        '';
      };
    };

  };

}
