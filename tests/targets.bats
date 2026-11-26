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

@test "debian: não gerencia .termux, .zshrc nem .hushlogin; gerencia .bashrc e o straw" {
    init_cfg debian
    run chezmoi managed --source "$REPO" --config "$T/c.toml" --destination "$T/home" --path-style absolute
    [ "$status" -eq 0 ]
    [[ "$output" != *"/.termux"* ]]
    [[ "$output" != *"/.zshrc"* ]]
    [[ "$output" != *"/.hushlogin"* ]]
    [[ "$output" == *"/.bashrc"* ]]
    [[ "$output" == *"/.local/bin/straw"* ]]
}

@test "debian: o .bashrc gerado tem sintaxe válida e não cita o Termux" {
    init_cfg debian
    chezmoi execute-template --source "$REPO" --config "$T/c.toml" < "$REPO/dot_bashrc.tmpl" > "$T/bashrc"
    bash -n "$T/bashrc"
    ! grep -q 'termux' "$T/bashrc"
    grep -q '^straw()' "$T/bashrc"
}

@test "debian: só o script de pacotes gera conteúdo, e com sintaxe válida" {
    init_cfg debian
    for f in "$REPO"/.chezmoiscripts/*.tmpl; do
        chezmoi execute-template --source "$REPO" --config "$T/c.toml" < "$f" > "$T/s.sh"
        bash -n "$T/s.sh"
        case "$f" in
            *install-termux-packages*) grep -q 'apt-get' "$T/s.sh" ;;
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
