# List available recipes
default:
    @just --list --justfile "{{ justfile() }}"

# Build devShell
build_shell *args:
    nix build ".#devShells.{{ shell("nix eval --impure --raw --expr 'builtins.currentSystem'") }}.default"

# Update flake inputs
update *args:
    nix flake update {{ args }}

# Build the flake
build *args:
    nix build ".#"

# Update, test and commit flake inputs
update_automatic *args:
    @just update {{ args }}
    @just build {{ args }}
    git add flake.lock
    git commit -m "build: Update flake inputs"

# Run all pre-commit hooks
lint *args:
    pre-commit run -a {{ args }}
