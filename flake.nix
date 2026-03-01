{
  description = "jk-skills: Claude Code plugin marketplace";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    homeManagerModules.default = { config, lib, ... }:
      let
        cfg = config.programs.jk-skills;
        skillNames = [
          "using-jk-skills"
          "jk-philosophy"
          "jk-deep-plan"
          "jk-deep-execute"
          "jk-prove-it"
          "systematic-debugging"
          "test-driven-development"
          "verification-before-completion"
          "receiving-code-review"
          "requesting-code-review"
          "finishing-a-development-branch"
          "using-git-worktrees"
          "dispatching-parallel-agents"
          "writing-skills"
        ];
      in {
        options.programs.jk-skills = {
          enable = lib.mkEnableOption "jk-skills for Claude Code";
        };

        config = lib.mkIf cfg.enable {
          assertions = [{
            assertion = config.programs ? claude-code;
            message = "jk-skills requires programs.claude-code (from home-manager). Ensure the claude-code module is available.";
          }];

          programs.claude-code = {
            skills = builtins.listToAttrs (map (name: {
              inherit name;
              value = ./skills/${name};
            }) skillNames);

            commands = {
              jk-plan = ./commands/jk-plan.md;
              jk-execute = ./commands/jk-execute.md;
              jk-philosophy = ./commands/jk-philosophy.md;
            };

            agents = {
              code-reviewer = ./agents/code-reviewer.md;
            };

            hooks.session-start = builtins.readFile ./hooks/session-start;

            settings.hooks.SessionStart = [{
              matcher = "startup|resume|clear|compact";
              hooks = [{
                type = "command";
                command = "~/.claude/hooks/session-start";
              }];
            }];
          };
        };
      };

    checks = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        skill-structure = pkgs.runCommand "check-skill-structure" {
          src = self;
          nativeBuildInputs = [ pkgs.bash ];
        } ''
          cd $src
          bash scripts/check.sh
          touch $out
        '';
      });
  };
}
