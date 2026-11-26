#!/usr/bin/env bats
# Confere os perfis do termux.properties (celular e tablet): sintaxe e nomes das teclas extras.
# Precisa de python3; sem ele os testes são pulados.

REPO="$BATS_TEST_DIRNAME/.."

setup() { command -v python3 >/dev/null 2>&1 || skip "python3 não instalado"; }

# imprime os problemas encontrados no arquivo (nada = ok)
confere() {
    python3 - "$1" <<'PY'
import re, sys
linhas = open(sys.argv[1], encoding="utf-8").read().split("\n")
props, i = {}, 0
while i < len(linhas):
    l = linhas[i]
    if not l.strip() or l.lstrip().startswith(("#", "!")):
        i += 1; continue
    while l.rstrip().endswith("\\"):          # continuação de linha do Java Properties
        i += 1
        if i >= len(linhas) or linhas[i].lstrip().startswith("#"):
            print("continuação interrompida por comentário ou fim de arquivo"); sys.exit(0)
        l = l.rstrip()[:-1] + linhas[i].strip()
    m = re.match(r"\s*([\w.\-]+)\s*=\s*(.*)$", l)
    if not m:
        print("linha inválida:", l); sys.exit(0)
    props[m.group(1)] = m.group(2).strip(); i += 1
ek = props.get("extra-keys")
if not ek:
    print("sem extra-keys"); sys.exit(0)
ok = set("ESC TAB CTRL ALT SHIFT SHFT FN HOME END PGUP PGDN INS DEL BKSP UP DOWN LEFT RIGHT ENTER SPACE KEYBOARD DRAWER PASTE".split()) | {f"F{n}" for n in range(1, 13)}
# valor no estilo JSON do Termux (chaves sem aspas, aspas simples) -> objeto Python
txt = re.sub(r"([{,]\s*)(\w+)\s*:", r'\1"\2":', ek)
txt = re.sub(r"(:\s*)([A-Za-z][\w-]*)(?=\s*[,}\]])", r'\1"\2"', txt)
txt = re.sub(r"\b(ESC|TAB|CTRL|ALT|SHIFT|SHFT|FN|HOME|END|PGUP|PGDN|INS|DEL|BKSP|UP|DOWN|LEFT|RIGHT|ENTER|SPACE|KEYBOARD|DRAWER|PASTE)\b(?=\s*[,}\]])", r'"\1"', txt)
try:
    dados = eval(txt, {"__builtins__": {}})
except Exception as e:
    print("extra-keys inválido:", e); sys.exit(0)
def nomes(x):
    if isinstance(x, str): yield x
    elif isinstance(x, dict):
        for k in ("key", "popup"):
            if k in x: yield from nomes(x[k])
    elif isinstance(x, (list, tuple)):
        for y in x: yield from nomes(y)
for n in nomes(dados):
    if len(n) > 1 and n not in ok:
        print("tecla desconhecida:", n)
for k in ("allow-external-apps",):
    if props.get(k) != "false": print(k, "deve ficar false")
PY
}

@test "perfil celular: sintaxe e teclas válidas" {
    run confere "$REPO/private_dot_termux/private_termux.properties.cell"
    [ -z "$output" ]
}

@test "perfil tablet: sintaxe e teclas válidas" {
    run confere "$REPO/private_dot_termux/private_termux.properties.tablet"
    [ -z "$output" ]
}

@test "o tablet tem todas as teclas do celular" {
    run python3 - "$REPO/private_dot_termux" <<'PY'
import re, sys
def teclas(arq):
    t = open(f"{sys.argv[1]}/private_termux.properties.{arq}", encoding="utf-8").read()
    t = t[t.index("\nextra-keys = ["):]
    t = t[:t.index("\n\n")]
    return set(re.findall(r"\b(ESC|TAB|CTRL|ALT|HOME|END|PGUP|PGDN|DEL|BKSP|UP|DOWN|LEFT|RIGHT|ENTER|KEYBOARD|DRAWER|PASTE)\b", t))
falta = teclas("cell") - teclas("tablet")
print("faltam no tablet:", sorted(falta)) if falta else None
PY
    [ -z "$output" ]
}

@test "o conferidor pega tecla com nome errado" {
    printf 'extra-keys = [["ESC", "TABB"]]\nallow-external-apps = false\n' > "$BATS_TEST_TMPDIR/p"
    run confere "$BATS_TEST_TMPDIR/p"
    [[ "$output" == *"TABB"* ]]
}
