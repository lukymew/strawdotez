# Solução de problemas

English: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Comece por `straw doctor`. Ele confere o ambiente e os pacotes e sai com erro se algo estiver errado.

## `straw: command not found` ou subcomando desconhecido
Os arquivos ainda não foram aplicados. Rode:

```
chezmoi init -S ~/strawdotez && chezmoi apply -S ~/strawdotez
```

Depois abra uma nova sessão (ou rode `reload`).

## `straw doctor` ou `straw tools` diz que falta o binário
Não foi possível baixar o `straw-ui` (sem internet, ou a release não tem binário para a sua arquitetura). O resto continua funcionando em bash. Para tentar de novo, rode o instalador outra vez, ou fixe uma versão:

```
bash install.sh --version vX.Y.Z
```

## Os emojis aparecem quebrados
Use uma fonte com suporte a emoji, ou desligue-os em um comando:

```
STRAW_PLAIN=1 straw
```

## `straw tools` fica estranho em terminal pequeno
Use a lista simples, sem a tela interativa:

```
STRAW_UI_SIMPLE=1 straw tools
```

## Um pacote aparece como faltando depois de instalado
Rode `pkg update` e depois `straw doctor` de novo. Um pacote só conta como instalado quando o dpkg diz `install ok installed`.

## `Permission denied` ao gravar em `/tmp`
O Termux não tem `/tmp` gravável. Use `$TMPDIR`.

## Meu `termux.properties` mudou
Antes de sobrescrever, o setup salva a sua versão em `~/.termux/termux.properties.bak`. Compare os dois e rode `termux-reload-settings`.

## O menu abre num tamanho ruim
O menu do `fzf` usa metade da tela, embaixo. Mude em `FZF_DEFAULT_OPTS` (arquivo `env_common`) se preferir outro tamanho.

## Ainda travado?
Abra uma issue com a saída de `straw doctor` e `straw version`. Nunca cole tokens, chaves ou e-mails. Veja o [SECURITY.md](../SECURITY.md).
