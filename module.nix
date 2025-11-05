{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    types
    mkEnableOption
    mkOption
    mkPackageOption
    mkIf
    ;

  cfg = config.services.ixp-manager;

  settingsFormat = pkgs.formats.json {};
  configJson = settingsFormat.generate "librenms-config.json" cfg.settings;

  package = cfg.package.override {
    logDir = cfg.logDir;
    dataDir = cfg.dataDir;
  };

  artisanWrapper = pkgs.writeShellScriptBin "ixpm-artisan" ''
    cd ${package}
    sudo=exec
    if [[ "$USER" != ${cfg.user} ]]; then
      sudo='exec /run/wrappers/bin/sudo -u ${cfg.user}'
    fi
    $sudo ${package}/artisan "$@"
  '';

  configFile = pkgs.writeText "config.php" ''
    <?php
    $new_config = json_decode(file_get_contents("${cfg.dataDir}/config.json"), true);
    $config = ($config == null) ? $new_config : array_merge($config, $new_config);

    ${lib.optionalString (cfg.extraConfig != null) cfg.extraConfig}
  '';
in {
  options.services.ixp-manager = {
    enable = mkEnableOption "Enable IXP Manager, a full stack management platform for Internet Exchange Points";

    # TODO: Figure out overlays and shit
    package = mkPackageOption pkgs "librenms" {};

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = package;
      defaultText = lib.literalExpression "package";
      description = ''
        The final package used by the module. This is the package that has all overrides.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "ixpmgr";
      description = ''
        Name of the LibreNMS user.
      '';
    };

    group = mkOption {
      type = types.str;
      default = "ixpmgr";
      description = ''
        Name of the IXP Manager group.
      '';
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/ixp-manager";
      description = ''
        Path of the IXP Manager state directory.
      '';
    };

    logDir = mkOption {
      type = types.path;
      default = "/var/log/ixp-manager";
      description = ''
        Path of the IXP Manager logging directory.
      '';
    };

    # TODO: Update `settings` and `extraConfig` options to reflect IXPM stuff
    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
        options = {};
      };
      description = ''
        Attrset of the LibreNMS configuration.
        See <https://docs.librenms.org/Support/Configuration/> for reference.
        All possible options are listed [here](https://github.com/librenms/librenms/blob/master/misc/config_definitions.json).
        See <https://docs.librenms.org/Extensions/Authentication/> for setting other authentication methods.
      '';
      default = {};
      example = {
        base_url = "/librenms/";
        top_devices = true;
        top_ports = false;
      };
    };

    extraConfig = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Additional config for LibreNMS that will be appended to the `config.php`. See
        <https://github.com/librenms/librenms/blob/master/misc/config_definitions.json>
        for possible options. Useful if you want to use PHP-Functions in your config.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      group = "${cfg.group}";
      isSystemUser = true;
    };

    users.groups.${cfg.group} = {};
  };
}
