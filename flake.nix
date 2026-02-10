{
  description = "Sloppy sandbox for sloppy tools";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { utils, nixpkgs, ... }:
    utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
        lib = pkgs.lib;
        jarvisDeps = [
          pkgs.firejail
          pkgs.claude-code
        ];
        jarvisPkg = pkgs.stdenvNoCC.mkDerivation {
          name = "jarvis";
          src = ./scripts;
          phases = [
            "unpackPhase"
            "installPhase"
          ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            mkdir -p $out/bin
            install -m 755 claude-sandbox.sh $out/bin/jarvis
            wrapProgram $out/bin/jarvis --prefix PATH : \
              ${lib.makeBinPath jarvisDeps}
          '';
        };
        shellLauncher = pkgs.writeShellApplication {
          name = "jarvis-shell";
          runtimeInputs = [ pkgs.nix ];
          text = ''
            if [[ $# -lt 1 ]]; then
              echo "first argument must be target directory, the rest of args are passed to nix shell"
              exit 1
            fi

            export PATH="${jarvisPkg}/bin:$PATH"

            cd "$1"

            nix shell "''${@:2}"
          '';
        };
      in
      {
        packages = {
          jarvis = jarvisPkg;
        };
        apps = {
          shell = {
            type = "app";
            program = "${shellLauncher}/bin/jarvis-shell";
          };
        };
        formatter = pkgs.nixfmt-tree;
      }
    );
}
