#!/data/data/com.termux/files/usr/bin/bash
# strawdotez: instalador de uma linha / one-line installer (Termux)
#   curl -fsSL https://raw.githubusercontent.com/lukymew/strawdotez/main/install.sh | bash
#   ... | bash -s -- --defaults     (sem perguntas / no questions)
set -eu

REPO="${STRAW_REPO:-lukymew/strawdotez}"

case "${LC_ALL:-${LANG:-}}" in
    pt*) L=pt ;;
    *)   L=en ;;
esac

# m "texto em português" "text in English"
m() { if [ "$L" = pt ]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi; }

case "${PREFIX:-}" in
    /data/data/com.termux*) ;;
    *) m "strawdotez: este instalador é só para o Termux." "strawdotez: this installer is for Termux only."; exit 1 ;;
esac

defaults=0
for a in "$@"; do
    case "$a" in
        -d|--defaults) defaults=1 ;;
        -h|--help) m "uso: install.sh [--defaults]" "usage: install.sh [--defaults]"; exit 0 ;;
    esac
done

if ! command -v chezmoi >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
    m "strawdotez: instalando chezmoi e git..." "strawdotez: installing chezmoi and git..."
    pkg install -y chezmoi git
fi

args=(init --apply)
if [ "$defaults" = 1 ] || ! { : </dev/tty; } 2>/dev/null; then
    # sem terminal ou pedido --defaults: usa os padrões, mantendo o idioma do sistema
    args+=(--promptDefaults --promptChoice "Idioma / Language (pt or en)=$L")
    m "strawdotez: usando as respostas padrão." "strawdotez: using default answers."
    chezmoi "${args[@]}" "$REPO"
else
    # curl | bash ocupa o stdin: as perguntas são lidas do terminal
    chezmoi "${args[@]}" "$REPO" </dev/tty
fi

m "strawdotez: pronto. Abra uma sessão nova do Termux para ver o resultado." "strawdotez: done. Open a new Termux session to see the result."
m "Dica: rode 'straw menu' para escolher ferramentas e perfis." "Tip: run 'straw menu' to pick tools and profiles."
