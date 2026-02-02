{
  description = "AES67 Linux daemon with web UI and kernel module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";

    cpp-httplib = {
      url = "github:bondagit/cpp-httplib";
      flake = false;
    };
    ravenna-alsa-lkm = {
      url = "github:bondagit/ravenna-alsa-lkm/aes67-daemon";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, cpp-httplib, ravenna-alsa-lkm, ... }:
    let
      overlay = final: prev: {
        aes67-daemon-webui = final.callPackage ./nix/webui.nix {
          src = self;
        };

        aes67-daemon = final.callPackage ./nix/daemon.nix {
          src = self;
          webui = final.aes67-daemon-webui;
          cpp-httplib = cpp-httplib;
          ravenna-alsa-lkm = ravenna-alsa-lkm;
        };

        aes67-kernel-module = final.callPackage ./nix/kernel-module.nix {
          ravenna-alsa-lkm = ravenna-alsa-lkm;
          kernel = final.linuxPackages.kernel;
          kernelModuleMakeFlags = final.linuxPackages.kernelModuleMakeFlags;
        };

        aes67-kernel-module-latest = final.callPackage ./nix/kernel-module.nix {
          ravenna-alsa-lkm = ravenna-alsa-lkm;
          kernel = final.linuxPackages_latest.kernel;
          kernelModuleMakeFlags = final.linuxPackages_latest.kernelModuleMakeFlags;
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          inherit (pkgs) aes67-daemon aes67-daemon-webui aes67-kernel-module aes67-kernel-module-latest;
          default = pkgs.aes67-daemon;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cmake
            ninja
            pkg-config
            boost
            avahi
            systemd
            alsa-lib
            libfaac
            nodejs
          ];
        };
      }
    )
    // {
      overlays.default = overlay;
      nixosModules.default = import ./nix/module.nix;
    };
}
