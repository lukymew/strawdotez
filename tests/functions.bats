#!/usr/bin/env bats
# Testes das funções de shell (functions_utils_termux e aliases_termux).
# Renderiza os templates com o chezmoi e carrega as funções num bash limpo.
# Precisa do chezmoi no PATH; sem ele, os testes são pulados.

REPO="$BATS_TEST_DIRNAME/.."

setup_file() {
    command -v chezmoi >/dev/null 2>&1 || skip "chezmoi não instalado"
    D="$BATS_FILE_TMPDIR"
    printf '[data]\nlang="en"\nname="x"\nemail="a@b.c"\ndevice="cell"\nbanner=false\nhushlogin=true\n' > "$D/c.toml"
    for f in functions_utils_termux aliases_termux; do
        HOME="$D" PREFIX=/data/data/com.termux/files/usr \
            chezmoi execute-template --source "$REPO" --config "$D/c.toml" < "$REPO/.chezmoitemplates/$f" > "$D/$f.sh"
    done
}

setup() {
    command -v chezmoi >/dev/null 2>&1 || skip "chezmoi não instalado"
    D="$BATS_FILE_TMPDIR"
    W="$BATS_TEST_TMPDIR"
    cd "$W"
}

# roda um trecho de bash com as funções carregadas
fn() { bash --norc -c "shopt -s expand_aliases; source '$D/functions_utils_termux.sh'; source '$D/aliases_termux.sh'; $1"; }

@test "os arquivos renderizados têm sintaxe válida" {
    bash -n "$D/functions_utils_termux.sh"
    bash -n "$D/aliases_termux.sh"
}

@test "aliases perigosos removidos" {
    ! grep -q "alias rmrf=" "$D/aliases_termux.sh"
    ! grep -q "iptablesflush" "$D/aliases_termux.sh"
    ! grep -q "searchsploit" "$D/aliases_termux.sh"
}

@test "lcfile põe o nome em minúsculas" {
    touch "ARQUIVO.TXT"
    run fn 'lcfile ARQUIVO.TXT'
    [ -e arquivo.txt ]
}

@test "lcfile não sobrescreve um arquivo existente" {
    touch A.txt a.txt
    run fn 'lcfile A.txt'
    [ -e A.txt ] && [ -e a.txt ]
    [[ "$output" != "" ]]
}

@test "rsfile troca a substring" {
    touch foo-bar.txt
    run fn 'rsfile foo baz foo-bar.txt'
    [ -e baz-bar.txt ]
}

@test "rsfile trata * como texto, não como padrão" {
    touch "a*b.txt" "axxb.txt"
    run fn 'rsfile "*" _ "a*b.txt"'
    [ -e "a_b.txt" ]
    [ -e "axxb.txt" ]
}

@test "genpasswd gera o tamanho pedido e só caracteres permitidos" {
    run fn 'genpasswd 20'
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[A-Za-z0-9_]{20}$ ]]
}

@test "genpin gera só dígitos" {
    run fn 'genpin 6'
    [[ "$output" =~ ^[0-9]{6}$ ]]
}

@test "rot13 é reversível" {
    run fn 'echo "Hello, World" | rot13 | rot13'
    [ "$output" = "Hello, World" ]
    run fn 'echo abc | rot13'
    [ "$output" = "nop" ]
}

@test "trim-ws tira espaços no fim das linhas" {
    printf 'a  \nb\t\n' > t.txt
    run fn 'trim-ws t.txt'
    [ "$(cat t.txt)" = "$(printf 'a\nb')" ]
}

@test "jsv valida JSON bom e acusa JSON ruim" {
    command -v python3 >/dev/null || skip "sem python3"
    echo '{"a":1}' > ok.json; echo '{a:' > ruim.json
    run fn 'jsv ok.json'
    [[ "$output" == *"OK"* ]]
    run fn 'jsv ruim.json'
    [[ "$output" != *"OK"* ]]
}

@test "extract avisa quando a extensão é desconhecida" {
    touch x.desconhecida
    run fn 'extract x.desconhecida'
    [[ "$output" != "" ]]
}

@test "extract descompacta um tar.gz" {
    mkdir d && echo oi > d/f.txt && tar czf d.tar.gz d && rm -r d
    run fn 'extract d.tar.gz'
    [ -f d/f.txt ]
}

@test "clone usa -- antes da URL (checagem de texto: o git recusa as opções de qualquer jeito)" {
    grep -q 'git clone -q -- "\$1"' "$D/functions_utils_termux.sh"
}

@test "atalho sem o pacote avisa qual instalar" {
    run bash --norc -c "PATH=/usr/bin:/bin; source '$D/aliases_termux.sh'; battery"
    [ "$status" -ne 0 ]
    [[ "$output" == *"termux-api"* ]]
}

@test "command_not_found do bash sugere o pacote" {
    f="$BATS_FILE_TMPDIR/bashrc_termux.sh"
    HOME="$D" PREFIX=/data/data/com.termux/files/usr \
        chezmoi execute-template --source "$REPO" --config "$D/c.toml" < "$REPO/.chezmoitemplates/bashrc_termux" > "$f"
    run bash --norc -c "blue= red= green= yellow= rst=; $(sed -n '/^command_not_found_handle() {/,/^}/p' "$f"); command_not_found_handle adb; echo rc=\$?"
    [ "$status" -eq 0 ]
    [[ "$output" == *"rc=127"* ]]
    [[ "$output" == *"pkg install android-tools"* ]]
}

@test "command_not_found do zsh dá as mesmas dicas que o bash" {
    command -v zsh >/dev/null 2>&1 || skip "zsh não instalado"
    f="$BATS_FILE_TMPDIR/zsh_compat_termux.sh"
    HOME="$D" PREFIX=/data/data/com.termux/files/usr \
        chezmoi execute-template --source "$REPO" --config "$D/c.toml" < "$REPO/.chezmoitemplates/zsh_compat_termux" > "$f"
    run zsh -c "source '$f'; command_not_found_handler adb; echo rc=\$?"
    [ "$status" -eq 0 ]
    [[ "$output" == *"rc=127"* ]]
    [[ "$output" == *"pkg install android-tools"* ]]
}
