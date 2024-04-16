{
  description = "An empty base flake with a devShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        inputs.treefmt-nix.flakeModule

        ./caddy.nix
      ];

      perSystem =
        {
          self',
          pkgs,
          config,
          ...
        }:
        {
          formatter = config.treefmt.build.wrapper;

          treefmt = {
            projectRootFile = "flake.lock";

            programs = {
              nixfmt = {
                enable = true;
                package = pkgs.nixfmt-rfc-style;
              };
            };
          };

          packages.default = self'.packages.caddy-with-cloudflare;
        };
    };
}
