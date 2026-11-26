#!/usr/bin/env bats
# Testes do comando `straw` (bash). Sem rede e sem root: usa stubs no PATH.
# Rodar: bats tests/

STRAW="$BATS_TEST_DIRNAME/../dot_local/bin/executable_straw"

setup() {
    T="$BATS_TEST_TMPDIR"
    mkdir -p "$T/bin" "$T/data" "$T/home"
    export HOME="$T/home" STRAW_DIR="$T/data" CALLS="$T/calls" INSTALLED="$T/installed"
    : > "$CALLS"; : > "$INSTALLED"
    unset PREFIX STRAW_PLAIN STRAW_UI
    export STRAW_ENV=termux   # no celular não há /etc/os-release, então fixamos o ambiente

    # dados mínimos (o que o chezmoi gera)
    cat > "$T/data/messages.sh" <<'M'
M_help_title="help-title"
M_help_menu="  straw menu"
M_help_install="  straw install"
M_help_tools="  straw tools"
M_help_doctor="  straw doctor"
M_help_config="  straw config"
M_help_update="  straw update"
M_help_version="  straw version"
M_help_help="  straw help"
M_unknown="unknown: %s"
M_install_usage="usage: straw install <pkg>"
M_nothing_to_install="all installed"
M_installing="installing: %s"
M_done="done"
M_failed="failed:"
M_doctor_no_bin="no straw-ui"
M_back="Back"
M_tools_header="tools"
M_profiles_header="profiles"
M_continue="enter"
M_no_pm="no pm"
M_need_fzf="need fzf"
M_menu_header="menu %s"
M_quit="Quit"
M
    printf 'utils\tUtilities\tjq tree\tjq\tjq\t🧰\tcli\nnet\tNetwork\tnmap\tnmap\t-\t📡\tnet\n' > "$T/data/modules.tsv"
    printf 'standard\tStandard\tutils\t-\t🧰\n' > "$T/data/profiles.tsv"

    # stubs: registram a chamada; dpkg/apk consultam o arquivo "installed"
    for c in pkg apt-get sudo; do
        printf '#!/bin/bash\necho "%s $*" >> "$CALLS"\nexit "${STUB_FAIL:-0}"\n' "$c" > "$T/bin/$c"
    done
    cat > "$T/bin/apk" <<'S'
#!/bin/bash
echo "apk $*" >> "$CALLS"
if [ "$1" = info ]; then grep -qx "$3" "$INSTALLED"; exit $?; fi
exit "${STUB_FAIL:-0}"
S
    # dpkg-query -W -f='${Status}' pkg: imprime o estado se o pacote está em "installed"
    printf '#!/bin/bash\nif grep -qx "${@: -1}" "$INSTALLED"; then printf "install ok installed"; else exit 1; fi\n' > "$T/bin/dpkg-query"
    printf '#!/bin/bash\nexit 1\n' > "$T/bin/dpkg"
    chmod +x "$T"/bin/*
    # tira ~/.local/bin do PATH para não achar um straw-ui real
    PATH="$T/bin:$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '/\.local/bin$' | paste -sd:)"
    export PATH
}

@test "help lista todos os comandos" {
    run bash "$STRAW" help
    [ "$status" -eq 0 ]
    for w in menu install tools doctor config update version help; do
        [[ "$output" == *"straw $w"* ]]
    done
}

@test "comando desconhecido sai com 2" {
    run bash "$STRAW" xyz
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown: xyz"* ]]
}

@test "install sem argumento mostra o uso" {
    run bash "$STRAW" install
    [ "$status" -ne 0 ] || [[ "$output" == *"usage"* ]]
    [[ "$output" == *"usage"* ]]
}

@test "termux: install usa pkg" {
    STRAW_ENV=termux run bash "$STRAW" install foo
    grep -q "pkg install -y foo" "$CALLS"
}

@test "apt: install usa apt-get (como root ou com sudo)" {
    STRAW_ENV=apt run bash "$STRAW" install foo
    grep -q "apt-get install -y foo" "$CALLS"
}

@test "apk: install usa apk add" {
    STRAW_ENV=apk run bash "$STRAW" install foo
    grep -q "apk add foo" "$CALLS"
}

@test "pacote já instalado não reinstala" {
    echo foo > "$INSTALLED"
    STRAW_ENV=termux run bash "$STRAW" install foo
    [[ "$output" == *"all installed"* ]]
    ! grep -q "pkg install" "$CALLS"
}

@test "falha no lote cai no fallback individual e lista as falhas" {
    STUB_FAIL=1 STRAW_ENV=termux run bash "$STRAW" install a b
    [[ "$output" == *"failed:"* ]]
    [[ "$output" == *"- a"* && "$output" == *"- b"* ]]
    grep -q "pkg install -y a b" "$CALLS"
    grep -qx "pkg install -y a" "$CALLS"
    grep -qx "pkg install -y b" "$CALLS"
}

@test "doctor sem o binário avisa e sai com 1" {
    run bash "$STRAW" doctor
    [ "$status" -eq 1 ]
    [[ "$output" == *"no straw-ui"* ]]
}

@test "doctor chama o binário com os argumentos" {
    printf '#!/bin/bash\necho "ui $*"\n' > "$T/ui"; chmod +x "$T/ui"
    STRAW_UI="$T/ui" run bash "$STRAW" doctor --quick
    [ "$status" -eq 0 ]
    [ "$output" = "ui doctor --quick" ]
}

@test "tools sem o binário avisa e sai com 1" {
    run bash "$STRAW" tools
    [ "$status" -eq 1 ]
}

@test "menu de ferramentas mostra emojis e o plain os remove" {
    printf '#!/bin/bash\ncat >&2\n' > "$T/bin/fzf"; chmod +x "$T/bin/fzf"
    run bash -c "source <(sed '/^case \"\${1:-}\"/,\$d' '$STRAW'); STRAW_ENV=termux; menu_tools" </dev/null
    [[ "$output" == *"🧰 Utilities"* ]]
    STRAW_PLAIN=1 run bash -c "source <(sed '/^case \"\${1:-}\"/,\$d' '$STRAW'); menu_tools" </dev/null
    [[ "$output" != *"🧰"* ]]
    [[ "$output" == *"Utilities"* ]]
}

@test "módulo sem pacotes no ambiente não aparece" {
    printf '#!/bin/bash\ncat >&2\n' > "$T/bin/fzf"; chmod +x "$T/bin/fzf"
    STRAW_ENV=apk run bash -c "source <(sed '/^case \"\${1:-}\"/,\$d' '$STRAW'); menu_tools" </dev/null
    [[ "$output" == *"Utilities"* ]]
    [[ "$output" != *"Network"* ]]
}
