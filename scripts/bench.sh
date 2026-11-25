#!/usr/bin/env bash
# strawdotez: mede a abertura do shell e compara com o orçamento
#   bash scripts/bench.sh              (50 aberturas, bash e zsh)
#   bash scripts/bench.sh 100          (100 aberturas)
# Orçamento (ms): BUDGET_BASH=30 BUDGET_ZSH=50 (valores acima do medido no celular)
N="${1:-50}"
BUDGET_BASH="${BUDGET_BASH:-30}"
BUDGET_ZSH="${BUDGET_ZSH:-50}"
fail=0

medir() { # shell
    local sh="$1" i t0 t1
    command -v "$sh" >/dev/null 2>&1 || { echo "$sh: não instalado, pulando"; return 2; }
    "$sh" -i -c exit >/dev/null 2>&1   # aquece o cache
    t0=$EPOCHREALTIME
    for ((i = 0; i < N; i++)); do "$sh" -i -c exit >/dev/null 2>&1; done
    t1=$EPOCHREALTIME
    awk -v a="$t0" -v b="$t1" -v n="$N" 'BEGIN { printf "%.1f", (b - a) * 1000 / n }'
}

for sh in bash zsh; do
    ms="$(medir "$sh")"; rc=$?
    [ "$rc" = 2 ] && { echo "$ms"; continue; }
    if [ "$sh" = bash ]; then budget=$BUDGET_BASH; else budget=$BUDGET_ZSH; fi
    if awk -v m="$ms" -v b="$budget" 'BEGIN { exit !(m <= b) }'; then
        printf '%-5s %6s ms  (orçamento %s ms)  ok\n' "$sh" "$ms" "$budget"
    else
        printf '%-5s %6s ms  (orçamento %s ms)  ACIMA\n' "$sh" "$ms" "$budget"; fail=1
    fi
done
exit "$fail"
