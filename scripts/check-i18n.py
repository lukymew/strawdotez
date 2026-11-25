#!/usr/bin/env python3
"""Confere se pt e en têm as mesmas chaves em .chezmoidata/i18n.yaml."""
import re, sys
chaves, lang = {}, None
for linha in open(".chezmoidata/i18n.yaml", encoding="utf-8"):
    m = re.match(r"^  (\w+):\s*$", linha)
    if m:
        lang = m.group(1); chaves[lang] = set(); continue
    m = re.match(r"^    (\w+):", linha)
    if m and lang:
        chaves[lang].add(m.group(1))
pt, en = chaves.get("pt", set()), chaves.get("en", set())
for k in sorted(pt - en): print(f"falta em en: {k}")
for k in sorted(en - pt): print(f"falta em pt: {k}")
if pt == en:
    print(f"OK: {len(pt)} mensagens nos dois idiomas")
else:
    sys.exit(1)
