# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/).

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
