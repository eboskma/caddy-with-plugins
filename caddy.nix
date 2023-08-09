{ self, ... }: {
  perSystem = { self', pkgs, lib, ... }: {
    packages.caddy-with-cloudflare = 
      self.lib.caddyWithPackages {
        inherit (pkgs) caddy buildGoModule;
        plugins = [ "github.com/caddy-dns/cloudflare" ];
        vendorSha256 = "juhzEaAv3s8KAcyloSNotAddOqgMBqjOcTkbA15Gj/U=";
      };
  };

  flake = {
    lib.caddyWithPackages = { caddy, buildGoModule, plugins, vendorSha256 }: let
      pluginImports = builtins.concatStringsSep "\n" (map (plugin: "_ \"${plugin}\"") plugins);
      
        main = ''
          package main

          import (
            caddycmd "github.com/caddyserver/caddy/v2/cmd"
            _ "github.com/caddyserver/caddy/v2/modules/standard"
            _ "github.com/caddyserver/caddy/v2"
            ${pluginImports}
          )

          func main() {
            caddycmd.Main()
          }
        '';
      in
      caddy.override {
        buildGoModule = args: buildGoModule ((builtins.removeAttrs args [ "vendorHash" "pname" ]) // {
          inherit vendorSha256;
          
          pname = "caddy-with-plugins";
          
          overrideModAttrs = _: {
            preBuild = "echo '${main}' > cmd/caddy/main.go";
            postConfigure = "go mod tidy";
            postInstall = ''
              mkdir -p "$out/.magic"
              cp go.sum go.mod "$out/.magic"
            '';
          };

          postPatch = ''
            echo '${main}' > cmd/caddy/main.go
            cat cmd/caddy/main.go
          '';

          postConfigure = ''
            cp vendor/.magic/go.* .
          '';
        });
      };
  };
}
