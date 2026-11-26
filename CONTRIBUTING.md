# Contributing

Thanks for helping. This project is for **Termux only**, with no secrets in the repo.

## Set up
```
git clone https://github.com/lukymew/strawdotez ~/strawdotez
cd ~/strawdotez && bash scripts/setup-dev.sh
chezmoi init -S ~/strawdotez && chezmoi apply -S ~/strawdotez
```
`setup-dev.sh` turns on the pre-commit hook.

## Before you open a pull request
- Run the checks: `bash scripts/ci-check.sh`.
- Run the tests: `bats tests/` (on Termux, clone bats-core, since `bats` is not a package).
- For Go changes: `gofmt -l .`, `go vet ./...` and `go test ./...`.
- Every message goes in `.chezmoidata/i18n.yaml` in **both** `pt` and `en`. `scripts/check-i18n.py` checks this.
- Never commit tokens, keys, real e-mails or private paths. See [SECURITY.md](SECURITY.md).
- Add a line under `[Unreleased]` in `CHANGELOG.md`.

## Style
- Small commits, in the style `fix: ...`, `feat: ...`, `docs: ...`.
- Shell code must pass `shellcheck`.
- Verify that a package exists in the Termux repos before adding it (`pkg search`).

## Reporting a vulnerability
Do not open a public issue. Follow [SECURITY.md](SECURITY.md).

---

# Contribuindo

Obrigado por ajudar. O projeto é **só para Termux** e não tem segredos no repositório.

Os passos são os mesmos acima: `scripts/setup-dev.sh`, `scripts/ci-check.sh`, `bats tests/` e, para Go, `gofmt`, `go vet` e `go test`. Toda mensagem entra em `.chezmoidata/i18n.yaml` em `pt` **e** `en`. Nunca versione tokens, chaves ou e-mails reais. Registre a mudança em `[Unreleased]` no `CHANGELOG.md`. Vulnerabilidades: veja o [SECURITY.md](SECURITY.md), sem issue pública.
