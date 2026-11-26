#!/usr/bin/env bats
# Alvos suportados: Termux e Debian/Ubuntu (STRAW_TARGET força o alvo nos testes).
# Sem o chezmoi no PATH os testes são pulados.

REPO="$BATS_TEST_DIRNAME/.."

setup() {
    command -v chezmoi >/dev/null 2>&1 || skip "chezmoi não instalado"
    T="$BATS_TEST_TMPDIR"; mkdir -p "$T/home"
    export HOME="$T/home"
}

init_cfg() {  # init_cfg <alvo>  -> grava $T/c.toml
    STRAW_TARGET="$1" run chezmoi init --source "$REPO" --promptDefaults \
        --promptChoice "Idioma / Language (pt or en)=pt" --config "$T/c.toml" --destination "$T/home"
}

@test "debian: o config recebe target e usa os padrões sem perguntar" {
    init_cfg debian
    [ "$status" -eq 0 ]
    grep -q 'target = "debian"' "$T/c.toml"
    grep -q 'device = "cell"' "$T/c.toml"
    grep -q 'shell = "bash"' "$T/c.toml"
}

@test "alpine ainda é recusado com mensagem clara" {
    init_cfg alpine
    [ "$status" -ne 0 ]
    [[ "$output" == *"Alpine"* ]]
}

@test "debian: ignora .termux e .hushlogin, mas não o .zshrc nem o .bashrc" {
    init_cfg debian
    run chezmoi execute-template --source "$REPO" --config "$T/c.toml" < "$REPO/.chezmoiignore"
    [ "$status" -eq 0 ]
    [[ "$output" == *$'\n.termux\n'* ]]
    [[ "$output" == *$'\n.hushlogin'* ]]
    [[ "$output" != *".zshrc"* ]]
    [[ "$output" != *".bashrc"* ]]
}

@test "debian: o .bashrc gerado tem sintaxe válida e não cita o Termux" {
    init_cfg debian
    chezmoi execute-template --source "$REPO" --config "$T/c.toml" < "$REPO/dot_bashrc.tmpl" > "$T/bashrc"
    bash -n "$T/bashrc"
    ! grep -q 'termux' "$T/bashrc"
    grep -q '^straw()' "$T/bashrc"
}

@test "debian: os scripts do Termux ficam vazios e os demais têm sintaxe válida" {
    init_cfg debian
    for f in "$REPO"/.chezmoiscripts/*.tmpl; do
        chezmoi execute-template --source "$REPO" --config "$T/c.toml" < "$f" > "$T/s.sh"
        bash -n "$T/s.sh"
        case "$f" in
            *install-termux-packages*) grep -q 'apt-get' "$T/s.sh" ;;
            *set-default-shell*) grep -q 'chsh' "$T/s.sh" ;;
            *) [ "$(tr -d '[:space:]' < "$T/s.sh")" = "" ] ;;
        esac
    done
}

@test "termux: sem a chave target (instalação antiga) continua tratado como Termux" {
    printf '[data]\nlang="en"\nname="x"\nemail="a@b.c"\ndevice="cell"\nbanner=false\nhushlogin=true\n' > "$T/old.toml"
    run chezmoi execute-template --source "$REPO" --config "$T/old.toml" < "$REPO/.chezmoiignore"
    [ "$status" -eq 0 ]
    [[ "$output" != *$'\n.termux\n'* ]]
    [[ "$output" != *".zshrc"* ]]
}

@test "instalador: STRAW_TARGET=alpine recusa antes de mexer em qualquer coisa" {
    STRAW_TARGET=alpine run timeout 10 bash "$REPO/install.sh" </dev/null
    [ "$status" -ne 0 ]
}

@test "instalador: alvo desconhecido também é recusado" {
    STRAW_TARGET=freebsd run timeout 10 bash "$REPO/install.sh" </dev/null
    [ "$status" -eq 1 ]
}

@test "debian: o .bashrc garante um TMPDIR que existe (proot)" {
    init_cfg debian
    chezmoi execute-template --source "$REPO" --config "$T/c.toml" < "$REPO/dot_bashrc.tmpl" > "$T/bashrc"
    run env -i HOME="$T/home" PATH="$PATH" TMPDIR=/nao/existe bash -c 'PS1=x; . "$1"; echo "$TMPDIR"' _ "$T/bashrc"
    [[ "$output" == *"/tmp" ]]
}

@test "debian: o .bashrc tem aliases, funções e o prompt colorido" {
    init_cfg debian
    chezmoi execute-template --source "$REPO" --config "$T/c.toml" < "$REPO/dot_bashrc.tmpl" > "$T/bashrc"
    grep -q '^alias ll=' "$T/bashrc" || grep -q "alias gs=" "$T/bashrc"
    grep -q 'PS1=' "$T/bashrc"
    ! grep -q 'termux-reload-settings' "$T/bashrc"
    ! grep -q 'uppkg' "$T/bashrc"
}

@test "debian: o .zshrc tem sintaxe válida e não usa o command_not_found do Termux" {
    command -v zsh >/dev/null 2>&1 || skip "zsh não instalado"
    init_cfg debian
    chezmoi execute-template --source "$REPO" --config "$T/c.toml" < "$REPO/dot_zshrc.tmpl" > "$T/zshrc"
    zsh -n "$T/zshrc"
    ! grep -q 'command_not_found_handler' "$T/zshrc"
    grep -q '^straw()' "$T/zshrc"
}

@test "debian: instala os plugins do zsh mas não fonte nem tema" {
    init_cfg debian
    run chezmoi execute-template --source "$REPO" --config "$T/c.toml" < "$REPO/.chezmoiexternal.toml.tmpl"
    [[ "$output" == *"zsh-autosuggestions"* ]]
    [[ "$output" != *"font.ttf"* ]]
}

@test "debian: o script do shell padrão usa o shebang do sistema" {
    init_cfg debian
    run chezmoi execute-template --source "$REPO" --config "$T/c.toml" < "$REPO/.chezmoiscripts/run_onchange_after_set-default-shell.sh.tmpl"
    [ "${lines[0]}" = "#!/bin/bash" ]
}
