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
          pkgs.bubblewrap
          pkgs.bash
          pkgs.which
          pkgs.pi-coding-agent
          pkgs.claude-code
        ];
        shellDeps = [
          pkgs.nix
          pkgs.bash
          pkgs.coreutils
          pkgs.inetutils
          pkgs.ps
          pkgs.gnugrep
          pkgs.gnused
          pkgs.openssh
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

            export PATH="${lib.makeBinPath (shellDeps ++ [ jarvisPkg ])}"
            # FIXME: specify deps from the outside
            # export LD_LIBRARY_PATH="${lib.makeLibraryPath [ pkgs.stdenv.cc.cc pkgs.libz ]}"

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
        lib = {
          mk-jarvis = { workdir, runtime-deps, lib-deps }: pkgs.writeShellApplication {
            name = "jarvis";
            runtimeInputs = runtime-deps;
            text = ''
              if [[ $# -ne 0 ]]; then
                echo "this script expects no arguments"
                exit 1
              fi
              export LD_LIBRARY_PATH="${lib.makeLibraryPath lib-deps}"

              cd "${workdir}"

              ${jarvisPkg}/bin/jarvis
            ''
        };
        formatter = pkgs.nixfmt-tree;
      }
    );
}
