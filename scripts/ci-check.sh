#!/usr/bin/env bash
# strawdotez: checagens automáticas (rodam no GitHub e no celular)
#   bash scripts/ci-check.sh        (dentro do repositório)
# Precisa de: chezmoi, bash, zsh e python3. Use CHEZMOI=/caminho/chezmoi para outro binário.
set -u
CZ="${CHEZMOI:-chezmoi}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
case "$PREFIX" in /data/data/com.termux*) ;; *) export PREFIX=/data/data/com.termux/files/usr ;; esac
fail=0
ok()  { printf '  ok   %s\n' "$1"; }
bad() { printf '  ERRO %s\n' "$1"; fail=1; }

echo "== mensagens pt/en"
(cd "$REPO" && python3 scripts/check-i18n.py) && ok "i18n" || bad "i18n: faltam chaves"

for lang in pt en; do
    echo "== idioma: $lang"
    H="$(mktemp -d)"
    if ! HOME="$H" "$CZ" init -S "$REPO" --promptDefaults --promptChoice "Idioma / Language (pt or en)=$lang" >"$H/init.log" 2>&1; then
        bad "init ($lang)"; cat "$H/init.log"; continue
    fi
    ok "init"
    for f in .bashrc .zshrc; do
        if HOME="$H" "$CZ" -S "$REPO" cat "$H/$f" >"$H/$f.out" 2>"$H/err"; then
            ok "renderiza $f"
        else
            bad "renderiza $f"; cat "$H/err"; continue
        fi
    done
    bash -n "$H/.bashrc.out" 2>"$H/err" && ok "bash -n .bashrc" || { bad "bash -n .bashrc"; cat "$H/err"; }
    zsh -n "$H/.zshrc.out" 2>"$H/err" && ok "zsh -n .zshrc" || { bad "zsh -n .zshrc"; cat "$H/err"; }
    for s in "$REPO"/.chezmoiscripts/*.tmpl; do
        n="$(basename "$s")"
        if HOME="$H" "$CZ" -S "$REPO" execute-template <"$s" >"$H/s.sh" 2>"$H/err"; then
            bash -n "$H/s.sh" 2>"$H/err" && ok "script $n" || { bad "script $n (sintaxe)"; cat "$H/err"; }
        else
            bad "script $n (render)"; cat "$H/err"
        fi
    done
done

echo
[ "$fail" = 0 ] && echo "TUDO OK" || echo "FALHOU"
exit "$fail"
