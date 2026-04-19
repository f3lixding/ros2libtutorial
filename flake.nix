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
        ros-pkgs = import "${nix-ros-overlay.outPath}/default.nix" {
          inherit system;
          overlays = [
            (final: prev: {
              pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                (pyFinal: pyPrev: {
                  catkin-pkg = pyPrev.catkin-pkg.overridePythonAttrs (_: {
                    build-system = [ pyFinal.setuptools_79 ];
                  });
                })
              ];
            })
          ];
        };
        jazzy-pkgs = import ./nix/mk-jazzy-pkgs.nix {
          inherit system nix-ros-overlay;
          pkgs = ros-pkgs;
        };
        colcon = pkgs.writeShellScriptBin "colcon" ''
          exec ${ros-pkgs.colcon}/bin/colcon "$@"
        '';
      in
      {
        packages.default = jazzy-pkgs.rosEnv;
        devShells.default = pkgs.mkShell {
          packages = [
            jazzy-pkgs.rosEnv
            colcon
            jazzy-pkgs.rosPkgs.python3Packages.rosdep
          ];
          shellHook = ''
            if [ -f install/setup.sh ]; then
              source install/setup.sh
            fi
            if [ -t 1 ]; then
              exec ${pkgs.zsh}/bin/zsh
            fi
          '';
        };
      }
    );
}
