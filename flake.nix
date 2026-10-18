{
  description = "Agentifi development shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
    in {
      devShells = forAll (pkgs: {
        # Nix provides the tools; mise still runs the tasks in mise.toml.
        # Keep these versions in step with go.mod and frontend/mise.toml.
        default = pkgs.mkShell {
          packages = with pkgs; [ go_1_26 nodejs_24 mise sqlite postgresql_17 ];
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
