# Suwayomi Server flake

This flake builds the Suwayomi JAR from `package.nix` and wraps it with Java 21.
It provides packages and apps for x86_64 and aarch64 Linux and aarch64 macOS.

Run commands from this directory. Nix must have `nix-command` and `flakes`
enabled. If these files are new in a Git checkout, add them so Nix can see them:

```sh
git add flake.nix flake.lock package.nix
```

## Build, run, or install

```sh
nix build .
nix run .
```

`nix run .` starts the server in the foreground. Arguments can be passed with
`nix run . -- <arguments>`. The named package and app are `.#suwayomi-server`.

To install the command in your user profile:

```sh
nix profile add .#suwayomi-server
tachidesk-server
```

## Update Suwayomi

```sh
nix run .#update
```

The updater uses [nix-update](https://github.com/Mic92/nix-update) to find the
latest stable upstream release, update the version and download hash in
`package.nix`, and build it. Run it from this repository's root. Review and
commit the resulting change if you keep this flake in Git.

To select a particular release:

```sh
nix run .#update -- --version=2.4.2366
```

If you installed Suwayomi in your user profile, apply the updated package with:

```sh
nix profile upgrade suwayomi-server
```

Use `nix profile list` to find the profile entry's name if it differs. Restart
any running Suwayomi process to use the new version.

The flake pins downloads for reproducible builds. Updates happen when you run
the updater; the flake does not schedule updates or restart the server itself.

## Update Nix dependencies

```sh
nix flake update nixpkgs
nix flake check
```

This updates Java and the build tools. It does not change the Suwayomi version
in `package.nix`; use `nix run .#update` for that.

## Use in a NixOS flake

Add this local repository as an input to your system flake:

```nix
inputs.suwayomi = {
  url = "path:/home/edward/Documents/projects/suwayomi-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Pass `inputs` to your NixOS modules through `specialArgs = { inherit inputs; };`,
then use the existing NixOS service:

```nix
{ inputs, pkgs, ... }:
{
  services.suwayomi-server = {
    enable = true;
    package = inputs.suwayomi.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
```

The NixOS service manages its own data directory. Configure it to use your
existing data if you are migrating a manual installation.

After updating this repository, refresh its input in your system flake and
rebuild:

```sh
nix flake update suwayomi
sudo nixos-rebuild switch --flake .#YOUR_HOST
```

For a command-only installation, use the same package in
`environment.systemPackages` instead of enabling the service. The flake also
exports `overlays.default` to make this package available as
`pkgs.suwayomi-server`.
