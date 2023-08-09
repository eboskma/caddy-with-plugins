{
  description = "An empty base flake with a devShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [ ./caddy.nix ];

      perSystem = { self', pkgs, ... }:
        {
          formatter = pkgs.nixpkgs-fmt;

          packages.default = self'.packages.caddy;

          devShells.default = with pkgs; mkShell {
            packages = [ xcaddy go ];
          };
        };
    };
}
