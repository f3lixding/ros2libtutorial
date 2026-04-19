{
  pkgs,
  system,
  nix-ros-overlay,
}:
let
  lib = pkgs.lib;

  rosPkgs = import pkgs.path {
    inherit system;
    overlays = [
      (final: prev: {
        tbb_2022 = if prev ? tbb_2022_0 then prev.tbb_2022_0 else prev.tbb_2022;
      })
      nix-ros-overlay.overlays.default
    ];
  };

  jazzy = {
    inherit rosPkgs;
    ros = rosPkgs.rosPackages.jazzy;
  };
in
{
  inherit (jazzy) rosPkgs ros;

  rosEnv = jazzy.ros.buildEnv {
    paths =
      with jazzy.ros;
      [
        ament-cmake-core
        python-cmake-module
        ros-core
        common-interfaces
        example-interfaces
        sensor-msgs-py
        demo-nodes-cpp
        (lib.getLib rosPkgs.qt5.qtbase)
        (lib.getDev rosPkgs.qt5.qtbase)
      ];
  };
}
