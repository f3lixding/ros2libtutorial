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

            for qt_plugins in \
              ${pkgs.lib.getBin jazzy-pkgs.rosPkgs.qt5.qtbase}/lib/qt-*/plugins \
              ${pkgs.lib.getBin jazzy-pkgs.rosPkgs.qt5.qtwayland}/lib/qt-*/plugins
            do
              if [ -d "$qt_plugins" ]; then
                export QT_PLUGIN_PATH="$qt_plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
              fi
            done

            export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
            export DISPLAY="''${DISPLAY:-:0}"
            export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
            export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:-wayland}"
            export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-xcb}"

            if [ -t 1 ]; then
              exec ${pkgs.zsh}/bin/zsh
            fi
          '';
        };
      }
    );
}
