#!/usr/bin/env bash
# strawdotez: prepara o clone de desenvolvimento (rode uma vez dentro do repositório)
#   bash scripts/setup-dev.sh
set -eu
cd "$(git rev-parse --show-toplevel)"

git config core.hooksPath .githooks
echo "ok: hook de pre-commit ativado (.githooks/pre-commit)"

for c in chezmoi go shellcheck gitleaks; do
    if command -v "$c" >/dev/null 2>&1; then echo "ok: $c"; else echo "falta (opcional): $c"; fi
done
if [ -x "$HOME/bats-core/bin/bats" ] || command -v bats >/dev/null 2>&1; then
    echo "ok: bats"
else
    echo "falta (opcional): bats  ->  git clone --depth 1 https://github.com/bats-core/bats-core ~/bats-core"
fi
