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
        py = jazzy-pkgs.ros.python3Packages;
        patchedCatkinPkg = py."catkin-pkg".overrideAttrs (old: {
          propagatedBuildInputs = builtins.map (
            pkg: if (pkg.pname or pkg.name or "") == "setuptools" then py.setuptools_79 else pkg
          ) old.propagatedBuildInputs;
        });
        patchedColconRos = py."colcon-ros".overrideAttrs (old: {
          propagatedBuildInputs = builtins.map (
            pkg: if (pkg.pname or pkg.name or "") == "catkin-pkg" then patchedCatkinPkg else pkg
          ) old.propagatedBuildInputs;
        });
        colcon = pkgs.buildEnv {
          name = "colcon-jazzy";
          paths = [
            py.colcon
            py."colcon-bash"
            py."colcon-cmake"
            py."colcon-defaults"
            py."colcon-library-path"
            py."colcon-metadata"
            py."colcon-mixin"
            py."colcon-notification"
            py."colcon-output"
            py."colcon-package-information"
            py."colcon-package-selection"
            py."colcon-parallel-executor"
            py."colcon-python-setup-py"
            py."colcon-recursive-crawl"
            patchedColconRos
            py."colcon-test-result"
            py."colcon-zsh"
          ];
        };
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
            exec ${pkgs.zsh}/bin/zsh
          '';
        };
      }
    );
}
