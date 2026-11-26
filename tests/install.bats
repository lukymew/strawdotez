#!/usr/bin/env bats
# Testes do download do straw-ui no install.sh (função get_ui), sem rede:
# a "release" é uma pasta local servida por file://.

INSTALL="$BATS_TEST_DIRNAME/../install.sh"

setup() {
    T="$BATS_TEST_TMPDIR"
    export HOME="$T/home" TMPDIR="$T/tmp"
    mkdir -p "$HOME" "$TMPDIR" "$T/rel"
    case "$(uname -m)" in
        aarch64|arm64) A=arm64 ;;
        x86_64|amd64)  A=amd64 ;;
        *) skip "arquitetura sem binário" ;;
    esac
    printf '#!/bin/sh\necho ui\n' > "$T/rel/straw-ui-linux-$A"
    export STRAW_UI_URL="file://$T/rel"
    REPO=x; ver=""
}

# carrega só a função get_ui do install.sh
load_ui() { eval "$(sed -n '/^get_ui() {/,/^}/p' "$INSTALL")"; }

@test "com checksum correto instala o binário executável" {
    (cd "$T/rel" && sha256sum "straw-ui-linux-$A" > SHA256SUMS)
    load_ui
    run get_ui
    [ "$status" -eq 0 ]
    [ -x "$HOME/.local/bin/straw-ui" ]
}

@test "com checksum errado recusa e não instala nada" {
    echo "0000000000000000000000000000000000000000000000000000000000000000  straw-ui-linux-$A" > "$T/rel/SHA256SUMS"
    load_ui
    run get_ui
    [ "$status" -eq 1 ]
    [ ! -e "$HOME/.local/bin/straw-ui" ]
}

@test "sem o binário na release retorna erro e não instala nada" {
    rm "$T/rel/straw-ui-linux-$A"
    echo "abc  straw-ui-linux-$A" > "$T/rel/SHA256SUMS"
    load_ui
    run get_ui
    [ "$status" -eq 1 ]
    [ ! -e "$HOME/.local/bin/straw-ui" ]
}

@test "sem SHA256SUMS na release retorna erro" {
    load_ui
    run get_ui
    [ "$status" -eq 1 ]
    [ ! -e "$HOME/.local/bin/straw-ui" ]
}

@test "falha no download não deixa pasta temporária" {
    rm "$T/rel/straw-ui-linux-$A"
    load_ui
    run get_ui
    [ "$status" -eq 1 ]
    [ -z "$(ls -A "$TMPDIR")" ]
}
