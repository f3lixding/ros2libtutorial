# Nix Dev Shell Store Paths

There is one Nix store on the machine:

```text
/nix/store
```

A dev shell is not associated with exactly one store path. It is an environment assembled from many store paths: tools, libraries, Python packages, ROS packages, shell hooks, and generated build environments.

In this flake, one important store path is the generated ROS environment:

```nix
packages.default = jazzy-pkgs.rosEnv;

devShells.default = pkgs.mkShell {
  packages = [
    jazzy-pkgs.rosEnv
    # ...
  ];
};
```

That means `jazzy-pkgs.rosEnv` is both:

- the default package output
- one of the package inputs to the dev shell

To see the store path for the current flake's ROS environment:

```sh
nix eval --raw .#packages.x86_64-linux.default.outPath
```

Or build/evaluate the same output:

```sh
nix build .#packages.x86_64-linux.default --print-out-paths --no-link
```

Example output:

```text
/nix/store/094wv02javkigh249kzzbkvwh0qj4pk4-ros-env
```

That path is the generated ROS environment created by `jazzy.ros.buildEnv`.

## Inspecting The ROS Env

The ROS env can contain packages that were not listed directly in `nix/mk-jazzy-pkgs.nix`, because entries like `ros-core` and `common-interfaces` pull in other ROS packages transitively.

For example, to check whether `rclcpp` and `std_msgs` are present:

```sh
ros_env=$(nix eval --raw .#packages.x86_64-linux.default.outPath)

find -L "$ros_env" \
  \( -path '*/rclcppConfig.cmake' \
  -o -path '*/std_msgsConfig.cmake' \
  -o -path '*/rclcpp.hpp' \
  -o -path '*/std_msgs/msg/string.hpp' \)
```

Expected matches look like:

```text
/nix/store/...-ros-env/include/rclcpp/rclcpp/rclcpp.hpp
/nix/store/...-ros-env/include/std_msgs/std_msgs/msg/string.hpp
/nix/store/...-ros-env/share/rclcpp/cmake/rclcppConfig.cmake
/nix/store/...-ros-env/share/std_msgs/cmake/std_msgsConfig.cmake
```

The `include/...` files are what the compiler needs for `#include`.

The `share/.../cmake/*Config.cmake` files are what CMake finds when code says:

```cmake
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
```

## Inspecting The Active Shell

`nix eval` tells you what the flake currently evaluates to. An already-entered dev shell may still contain older store paths if the flake changed after the shell was started.

Inside the active dev shell, inspect the environment directly:

```sh
echo "$AMENT_PREFIX_PATH" | tr ':' '\n'
echo "$CMAKE_PREFIX_PATH" | tr ':' '\n'
echo "$LD_LIBRARY_PATH" | tr ':' '\n'
echo "$PATH" | tr ':' '\n' | rg '/nix/store'
```

These variables are what build tools and runtime tools actually see in the current shell.

Important ones:

- `AMENT_PREFIX_PATH` tells ROS tooling where ROS prefixes are.
- `CMAKE_PREFIX_PATH` tells CMake where to search for package config files like `rclcppConfig.cmake`.
- `LD_LIBRARY_PATH` tells the dynamic linker where to find shared libraries at runtime.
- `PATH` tells the shell where to find executables.

## Practical Rule

Use the flake output when you want to know what the current repository definition produces:

```sh
nix eval --raw .#packages.x86_64-linux.default.outPath
```

Use environment variables when you want to know what the current shell process is actually using:

```sh
env | sort | rg '^(AMENT_PREFIX_PATH|CMAKE_PREFIX_PATH|LD_LIBRARY_PATH|PATH)='
```
