# spec-kitty.nix

A Nix flake that packages [Priivacy's Spec Kitty](https://github.com/Priivacy-ai/spec-kitty)
as a reproducible, lock-pinned build using
[uv2nix](https://github.com/pyproject-nix/uv2nix).

## Why

Spec Kitty is distributed as a Python project managed with `uv`. This flake
exposes it as a regular Nix package and development shell, so you can:

- run `spec-kitty` without installing Python or `uv` globally,
- pin Spec Kitty and all of its transitive dependencies via `flake.lock` for
  reproducible builds,
- consume it as a flake input from other Nix projects.

## Getting started

### Run Spec Kitty

```sh
nix run github:toracgmbh/speckit.nix -- --help
```

### Use as a flake input

```nix
{
  inputs.spec-kitty = {
    url = "github:toracgmbh/speckit.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

The package is exposed at `spec-kitty.packages.${system}.default` &mdash; a
Python virtualenv containing the `spec-kitty` entry point.

### Development

A `devShell` with `spec-kitty`, `uv`, `just`, and the configured pre-commit hooks
is available:

```sh
nix develop
just --list
```

Common recipes:

- `just build` &mdash; build the Spec Kitty package
- `just build_shell` &mdash; build the development shell
- `just lint` &mdash; run all pre-commit hooks
- `just update` &mdash; update flake inputs

## License

Released under the [MIT License](LICENSE.md).

Spec Kitty itself is a separate project by Priivacy, distributed under its own
license; see the [upstream repository](https://github.com/Priivacy-ai/spec-kitty).
