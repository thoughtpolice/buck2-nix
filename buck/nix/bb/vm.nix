{ pkgs }:

let
  # Basics: use TianoCore to boot in a VM, and use the latest state version
  basics-module = { pkgs, ... }: {
    virtualisation = {
      qemu.options = [ "-bios" "${pkgs.OVMF.fd}/FV/OVMF.fd" ];
      memorySize = 4096; # Use 2048MiB memory.
      cores = 4;         # Simulate 4 cores.
    };
    system.stateVersion = "23.05";
  };

  # Debugging module that helps us inspect the VM
  debug-vm-module = { modulesPath, ... }: {
    imports = [
      # The qemu-vm NixOS module gives us the `vm` attribute that we will later
      # use, and other VM-related settings
      "${modulesPath}/virtualisation/qemu-vm.nix"
    ];

    virtualisation.forwardPorts = [
      { from = "host"; host.port = 2222; guest.port = 22; }
      # buildbarn ports
      { from = "host"; host.port = 8980; guest.port = 8980; }
      { from = "host"; host.port = 7982; guest.port = 7982; }
      { from = "host"; host.port = 7984; guest.port = 7984; }
    ];

    # Root user without password and enabled SSH for playing around
    networking.firewall.enable = false;
    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = "yes";
    users.extraUsers.root.password = "";
  };

  # Buildbarn specification
  buildbarn-module = { pkgs, ... }:
    let
      buildbarn-config = pkgs.runCommand "buildbarn-config" {} ''
        mkdir -p $out
        cp -r ${./docker}/* $out
      '';

      run-buildbarn-cmd = pkgs.runCommand "run-buildbarn" {} ''
        mkdir -p $out/bin
        echo '#!/usr/bin/env bash' > $out/bin/run-buildbarn
        echo 'set -eu' >> $out/bin/run-buildbarn
        echo 'cd ${buildbarn-config}' >> $out/bin/run-buildbarn
        cat ${./docker/shim.sh} >> $out/bin/run-buildbarn
        chmod +x $out/bin/run-buildbarn
      '';

    in {
    virtualisation.docker.enable = true;
    environment.systemPackages = with pkgs; [
      git
      vim
      ripgrep
      htop
      btop
      tmux

      run-buildbarn-cmd
    ];
  };

  nixosEvaluation = pkgs.nixos [
    basics-module
    debug-vm-module
    buildbarn-module
  ];
in

nixosEvaluation.config.system.build.vm
