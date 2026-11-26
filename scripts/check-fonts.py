#!/usr/bin/env python3
"""Confere .chezmoidata/fonts.yaml e themes.yaml: ids únicos, 'default' presente e, nas demais
entradas, url https e sha256 com 64 hex."""
import re, sys


def confere(arq):
    txt = open(arq, encoding="utf-8").read()
    ids, erros = [], 0
    for bloco in re.split(r"(?m)^  - ", txt)[1:]:
        c = dict(re.findall(r"(?m)^\s*(\w+):\s*(.*)$", bloco))
        ids.append(c.get("id"))
        if c.get("id") == "default":
            continue
        if not c.get("url", "").startswith("https://"):
            print(f"{arq}: url sem https: {c.get('id')}"); erros += 1
        if not re.fullmatch(r"[0-9a-f]{64}", c.get("sha256", "")):
            print(f"{arq}: sha256 inválido: {c.get('id')}"); erros += 1
    if len(ids) != len(set(ids)):
        print(f"{arq}: id repetido"); erros += 1
    if "default" not in ids or len(ids) < 2:
        print(f"{arq}: falta default ou as outras opções"); erros += 1
    return erros


erros = confere(".chezmoidata/fonts.yaml") + confere(".chezmoidata/themes.yaml")
if erros:
    sys.exit(1)
print("OK: fontes e temas")
