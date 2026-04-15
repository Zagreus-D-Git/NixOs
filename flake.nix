{
  description = "Vivobook unified";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    devShells = import ./dev/llm-lab.nix { inherit pkgs; };
  in {
    nixosConfigurations.vivobook-lab = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ ./nixos/configuration.nix ];
    };

    devShells.${system} = devShells;
  };
}
