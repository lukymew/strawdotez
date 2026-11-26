#!/data/data/com.termux/files/usr/bin/bash
# strawdotez: instalador de uma linha / one-line installer (Termux, Debian, Ubuntu)
#   curl -fsSL https://raw.githubusercontent.com/lukymew/strawdotez/main/install.sh | bash
#   ... | bash -s -- --defaults     (sem perguntas / no questions)
#   ... | bash -s -- --version v1.2.0   (fixa uma versão / pin a version)
set -eu

REPO="${STRAW_REPO:-lukymew/strawdotez}"

case "${LC_ALL:-${LANG:-}}" in
    pt*) L=pt ;;
    *)   L=en ;;
esac

# m "texto em português" "text in English"
m() { if [ "$L" = pt ]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi; }

# Baixa o binário straw-ui (Go) da última release. Se falhar, segue só com o bash.
get_ui() {
    local arch base dest tmp want got
    case "$(uname -m)" in
        aarch64|arm64) arch=arm64 ;;
        x86_64|amd64)  arch=amd64 ;;
        *) return 1 ;;
    esac
    if [ -n "$ver" ]; then
        base="${STRAW_UI_URL:-https://github.com/$REPO/releases/download/$ver}"
    else
        base="${STRAW_UI_URL:-https://github.com/$REPO/releases/latest/download}"
    fi
    dest="$HOME/.local/bin/straw-ui"
    tmp="$(mktemp -d "${TMPDIR:-$HOME}/straw-ui.XXXXXX")" || return 1
    if curl -fsSL "$base/straw-ui-linux-$arch" -o "$tmp/bin" && curl -fsSL "$base/SHA256SUMS" -o "$tmp/sums"; then
        want="$(awk -v f="straw-ui-linux-$arch" '$2 == f { print $1 }' "$tmp/sums")"
        got="$(sha256sum "$tmp/bin" | cut -d' ' -f1)"
        if [ -n "$want" ] && [ "$want" = "$got" ]; then
            mkdir -p "$HOME/.local/bin"
            install -m 755 "$tmp/bin" "$dest"
            rm -f "$tmp/bin" "$tmp/sums"; rmdir "$tmp"
            return 0
        fi
    fi
    rm -f "$tmp/bin" "$tmp/sums"; rmdir "$tmp" 2>/dev/null || true
    return 1
}

# alvo: Termux, ou Debian/Ubuntu (proot-distro ou nativo)
TARGET="${STRAW_TARGET:-}"
if [ -z "$TARGET" ]; then
    case "${PREFIX:-}" in
        /data/data/com.termux*) TARGET=termux ;;
        *)
            ids=""
            [ -r /etc/os-release ] && ids="$(sed -n 's/^ID=//p;s/^ID_LIKE=//p' /etc/os-release | tr -d '"' | tr '\n' ' ')"
            case "$ids" in
                *debian*|*ubuntu*) TARGET=debian ;;
                *alpine*) TARGET=alpine ;;
                *) TARGET=unknown ;;
            esac ;;
    esac
fi
case "$TARGET" in
    termux|debian) ;;
    alpine) m "strawdotez: o Alpine ainda não é suportado (só Termux e Debian/Ubuntu)." "strawdotez: Alpine is not supported yet (only Termux and Debian/Ubuntu)."; exit 1 ;;
    *) m "strawdotez: ambiente não suportado (só Termux e Debian/Ubuntu)." "strawdotez: unsupported environment (only Termux and Debian/Ubuntu)."; exit 1 ;;
esac

defaults=0
ver="${STRAW_VERSION:-}"
while [ "$#" -gt 0 ]; do
    case "$1" in
        -d|--defaults) defaults=1 ;;
        -v|--version)  shift; ver="${1:-}" ;;
        -h|--help) m "uso: install.sh [--defaults] [--version vX.Y.Z]" "usage: install.sh [--defaults] [--version vX.Y.Z]"; exit 0 ;;
    esac
    shift
done
if [ -n "$ver" ]; then
    if ! [[ "$ver" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        m "strawdotez: versão inválida '$ver' (use algo como v1.2.0)." "strawdotez: invalid version '$ver' (use something like v1.2.0)."
        exit 1
    fi
    m "strawdotez: instalando a versão $ver (fixada: 'straw update' não atualiza; rode o instalador de novo para trocar)." "strawdotez: installing version $ver (pinned: 'straw update' will not move it; run the installer again to change)."
fi

if [ "$TARGET" = termux ]; then
    if ! command -v chezmoi >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
        m "strawdotez: instalando chezmoi e git..." "strawdotez: installing chezmoi and git..."
        pkg install -y chezmoi git
    fi
else
    sudo=""
    [ "$(id -u)" != 0 ] && command -v sudo >/dev/null 2>&1 && sudo=sudo
    if ! command -v git >/dev/null 2>&1; then
        m "strawdotez: instalando git..." "strawdotez: installing git..."
        $sudo apt-get update -qq && $sudo apt-get install -y -qq git
    fi
    export PATH="$HOME/.local/bin:$PATH"
    if ! command -v chezmoi >/dev/null 2>&1; then
        m "strawdotez: instalando o chezmoi (instalador oficial)..." "strawdotez: installing chezmoi (official installer)..."
        mkdir -p "$HOME/.local/bin"
        sh -c "$(curl -fsSL https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
    fi
fi

args=(init --apply)
[ -n "$ver" ] && args+=(--branch "$ver")
if [ "$defaults" = 1 ] || ! { : </dev/tty; } 2>/dev/null; then
    # sem terminal ou pedido --defaults: usa os padrões, mantendo o idioma do sistema
    args+=(--promptDefaults --promptChoice "Idioma / Language (pt or en)=$L")
    m "strawdotez: usando as respostas padrão." "strawdotez: using default answers."
    chezmoi "${args[@]}" "$REPO"
else
    # curl | bash ocupa o stdin: as perguntas são lidas do terminal
    chezmoi "${args[@]}" "$REPO" </dev/tty
fi

if get_ui; then
    m "strawdotez: straw-ui instalado (straw doctor e straw tools)." "strawdotez: straw-ui installed (straw doctor and straw tools)."
else
    m "strawdotez: não foi possível baixar o straw-ui. Tudo segue funcionando em bash; só 'straw doctor' e 'straw tools' ficam indisponíveis." "strawdotez: could not download straw-ui. Everything keeps working in bash; only 'straw doctor' and 'straw tools' are unavailable."
fi

if [ "$TARGET" = termux ]; then
    m "strawdotez: pronto. Abra uma sessão nova do Termux para ver o resultado." "strawdotez: done. Open a new Termux session to see the result."
else
    m "strawdotez: pronto. Rode 'exec bash' ou abra uma sessão nova para ver o resultado." "strawdotez: done. Run 'exec bash' or open a new session to see the result."
fi
m "Dica: rode 'straw menu' para escolher ferramentas e perfis." "Tip: run 'straw menu' to pick tools and profiles."
