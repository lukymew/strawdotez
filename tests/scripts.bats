#!/usr/bin/env bats
# Testes do script que aplica o termux.properties (renderizado com o chezmoi).
# Sem o chezmoi no PATH os testes são pulados.

REPO="$BATS_TEST_DIRNAME/.."

setup() {
    command -v chezmoi >/dev/null 2>&1 || skip "chezmoi não instalado"
    T="$BATS_TEST_TMPDIR"; mkdir -p "$T/home/.termux" "$T/home/.local/share/strawdotez"
    export HOME="$T/home" PREFIX=/data/data/com.termux/files/usr
    printf '[data]\nlang="en"\nname="x"\nemail="a@b.c"\ndevice="cell"\nbanner=false\nhushlogin=true\n' > "$T/c.toml"
    chezmoi execute-template --source "$REPO" --config "$T/c.toml" \
        < "$REPO/.chezmoiscripts/run_onchange_after_apply-termux-settings.sh.tmpl" > "$T/s.sh"
    echo "perfil-cell" > "$HOME/.termux/termux.properties.cell"
    echo "perfil-tablet" > "$HOME/.termux/termux.properties.tablet"
}

@test "o script renderizado tem sintaxe válida" {
    bash -n "$T/s.sh"
}

@test "trocar de perfil não conta como edição manual" {
    cp "$HOME/.termux/termux.properties.tablet" "$HOME/.termux/termux.properties"
    run bash "$T/s.sh"
    [ "$status" -eq 0 ]
    [[ "$output" != *"bak"* ]]
    [ ! -e "$HOME/.termux/termux.properties.bak" ]
    [ "$(cat "$HOME/.termux/termux.properties")" = "perfil-cell" ]
}

@test "edição manual é guardada em .bak" {
    echo "minha-edicao" > "$HOME/.termux/termux.properties"
    run bash "$T/s.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"bak"* ]]
    [ "$(cat "$HOME/.termux/termux.properties.bak")" = "minha-edicao" ]
    [ "$(cat "$HOME/.termux/termux.properties")" = "perfil-cell" ]
}

@test "rodar duas vezes seguidas não gera aviso" {
    run bash "$T/s.sh"
    run bash "$T/s.sh"
    [[ "$output" != *"bak"* ]]
}

@test "perfil atualizado numa versão nova não vira aviso" {
    run bash "$T/s.sh"                       # grava e registra o aplicado
    echo "perfil-cell-v2" > "$HOME/.termux/termux.properties.cell"   # o chezmoi atualiza o perfil
    run bash "$T/s.sh"
    [[ "$output" != *"bak"* ]]
    [ "$(cat "$HOME/.termux/termux.properties")" = "perfil-cell-v2" ]
}
