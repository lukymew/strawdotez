#!/usr/bin/env bats
# Testes do `straw config` (ler e gravar opções). Usa os textos reais gerados pelo chezmoi.
# Sem o chezmoi no PATH os testes são pulados.

REPO="$BATS_TEST_DIRNAME/.."
STRAW="$REPO/dot_local/bin/executable_straw"

setup_file() {
    command -v chezmoi >/dev/null 2>&1 || skip "chezmoi não instalado"
    D="$BATS_FILE_TMPDIR"; mkdir -p "$D/data"
    printf '[data]\nlang="en"\nname="x"\nemail="a@b.c"\ndevice="cell"\nbanner=false\nhushlogin=true\n' > "$D/c.toml"
    for f in messages.sh fonts.tsv; do
        HOME="$D" PREFIX=/data/data/com.termux/files/usr \
            chezmoi execute-template --source "$REPO" --config "$D/c.toml" < "$REPO/dot_local/share/strawdotez/$f.tmpl" > "$D/data/$f"
    done
}

setup() {
    command -v chezmoi >/dev/null 2>&1 || skip "chezmoi não instalado"
    export STRAW_DIR="$BATS_FILE_TMPDIR/data" HOME="$BATS_TEST_TMPDIR" STRAW_ENV=termux STRAW_NO_APPLY=1
    export STRAW_CONFIG="$BATS_TEST_TMPDIR/chezmoi.toml"
    cat > "$STRAW_CONFIG" <<'T'
[data]
    lang = "en"
    name = "Ana"
    email = "ana@example.com"
    device = "cell"
    banner = true
    hushlogin = true
T
}

@test "list mostra os padrões de shell e fonte quando faltam" {
    run bash "$STRAW" config list
    [ "$status" -eq 0 ]
    [[ "$output" == *$'shell\tbash'* ]]
    [[ "$output" == *$'font\tdefault'* ]]
    [[ "$output" == *$'lang\ten'* ]]
}

@test "set troca o valor de uma chave que já existe" {
    run bash "$STRAW" config set lang pt
    [ "$status" -eq 0 ]
    grep -q '^    lang = "pt"$' "$STRAW_CONFIG"
    [ "$(grep -c 'lang' "$STRAW_CONFIG")" -eq 1 ]
}

@test "set cria a chave que falta dentro de [data]" {
    run bash "$STRAW" config set shell zsh
    [ "$status" -eq 0 ]
    [ "$(sed -n 1p "$STRAW_CONFIG")" = "[data]" ]
    grep -q '^    shell = "zsh"$' "$STRAW_CONFIG"
    run bash "$STRAW" config get shell
    [ "$output" = "zsh" ]
}

@test "set aceita só fontes que existem em fonts.tsv" {
    run bash "$STRAW" config set font jetbrains
    [ "$status" -eq 0 ]
    run bash "$STRAW" config set font comic-sans
    [ "$status" -eq 2 ]
    run bash "$STRAW" config get font
    [ "$output" = "jetbrains" ]
}

@test "valor inválido é recusado e o arquivo não muda" {
    cp "$STRAW_CONFIG" "$BATS_TEST_TMPDIR/antes"
    run bash "$STRAW" config set shell fish
    [ "$status" -eq 2 ]
    run bash "$STRAW" config set device phablet
    [ "$status" -eq 2 ]
    cmp "$STRAW_CONFIG" "$BATS_TEST_TMPDIR/antes"
}

@test "chave desconhecida é recusada" {
    run bash "$STRAW" config set senha 123
    [ "$status" -eq 2 ]
    run bash "$STRAW" config get senha
    [ "$status" -eq 2 ]
}

@test "booleanos ficam sem aspas" {
    run bash "$STRAW" config set banner false
    [ "$status" -eq 0 ]
    grep -q '^    banner = false$' "$STRAW_CONFIG"
}

@test "nome com caracteres especiais é gravado como texto" {
    run bash "$STRAW" config set name 'Ana & Cia / 100%'
    [ "$status" -eq 0 ]
    run bash "$STRAW" config get name
    [ "$output" = 'Ana & Cia / 100%' ]
}

@test "aspas e barra invertida no nome são recusadas" {
    run bash "$STRAW" config set name 'a"b'
    [ "$status" -eq 2 ]
    run bash "$STRAW" config set name 'a\b'
    [ "$status" -eq 2 ]
    run bash "$STRAW" config get name
    [ "$output" = "Ana" ]
}

@test "sem o arquivo de configuração avisa e sai com 1" {
    rm "$STRAW_CONFIG"
    run bash "$STRAW" config set lang pt
    [ "$status" -eq 1 ]
}

@test "config sem terminal lista as opções" {
    run bash "$STRAW" config </dev/null
    [ "$status" -eq 0 ]
    [[ "$output" == *$'device\tcell'* ]]
}

@test "o help lista o comando config" {
    run bash "$STRAW" help
    [[ "$output" == *"straw config"* ]]
}
