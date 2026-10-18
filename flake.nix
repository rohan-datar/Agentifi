{
  description = "Agentifi: package, NixOS module, and development shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
      linux = [ "aarch64-linux" "x86_64-linux" ];
    in {
      packages = forAll (pkgs: rec {
        agentifi = pkgs.callPackage ./nix/package.nix {
          buildGoModule = pkgs.buildGoModule.override { go = pkgs.go_1_26; };
          src = self;
          commit = self.rev or self.dirtyRev or "";
        };
        playwright-driver = pkgs.callPackage ./nix/playwright-driver.nix { };
        default = agentifi;
      });

      nixosModules.default = import ./nix/module.nix { inherit self; };

      checks = nixpkgs.lib.genAttrs linux (s: {
        nixos = import ./nix/test.nix { inherit self; pkgs = nixpkgs.legacyPackages.${s}; };
      });

      devShells = forAll (pkgs: {
        # Nix provides the tools; mise still runs the tasks in mise.toml.
        # Keep these versions in step with go.mod and frontend/mise.toml.
        default = pkgs.mkShell {
          packages = with pkgs; [ go_1_26 nodejs_26 mise sqlite postgresql_17 ];
          # Stop mise from installing its own copies of tools Nix supplies.
          MISE_DISABLE_TOOLS = "go,node";
          # The repo's mise files must be trusted before mise reads them.
          shellHook = ''
            mise trust --quiet --all 2>/dev/null || true
          '';
        };
      });
    };
}
