# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- `straw` command: `straw menu` (tools by module and tool profiles, with fzf), `straw update`, `straw version`, `straw help`.
- Modules and profiles in `.chezmoidata/straw.yaml`, with package lists per environment (Termux, Debian/Ubuntu/Kali, Alpine).
- Focused modules (C/C++, Go, Rust, web, network, pentest, privacy, media, editors) and more profiles (developer, networking, pentest, creator).
- Back button and quit in the menu; `straw install <package>` to install any package by name.

## [1.1.0] - 2026-11-25

### Added
- GitHub Actions CI: renders every template in pt and en, checks syntax (`bash -n`, `zsh -n`, `shellcheck`) and runs the secret scan (gitleaks).
- `scripts/check-i18n.py`: checks that pt and en have the same messages.
- `scripts/bench.sh`: measures shell startup against a time budget.
- Pre-commit hook (`.githooks/pre-commit`) that blocks commits with tokens or private keys.
- `CHECKLIST.md`: what to update for each kind of change.

## [1.0.0] - 2026-11-25

First stable release.

### Added
- One-command install for Termux with chezmoi, safe to re-run.
- Install questions: language (pt/en), git name and email, phone/tablet profile, logo and header, Termux welcome message.
- bash and zsh sharing the same aliases and functions, with fzf and zoxide.
- Package list in `.chezmoidata/packages.yaml`, with a notice for packages that fail to install.
- One-line installer (`install.sh`) with a `--defaults` mode.
- Messages in Portuguese and English, with fallback when a translation is missing.
- README in English and Portuguese, with screenshots, and MIT license.
