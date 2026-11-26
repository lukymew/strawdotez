#!/usr/bin/env bats
# Testes do `straw update`: atualiza o chezmoi e o binário straw-ui (release servida por file://).
# Usa os textos reais gerados pelo chezmoi. Sem o chezmoi no PATH os testes são pulados.

REPO="$BATS_TEST_DIRNAME/.."
STRAW="$REPO/dot_local/bin/executable_straw"

setup_file() {
    command -v chezmoi >/dev/null 2>&1 || skip "chezmoi não instalado"
    D="$BATS_FILE_TMPDIR"; mkdir -p "$D/data"
    printf '[data]\nlang="en"\nname="x"\nemail="a@b.c"\ndevice="cell"\nbanner=false\nhushlogin=true\n' > "$D/c.toml"
    HOME="$D" PREFIX=/data/data/com.termux/files/usr \
        chezmoi execute-template --source "$REPO" --config "$D/c.toml" < "$REPO/dot_local/share/strawdotez/messages.sh.tmpl" > "$D/data/messages.sh"
}

setup() {
    command -v chezmoi >/dev/null 2>&1 || skip "chezmoi não instalado"
    case "$(uname -m)" in
        aarch64|arm64) A=arm64 ;;
        x86_64|amd64)  A=amd64 ;;
        *) skip "arquitetura sem binário" ;;
    esac
    T="$BATS_TEST_TMPDIR"; mkdir -p "$T/home/.local/bin" "$T/bin" "$T/rel" "$T/tmp"
    export HOME="$T/home" TMPDIR="$T/tmp" STRAW_DIR="$BATS_FILE_TMPDIR/data" STRAW_ENV=termux
    export STRAW_UI_URL="file://$T/rel" STRAW_PINNED=0
    # chezmoi falso: só registra a chamada
    printf '#!/bin/sh\necho "$@" >> "%s/chezmoi.log"\nexit "${FAKE_CHEZMOI_RC:-0}"\n' "$T" > "$T/bin/chezmoi"
    chmod +x "$T/bin/chezmoi"
    export PATH="$T/bin:$PATH"
    # release com um binário e o SHA256SUMS
    printf '#!/bin/sh\necho ui-novo\n' > "$T/rel/straw-ui-linux-$A"
    (cd "$T/rel" && sha256sum "straw-ui-linux-$A" > SHA256SUMS)
}

@test "baixa o straw-ui quando não existe" {
    run bash "$STRAW" update
    [ "$status" -eq 0 ]
    [[ "$output" == *"straw-ui updated"* ]]
    [ -x "$HOME/.local/bin/straw-ui" ]
    grep -q '^update$' "$T/chezmoi.log"
}

@test "troca um binário antigo pelo novo" {
    printf '#!/bin/sh\necho ui-antigo\n' > "$HOME/.local/bin/straw-ui"; chmod +x "$HOME/.local/bin/straw-ui"
    run bash "$STRAW" update
    [ "$status" -eq 0 ]
    [ "$("$HOME/.local/bin/straw-ui")" = "ui-novo" ]
}

@test "já atualizado: avisa e não mexe no arquivo" {
    cp "$T/rel/straw-ui-linux-$A" "$HOME/.local/bin/straw-ui"; chmod +x "$HOME/.local/bin/straw-ui"
    touch -d '2020-01-01' "$HOME/.local/bin/straw-ui"
    run bash "$STRAW" update
    [ "$status" -eq 0 ]
    [[ "$output" == *"already the latest"* ]]
    [ "$(date -r "$HOME/.local/bin/straw-ui" +%Y)" = "2020" ]
}

@test "checksum errado: recusa, avisa e mantém o binário atual" {
    printf '#!/bin/sh\necho ui-antigo\n' > "$HOME/.local/bin/straw-ui"; chmod +x "$HOME/.local/bin/straw-ui"
    echo "0000000000000000000000000000000000000000000000000000000000000000  straw-ui-linux-$A" > "$T/rel/SHA256SUMS"
    run bash "$STRAW" update
    [ "$status" -eq 1 ]
    [[ "$output" == *"Could not update straw-ui"* ]]
    [ "$("$HOME/.local/bin/straw-ui")" = "ui-antigo" ]
}

