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

  rosEnv =
    with jazzy.ros;
    buildEnv {
      paths = [
        ros-core
        rcl
        (lib.getDev rcl)
        rcutils
        (lib.getDev rcutils)
        rosidl-runtime-c
        (lib.getDev rosidl-runtime-c)
        rqt
        rqt-common-plugins
        rqt-service-caller
        rqt-graph
        rqt-topic
        # specific to this tutorial
        examples-rclcpp-minimal-subscriber
        examples-rclcpp-minimal-publisher
      ];
    };
}
