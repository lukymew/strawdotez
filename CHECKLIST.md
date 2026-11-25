# Checklist de atualização

Antes de dar `git push`, confira o que a mudança toca.

## Sempre
- [ ] `chezmoi -S ~/strawdotez apply -v` roda sem erro
- [ ] `git status -sb` limpo e sem segredos no diff (`git diff --cached`)
- [ ] ROADMAP: marcar o item feito
- [ ] CHANGELOG: uma linha em "Unreleased" (ou na versão nova)

## Mudou uma mensagem ou texto de pergunta
- [ ] Nos dois idiomas em `.chezmoidata/i18n.yaml` (ou no dict de `.chezmoi.toml.tmpl`)
- [ ] `python scripts/check-i18n.py` mostra OK
- [ ] Texto de pergunta sem vírgula nem `=`

## Mudou uma pergunta, chave de dados ou `.chezmoidata/`
- [ ] Rodar `chezmoi init -S ~/strawdotez`
- [ ] README (en e pt-BR): tabela de perguntas
- [ ] CLAUDE.md, se a regra de trabalho mudou

## Mudou alias, função ou template de shell
- [ ] Conferir bash e zsh (`bash -n`, `zsh -n`)
- [ ] Medir abertura: `bash -i -c exit` (meta ~15 ms) e zsh (~30 ms)
- [ ] README: lista "O que vem", se for algo novo

## Adicionou ou tirou pacote
- [ ] `.chezmoidata/packages.yaml`
- [ ] README (en e pt-BR): lista de pacotes

## Mexeu no `straw` ou em módulos e perfis
- [ ] `.chezmoidata/straw.yaml` (pt e en na descrição, `icon` e `group`)
- [ ] Mudou colunas de `modules.tsv` ou `profiles.tsv`? Atualizar `scripts/ci-check.sh` e o bash
- [ ] Rodar `bash scripts/ci-check.sh` e `shellcheck -S warning dot_local/bin/executable_straw`
- [ ] README (en e pt-BR): tabela de comandos

## Mexeu em Go (`cmd/`, `internal/`)
- [ ] `gofmt -l .` vazio, `go vet ./...` e `go test ./...` passando
- [ ] Recompilar no celular: `go build -o ~/.local/bin/straw-ui ./cmd/straw-ui`
- [ ] Mensagem nova: chave `straw_*` nos dois idiomas

## Mudou o visual (logo, prompt, cores)
- [ ] Refazer os prints em `docs/bash.jpg` e `docs/zsh.jpg`

## Fechou uma fase ou lançou versão
- [ ] CHANGELOG com data e número
- [ ] Tag: `git tag -a vX.Y.Z -m "..."` e `git push origin vX.Y.Z`
- [ ] `gh release create vX.Y.Z --notes-file CHANGELOG.md` (o workflow Release anexa o `straw-ui` e o `SHA256SUMS`; confira em `gh release view vX.Y.Z`)
- [ ] CLAUDE.md: atualizar "Estado atual"
