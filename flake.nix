{
  description = "jk-skills: Superpowers companion with five standalone skills";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosModules.default = { config, lib, ... }:
      let
        cfg = config.programs.jk-skills;
        skillNames = [
          "jk-converse"
          "jk-interview"
          "jk-philosophy"
          "jk-reflect"
          "jk-remember"
        ];
      in {
        options.programs.jk-skills = {
          enable = lib.mkEnableOption "jk-skills companion skills";
        };

        config = lib.mkIf cfg.enable {
          programs.claude-code = {
            skills = builtins.listToAttrs (map (name: {
              inherit name;
              value = ./skills/${name};
            }) skillNames);
          };
        };
      };

    checks = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        skill-structure = pkgs.runCommand "check-skill-structure" {
          src = self;
          nativeBuildInputs = [ pkgs.bash pkgs.python3 pkgs.python3Packages.pytest ];
        } ''
          cd $src
          bash scripts/check.sh
          python3 -m pytest tests/ -q
          touch $out
        '';
      });
  };
}
