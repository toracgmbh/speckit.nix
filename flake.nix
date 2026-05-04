{
  description = "SpecKit wrapped with uv2nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    speckit = {
      url = "github:github/spec-kit";
      flake = false;
    };

    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-github-actions,
      git-hooks,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      speckit,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      # uvLock is supplied separately from ./uv.lock so that speckit can be
      # used as a plain locked flake input without patching, avoiding IFD.
      workspace = uv2nix.lib.workspace.loadWorkspace {
        workspaceRoot = speckit;
        uvLock = lib.importTOML ./uv.lock;
      };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      pythonSets = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python3;
        in
        (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope
          (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.wheel
              overlay
            ]
          )
      );

      gitHooks = forAllSystems (
        system:
        git-hooks.lib.${system}.run {
          src = ./.;
          default_stages = [
            "pre-commit"
            "pre-push"
          ];
          hooks = {
            check-merge-conflicts.enable = true;
            check-case-conflicts.enable = true;
            mixed-line-endings.enable = true;
            trim-trailing-whitespace.enable = true;
            editorconfig-checker.enable = true;
            no-commit-to-branch = {
              enable = true;
              settings.branch = [ "main" ];
            };
            commitizen.enable = true;
            nixfmt.enable = true;
            actionlint.enable = true;
            check-yaml.enable = true;
            deadnix = {
              enable = true;
              settings.noLambdaPatternNames = true;
            };
            nil.enable = true;
            statix.enable = true;
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pythonSet = pythonSets.${system};
          virtualenv = pythonSet.mkVirtualEnv "speckit-dev-env" workspace.deps.all;
        in
        {
          default = pkgs.mkShell {
            packages = [
              virtualenv
              pkgs.uv
            ];
            buildInputs = gitHooks.${system}.enabledPackages;
            env = {
              UV_NO_SYNC = "1";
              UV_PYTHON = pythonSet.python.interpreter;
              UV_PYTHON_DOWNLOADS = "never";
            };
            shellHook = ''
              unset PYTHONPATH
              ${gitHooks.${system}.shellHook}
            '';
          };
        }
      );

      packages = forAllSystems (system: {
        default = pythonSets.${system}.mkVirtualEnv "speckit-env" workspace.deps.default;
      });

      checks = forAllSystems (system: {
        package = packages.${system}.default;
        devShell = devShells.${system}.default;
        git-hooks = gitHooks.${system};
      });

    in
    {
      inherit devShells packages checks;

      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = lib.getAttrs [
          "x86_64-linux"
          "aarch64-darwin"
        ] checks;
      };
    };
}
