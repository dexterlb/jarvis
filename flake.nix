{
  description = "Sloppy sandbox for sloppy tools";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    charmbracelet.url = "github:charmbracelet/nur";
    charmbracelet.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { utils, nixpkgs, charmbracelet, ... }:
    utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [
            charmbracelet.overlays.default
          ];
        };
        lib = pkgs.lib;
        jarvisDeps = [
          pkgs.bubblewrap
          pkgs.which
          pkgs.bash
          pkgs.findutils
          pkgs.coreutils
          pkgs.util-linux
          pkgs.curl
          pkgs.ripgrep
          pkgs.jq
        ];
        toolDeps = {
          claude = [
            pkgs.claude-code
          ];
          pi = [
            pkgs.pi-coding-agent
          ];
          goose = [
            pkgs.goose-cli
          ];
          crush = [
            pkgs.crush
          ];
        };
        toolPkg = name: pkgs.stdenvNoCC.mkDerivation {
          inherit name;
          src = ./scripts;
          phases = [
            "unpackPhase"
            "installPhase"
          ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            mkdir -p $out/bin
            install -m 755 ${name}-sandbox.sh $out/bin/jarvis
            wrapProgram $out/bin/jarvis --prefix PATH : \
              ${lib.makeBinPath (jarvisDeps ++ toolDeps."${name}")}
          '';
        };
      in
      {
        lib = {
          mk-jarvis = { workdir, runtime-deps, tool }: pkgs.writeShellApplication {
            name = "sandboxed-${tool}";
            runtimeInputs = runtime-deps;
            text = ''
              cd "${workdir}"

              ${toolPkg tool}/bin/jarvis "''${@}"
            '';
          };
        };
        formatter = pkgs.nixfmt-tree;
      }
    );
}
