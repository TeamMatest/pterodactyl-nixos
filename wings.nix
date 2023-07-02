{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.services.wings;
  configuration = ''
    # /etc/pterodactyl/configuration.yml managed by /etc/NixOS/wings.nix
  '' + "${cfg.configuration}";
  wings = cfg.pkg;
in {
  options.services.wings = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    configuration = mkOption {
      type = types.str;
      default = null;
    };
    version = mkOption {
      type = types.str;
      default = "latest";
    };
    pkg = mkOption { type = types.package; };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.configuration != null;
      message = "wings is enabled, configuration must be set.";
    }];

    virtualisation.docker.enable = true;
    environment.etc."pterodactyl/config.yml".text = configuration;
    environment.systemPackages = [ wings ];
    systemd.services.wings = {
      enable = cfg.enable;
      description = "Pterodactyl Wings daemon";
      after = [ "docker.service" ];
      partOf = [ "docker.service" ];
      requires = [ "docker.service" ];
      startLimitIntervalSec = 180;
      startLimitBurst = 30;
      serviceConfig = {
        User = "root";
        WorkingDirectory = "/run/wings";
        LimitNOFILE = 4096;
        PIDFile = "/var/run/wings/daemon.pid";
        ExecStart =
          "/bin/sh -c '/usr/bin/env mkdir /run/wings; /usr/bin/env cat /etc/pterodactyl/config.yml > /run/wings/config.yml; ${cfg.pkg}/bin/wings --config /run/wings/config.yml'";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