@test "release sem SHA256SUMS: avisa e mantém o binário" {
    printf '#!/bin/sh\necho ui-antigo\n' > "$HOME/.local/bin/straw-ui"; chmod +x "$HOME/.local/bin/straw-ui"
    rm "$T/rel/SHA256SUMS"
    run bash "$STRAW" update
    [ "$status" -eq 1 ]
    [ "$("$HOME/.local/bin/straw-ui")" = "ui-antigo" ]
}

@test "versão fixada: não atualiza o straw-ui" {
    export STRAW_PINNED=1
    run bash "$STRAW" update
    [ "$status" -eq 0 ]
    [[ "$output" == *"Pinned version"* ]]
    [ ! -e "$HOME/.local/bin/straw-ui" ]
}

@test "detecta versão fixada pelo clone em HEAD solto" {
    unset STRAW_PINNED
    src="$T/src"; mkdir -p "$src" && cd "$src"
    git init -q . && git -c user.email=a@b.c -c user.name=x commit -q --allow-empty -m x && git checkout -q --detach
    printf '#!/bin/sh\nif [ "$1" = source-path ]; then echo "%s"; exit 0; fi\necho "$@" >> "%s/chezmoi.log"\n' "$src" "$T" > "$T/bin/chezmoi"
    cd "$T"
    run bash "$STRAW" update
    [ "$status" -eq 0 ]
    [[ "$output" == *"Pinned version"* ]]
    [ ! -e "$HOME/.local/bin/straw-ui" ]
}

@test "clone em branch (não fixado) atualiza o straw-ui" {
    unset STRAW_PINNED
    src="$T/src"; mkdir -p "$src" && cd "$src"
    git init -q . && git -c user.email=a@b.c -c user.name=x commit -q --allow-empty -m x
    printf '#!/bin/sh\nif [ "$1" = source-path ]; then echo "%s"; exit 0; fi\necho "$@" >> "%s/chezmoi.log"\n' "$src" "$T" > "$T/bin/chezmoi"
    cd "$T"
    run bash "$STRAW" update
    [ "$status" -eq 0 ]
    [ -x "$HOME/.local/bin/straw-ui" ]
}

@test "se o chezmoi update falha, o erro é repassado e o straw-ui não é tocado" {
    FAKE_CHEZMOI_RC=3 run bash "$STRAW" update
    [ "$status" -eq 3 ]
    [ ! -e "$HOME/.local/bin/straw-ui" ]
}

# ---- aviso de versão nova

notice_setup() {
    command -v script >/dev/null 2>&1 || skip "script (util-linux) não instalado"
    export XDG_CACHE_HOME="$T/cache" STRAW_LATEST_TAG="$1"
    git init -q "$T/src" && git -C "$T/src" -c user.email=a@b.c -c user.name=x commit -q --allow-empty -m x && git -C "$T/src" tag "$2"
    printf '#!/bin/sh\necho %s/src\n' "$T" > "$T/bin/chezmoi"; chmod +x "$T/bin/chezmoi"
    export PATH="$T/bin:$PATH"
}

@test "aviso: versão nova aparece em 'straw version'" {
    notice_setup v1.9.0 v1.4.3
    run script -qec "bash $STRAW version" /dev/null
    [[ "$output" == *"v1.9.0"* ]]
    [[ "$output" == *"straw update"* ]]
}

@test "aviso: nada quando já está na última" {
    notice_setup v1.4.3 v1.4.3
    run script -qec "bash $STRAW version" /dev/null
    [[ "$output" != *"straw update"* ]]
}

@test "aviso: STRAW_NO_UPDATE_CHECK desliga" {
    notice_setup v1.9.0 v1.4.3
    STRAW_NO_UPDATE_CHECK=1 run script -qec "bash $STRAW version" /dev/null
    [[ "$output" != *"v1.9.0"* ]]
}

@test "aviso: sem terminal não imprime" {
    notice_setup v1.9.0 v1.4.3
    run bash "$STRAW" version
    [[ "$output" != *"straw update"* ]]
}
