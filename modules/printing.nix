{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.rychly.printing;

  ## modules

  printerModule = types.submodule {

    options = {

      name = mkOption {
        type = types.str;
        description = "Name of the printer in CUPS.";
      };

      model = mkOption {
        type = types.str;
        description = "Model definition of the printer as a PPD file. Available values can be listed by: <code>lpinfo -m | grep modelNumber\code>";
      };

      driver = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "Driver package which provides a PPD file with the model definition (otherwise, there will be lpadmin error 'Unable to copy PPD file').";
        example = "pkgs.hplip";
      };

      deviceUri = mkOption {
        type = types.str;
        description = "URI of the printer's device, e.g.: <code>usb://Vendor/PrinterModel?serial=XXXX</code>, <code>socket://printerhostname</code>, or <code>smb://$(grep '^username=' ${smbCredentials} | cut -d = -f 2):$(grep '^password=' ${smbCredentials} | cut -d = -f 2)@smbhostname/smbprintername</code>";
      };

      info = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Description of the printer.";
      };

      location = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Description of the location of the printer.";
      };

      options = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Printer options. Available values can be listed by: <code>lpoptions -p printerName -l</code>";
        example = [ "PageSize=A4" "Duplex=DuplexNoTumble" ];
      };

    };

  };

  mainModuleOptions = {

    printers = mkOption {
      type = types.listOf printerModule;
      default = [ ];
      description = "Printers for CUPS.";
    };

    defaultPrinter = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "CUPS name of the default printer.";
    };

    webInterfaceUsers = mkOption {
      type = types.listOf types.str;
      default = [ "@SYSTEM" ];
      description = "If not empty, restrict access to the CUPS web interface to a list of user-name or @group-name items.";
    };

  };

in {

  options.rychly.printing = mainModuleOptions;

  config = mkIf (cfg.printers != [ ]) {

    services.printing.enable = true;

    # CUPS web UI access
    services.printing.extraConf = mkIf (cfg.webInterfaceUsers != [ ]) (mkAfter ''
      <Location />
        AuthType Basic
        Require user ${concatStringsSep " " cfg.webInterfaceUsers}
      </Location>
    '');

    # CUPS drivers
    services.printing.drivers = mkAfter (builtins.getAttr "driver" (zipAttrsWithNames [ "driver" ] (name: values: values) cfg.printers));

    # CUPS printers
    systemd.services.cups = {
      postStart = mkAfter (concatStringsSep "\n" (
        # wait for cupsd listening to port/socket
        [ ''
          for I in $(seq 10); do lpstat >/dev/null 2>&1 && break; sleep 1; done
        '' ]
        # remove all printers
        ++
        [ ''
          for I in $(lpstat -a | cut -d ' ' -f 1); do lpadmin -x "$I"; done
        '' ]
        ++
        # install defined printers
        map (printer:
          "lpadmin -p \"${printer.name}\" -m \"${printer.model}\" -v \"${printer.deviceUri}\""
          + optionalString (printer.info != null) " -D \"${printer.info}\""
          + optionalString (printer.location != null) " -L \"${printer.location}\""
          + concatMapStrings (option: " -o \"${option}\"") printer.options
          + " -E"
        ) cfg.printers
        ++
        # set a default printer if any
        optional (cfg.defaultPrinter != null) ''
          lpadmin -d "${cfg.defaultPrinter}"
          echo "Default ${cfg.defaultPrinter}" >/etc/cups/lpoptions
        ''
      ));
    };

    # FIXME: move outside of this set as it needs to be checked also when (cfg.printers == [ ])
    assertions = [
      {
        assertion = (cfg.defaultPrinter != null) -> (cfg.printers != [ ]);
        message = "The default CUPS printer can be set only if CUPS printers are set.";
      }
    ];

  };

}
