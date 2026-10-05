<!-- markdownlint-disable MD013 -->
# Learning

A repository gathering code and documentation while learning stuff.

## Usage

### Setup

This repository uses a [Nix flake](https://nixos.wiki/wiki/flakes) to handle packages installation and more.

After enterting the repository, run `nix develop` to install the required packages and make the needed setup.

If you use `direnv`, run the `direnv allow .` **once**, in this repository, to let direnv trigger `nix develop` each time your enter the repository.

### Development tasks

This repository uses [Task](https://taskfile.dev/) to handle the common development tasks. It is installed by Nix, upon running `nix develop` (or entering the repo allowed with `direnv`).

Run `task` to obtain a list of available tasks.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE)
file for details.
