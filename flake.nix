{
  description = "rs-zig";
  inputs = {
    zig-flake.url = "github:mitchellh/zig-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {self, nixpkgs, flake-utils, zig-flake }:
    flake-utils.lib.eachSystem [flake-utils.lib.system.x86_64-linux] (system:
    let pkgs = import nixpkgs {
      inherit system;
    };
    zig = zig-flake.packages.${system}.master;
    in {
      devShell = (pkgs.mkShell.override{stdenv=pkgs.gcc11Stdenv;})  {
        buildInputs = [
          zig
          pkgs.librealsense-gui
        ];
      };
    });
}
