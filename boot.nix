{
  inputs,
  pkgs,
  ...
}: {
  boot = {
    kernelPackages = inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.linuxPackages_latest;
    kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "boot.shell_on_fail"
    ];
    bootspec.enable = true;
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        consoleMode = "auto";
        configurationLimit = 5;
      };
    };
    tmp.cleanOnBoot = true;
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
}
