# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

let secrets = import ./secrets.nix { };
in {
  imports = [ ./hardware-configuration.nix ./wings.nix ./pterodactyl.nix ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;
  environment.shells = with pkgs; [ bash fish ];

  environment.systemPackages = with pkgs; [
    neovim # emacs in shell
    wget
    curl # fetchers, my beloved
    fish # shell
    git # le git
  ];

  # DO NOT DISABLE.
  services.openssh.enable = true;

  nix.extraOptions = ''
    keep-outputs = true
    experimental-features = nix-command flakes
  '';

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  networking.hostName = "matest-${secrets.node}";
  networking.networkmanager.enable = true;
  networking.interfaces = secrets.net.interfaces;
  networking.defaultGateway = secrets.net.gateway;
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "en_US.UTF-8";
  users.users.root.initialHashedPassword = "";
  users.users.root.openssh.authorizedKeys.keys = [ secrets.pubkey ];
  users.users.ilya = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [ secrets.pubkey ];
    extraGroups = [ "wheel" "sudo" ];
  };

  # pterodactyl
  services.pterodactyl = {
    enable = true;
    nginxVhost = "localhost";
    user = "pterodactyl";
    dataDir = "/srv/pterodactyl";
    redisName = "pterodactis";
  };

  # wings
  services.wings = {
    enable = true;
    configuration = secrets.wings;
    pkg = (builtins.getFlake
      "github:TeamMatest/nix-wings/2de9ee5f2bf8b8d2eeb214ba272a1e7e2cbe7ae0").packages.x86_64-linux.default;
  };

  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
