{
  description = "Rust project with dylint lints, clippy, and rustfmt";

  inputs = {
    # TODO: Point to your lint library's flake.
    rust-lints.url = "github:li-kai/rust-lints";
    nixpkgs.follows = "rust-lints/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-lints,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { localSystem = system; };
      });
    in
    {
      devShells = forAllSystems ({ pkgs }: {
        default = rust-lints.lib.mkDevShell {
          inherit pkgs;
          extraRustComponents = [ "rust-analyzer" ];
          packages = [
            pkgs.just
            pkgs.cargo-nextest
            # Add your project's native dependencies here.
          ];
        };
      });
    };
}
