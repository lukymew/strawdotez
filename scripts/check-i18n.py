#!/usr/bin/env python3
"""Confere .chezmoidata/i18n.yaml: mesmas chaves em pt e en, mesmos %s/%d em cada
mensagem e, nas chaves straw_* (viram messages.sh), nada de $ ou crase."""
import re, sys
msgs, lang = {}, None
for linha in open(".chezmoidata/i18n.yaml", encoding="utf-8"):
    m = re.match(r"^  (\w+):\s*$", linha)
    if m:
        lang = m.group(1); msgs[lang] = {}; continue
    m = re.match(r"^    (\w+):\s*(.*)$", linha.rstrip("\n"))
    if m and lang:
        msgs[lang][m.group(1)] = m.group(2)
pt, en = msgs.get("pt", {}), msgs.get("en", {})
erros = 0
for k in sorted(set(pt) - set(en)): print(f"falta em en: {k}"); erros += 1
for k in sorted(set(en) - set(pt)): print(f"falta em pt: {k}"); erros += 1
ph = lambda s: sorted(re.findall(r"%[sd]", s))
for k in sorted(set(pt) & set(en)):
    if ph(pt[k]) != ph(en[k]):
        print(f"%s/%d diferentes em pt e en: {k}"); erros += 1
    if k.startswith("straw_"):
        for l in ("pt", "en"):
            if "$" in msgs[l][k] or "`" in msgs[l][k]:
                print(f"$ ou crase em {l}: {k} (quebra o messages.sh)"); erros += 1
if erros:
    sys.exit(1)
print(f"OK: {len(pt)} mensagens nos dois idiomas")
