# speckit.nix

A Nix flake that packages [GitHub's Spec Kit](https://github.com/github/spec-kit)
as a reproducible, lock-pinned build using
[uv2nix](https://github.com/pyproject-nix/uv2nix).

## Why

Spec Kit is distributed as a Python project managed with `uv`. This flake
exposes it as a regular Nix package and development shell, so you can:

- run `specify` without installing Python or `uv` globally,
- pin Spec Kit and all of its transitive dependencies via `flake.lock` and
  `uv.lock` for reproducible builds,
- consume it as a flake input from other Nix projects.

The `uv.lock` is checked in alongside `flake.nix` so that Spec Kit can be used
as a plain locked flake input without patching, avoiding import-from-derivation.

## Getting started

### Run Spec Kit

```sh
nix run github:toracgmbh/speckit.nix -- --help
```

### Use as a flake input

```nix
{
  inputs.speckit = {
    url = "github:toracgmbh/speckit.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

The package is exposed at `speckit.packages.${system}.default` &mdash; a Python
virtualenv containing the `specify` entry point.

### Development

A `devShell` with `specify`, `uv`, `just`, and the configured pre-commit hooks
is available:

```sh
nix develop
just --list
```

Common recipes:

- `just build` &mdash; build the Spec Kit package
- `just build_shell` &mdash; build the development shell
- `just lint` &mdash; run all pre-commit hooks
- `just update` &mdash; update flake inputs

## License

Released under the [MIT License](LICENSE.md).

Spec Kit itself is a separate project by GitHub, distributed under its own
license; see the [upstream repository](https://github.com/github/spec-kit).
