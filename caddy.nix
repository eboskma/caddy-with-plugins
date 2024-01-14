{ self, ... }: {
  perSystem = { self', pkgs, lib, ... }: {
    packages.caddy-with-cloudflare =
      self.lib.caddyWithPackages {
        inherit (pkgs) caddy buildGoModule;
        plugins = [ "github.com/caddy-dns/cloudflare@a9d3ae2690a1d232bc9f8fc8b15bd4e0a6960eec" ];
        vendorHash = "sha256-VOhsXWm+IR+tUplVFkV3nzmZiS4rWKbDzkbYIPRm5ZY=";
      };
  };

  flake = {
    lib.caddyWithPackages = { caddy, buildGoModule, plugins, vendorHash }:
      let
        pluginImports = builtins.concatStringsSep "\n"
          (map
            (pluginWithHash:
              let
                plugin = builtins.elemAt (builtins.split "@" pluginWithHash) 0;
              in
              "_ \"${plugin}\"")
            plugins);
        pluginGoGetCmds = builtins.concatStringsSep "\n" (map (plugin: "go get ${plugin}") plugins);

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
          inherit vendorHash;

          pname = "caddy-with-plugins";

          overrideModAttrs = _: {
            preBuild = "echo '${main}' > cmd/caddy/main.go";
            postConfigure = ''
              ${pluginGoGetCmds}
              go mod tidy
            '';
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
