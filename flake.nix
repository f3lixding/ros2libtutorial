{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    ros-nixpkgs.url = "github:lopsided98/nixpkgs?ref=nix-ros";
    flake-utils.url = "github:numtide/flake-utils";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nix-ros-overlay.inputs.nixpkgs.follows = "ros-nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      ros-nixpkgs,
      flake-utils,
      nix-ros-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        ros-pkgs = import ros-nixpkgs {
          inherit system;
        };
        jazzy-pkgs = import ./nix/mk-jazzy-pkgs.nix {
          inherit system nix-ros-overlay;
          pkgs = ros-pkgs;
        };
      in
      {
        packages.default = jazzy-pkgs.rosEnv;
        devShells.default = pkgs.mkShell {
          packages = [
            jazzy-pkgs.rosEnv
            pkgs.colcon
          ];
          shellHook = ''
            exec ${pkgs.zsh}/bin/zsh
          '';
        };
      }
    );
}
