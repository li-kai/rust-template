{
  description = "Rust project with dylint lints, clippy, and rustfmt";

  inputs = {
    # TODO: Point to your lint library's flake.
    rust-lints.url = "github:li-kai/rust-lints";
    nixpkgs.follows = "rust-lints/nixpkgs";
    hk.url = "github:jdx/hk/v1.46.0";
    hk.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-lints,
      hk,
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
            hk.packages.${pkgs.system}.hk
            # Add your project's native dependencies here.
          ];
          shellHook = ''
            # Evaluate hk.pkl with hk's built-in Rust evaluator (pklr) instead of
            # the pkl CLI, so the dev shell doesn't need to pull in pkl + a JDK.
            export HK_PKL_BACKEND=pklr

            # Install hk's git hooks (Git 2.54+ config-based hooks). Idempotent,
            # so re-run on every shell entry to keep the hook in sync with hk.pkl.
            if git rev-parse --git-dir >/dev/null 2>&1 && [ -f hk.pkl ]; then
              hk install >/dev/null 2>&1 && echo "git hooks installed via hk"
            fi
          '';
        };
      });
    };
}
