{
  description = "hyahiaoui's learning repo flake";

  inputs = {
    # We want the latest versions of the system and software.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    utils.url = "github:numtide/flake-utils";

    # Seamless integration of git hooks with Nix
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    utils,
    git-hooks,
    ...
  }: let
    # We want to parametrizing some outputs over `system` (nixosConfigurations, for ex), but not all of them (devShell, for ex).
    # This can NOT be implemented using `flake-utils.lib.eachDefaultSystem`, cf. https://discourse.nixos.org/t/flake-home-manager-on-nixos-error-flake-utils-used/47719
    # Use the following instead, inspired by https://ayats.org/blog/no-flake-utils#when-things-go-wrong
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ] (system: function nixpkgs.legacyPackages.${system});

    # The git hooks, built per system by git-hooks.nix. `git-hooks.lib` is
    # indexed by system, so it must be derived from the `pkgs` instance
    # `forAllSystems` hands over — NOT from the top-level `system` binding,
    # which is hardcoded to aarch64-darwin for the host configurations.
    #
    # The resulting derivation is used twice: as a flake check (see `checks`)
    # and for its `shellHook` (see `devShell`), which generates
    # `.pre-commit-config.yaml` and installs `.git/hooks/pre-commit`.
    gitHooksFor = pkgs:
      git-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
        src = ./.;

        hooks = {
          # Format Nix code
          alejandra.enable = true;

          # Lint shell scripts
          shellcheck.enable = true;

          # Lint markdown files
          markdownlint.enable = true;

          # Scan for secrets
          trufflehog.enable = true;

          # Spell checker
          typos.enable = true;

          # See others in https://github.com/cachix/git-hooks.nix#built-in-hooks
        };

        # Use an alternative, faster, pre-commit implementation
        package = pkgs.prek;
      };
  in {
    # Run the hooks with `nix fmt`, over the whole repo when called bare, or
    # over the paths Nix forwards (`nix fmt path/to/file.nix ...`).
    #
    # `nix fmt` *executes* `formatter.<system>`, so this output has to be a
    # derivation exposing a runnable binary — a bare script string is not
    # enough. `writeShellApplication` provides the wrapper (and sets
    # `meta.mainProgram`, which is what `nix fmt` looks for).
    #
    # `package` and `configFile` come from the evaluated hook module rather
    # than being re-declared here, so `nix fmt`, `nix flake check` and the git
    # hook itself always agree on the same runner and the same config.
    formatter = forAllSystems (pkgs: let
      inherit (gitHooksFor pkgs) config;
      prek = "${pkgs.lib.getExe config.package} run --config ${config.configFile}";
    in
      pkgs.writeShellApplication {
        name = "run-git-hooks";
        text = ''
          if [ "$#" -eq 0 ]; then
            exec ${prek} --all-files
          else
            exec ${prek} --files "$@"
          fi
        '';
      });

    # Run the hooks in a sandbox with `nix flake check`.
    # Read-only filesystem and no internet access.
    checks = forAllSystems (pkgs: {
      pre-commit-check = gitHooksFor pkgs;
    });

    devShell = forAllSystems (
      # `mkShellNoCC` (rather than `mkShell`) because this shell only runs
      # some basic tools and compiles nothing.
      pkgs:
        pkgs.mkShellNoCC {
          packages = with pkgs; [
            fish
            go-task

            # For documentation
            zensical

            # For fast-htmx
            uv
            python314
          ];

          shellHook = ''
            # Generates `.pre-commit-config.yaml` (git-ignored, since it is a
            # build artifact of the `hooks` attrset above) and installs
            # `.git/hooks/pre-commit`. Must run before the `exec fish` below,
            # which never returns.
            ${(gitHooksFor pkgs).shellHook}

            # `nix develop` uses this to drop into an interactive fish shell.
            #
            # But direnv (via `use flake` in .envrc) also evaluates this hook
            # when loading the dev environment. There, `exec fish` would
            # replace direnv's shell with fish, which re-enters the directory,
            # re-triggers direnv, and loops forever — and makes direnv warn
            # that the hook "is taking a while to execute". direnv sets
            # DIRENV_IN_ENVRC=1 while sourcing .envrc, so in that case we skip
            # the exec and only let direnv import the environment.
            if [ -z "$DIRENV_IN_ENVRC" ]; then
              exec fish
            fi
          '';
        }
    );
  };
}
