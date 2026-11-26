#!/usr/bin/env python3
"""Confere .chezmoidata/fonts.yaml: ids únicos, 'default' presente e, nas demais fontes,
url https e sha256 com 64 hex."""
import re, sys
txt = open(".chezmoidata/fonts.yaml", encoding="utf-8").read()
ids, erros = [], 0
for bloco in re.split(r"(?m)^  - ", txt)[1:]:
    c = dict(re.findall(r"(?m)^\s*(\w+):\s*(.*)$", bloco))
    ids.append(c.get("id"))
    if c.get("id") == "default":
        continue
    if not c.get("url", "").startswith("https://"):
        print(f"url sem https: {c.get('id')}"); erros += 1
    if not re.fullmatch(r"[0-9a-f]{64}", c.get("sha256", "")):
        print(f"sha256 inválido: {c.get('id')}"); erros += 1
if len(ids) != len(set(ids)): print("id repetido"); erros += 1
if "default" not in ids: print("falta a fonte default"); erros += 1
if erros:
    sys.exit(1)
print(f"OK: {len(ids)} fontes")
