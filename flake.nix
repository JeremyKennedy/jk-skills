{
  description = "jk-skills: Claude Code plugin marketplace";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosModules.default = { config, lib, ... }:
      let
        cfg = config.programs.jk-skills;
        skillNames = [
          "using-jk-skills"
          "jk-philosophy"
          "jk-plan"
          "jk-execute"
          "jk-prove-it"
          "systematic-debugging"
          "test-driven-development"
          "verification-before-completion"
          "jk-receive-review"
          "jk-code-review"
          "jk-finish-branch"
          "using-git-worktrees"
          "dispatching-parallel-agents"
          "writing-skills"
          "jk-brainstorm"
          "jk-burn-rate"
          "jk-converse"
          "jk-reflect"
          "jk-remember"
          "plugin-check"
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

            agents = {
              code-reviewer = ./agents/code-reviewer.md;
              code-explorer = ./agents/code-explorer.md;
              code-architect = ./agents/code-architect.md;
              silent-failure-hunter = ./agents/silent-failure-hunter.md;
              test-analyzer = ./agents/test-analyzer.md;
              doc-analyzer = ./agents/doc-analyzer.md;
            };

            hooks.session-start = builtins.readFile ./hooks/session-start;

            settings.hooks.SessionStart = [{
              matcher = "startup|resume|clear|compact";
              hooks = [{
                type = "command";
                command = "bash ~/.claude/hooks/session-start";
                async = false;
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
