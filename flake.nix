{
  description = "Suwayomi Server with an updater for stable releases";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          suwayomi-server = pkgs.callPackage ./package.nix { };
        in
        {
          inherit suwayomi-server;
          default = suwayomi-server;
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          server = {
            type = "app";
            program = nixpkgs.lib.getExe self.packages.${system}.suwayomi-server;
            meta.description = "Run Suwayomi Server";
          };
          updater = pkgs.writeShellApplication {
            name = "update-suwayomi";
            runtimeInputs = [ pkgs.nix-update ];
            text = ''
              exec nix-update --flake --use-github-releases --build suwayomi-server "$@"
            '';
          };
        in
        {
          default = server;
          suwayomi-server = server;
          update = {
            type = "app";
            program = nixpkgs.lib.getExe updater;
            meta.description = "Update package.nix to the latest stable release and build it";
          };
        }
      );

      overlays.default = final: _prev: {
        suwayomi-server = final.callPackage ./package.nix { };
      };

      checks = forAllSystems (system: {
        suwayomi-server = self.packages.${system}.suwayomi-server;
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
