# Reavaliação do código (2026-11-25, após a v1.2.0)

Revisão feita lendo o código e rodando o que dava. Não é auditoria completa: no fim há a lista do que **não** foi visto.

## Resumo

O projeto está em bom estado: a instalação é idempotente, a abertura do shell é rápida (bash ~15 ms, zsh ~30 ms), há CI, testes (Go e bats), verificação de segredos e política escrita. Os achados abaixo são de arestas, não de falhas de arquitetura. Os dois mais importantes são o `llm()` exportando um `LD_LIBRARY_PATH` com entrada vazia e o `LANG` fixo em inglês.

## O que foi lido e testado

- Lido: `functions_*` (utils, net, termux, ai), `env_common`, `shell_tools_termux`, `bashrc_termux`, `bash.bashrc_termux`, `aliases_termux` (parte), os três scripts de `.chezmoiscripts/`, `.chezmoi.toml.tmpl`, `install.sh`, `scripts/bench.sh`, `dot_local/bin/executable_straw` e todo o código Go.
- Rodado: `go vet`, `go test` (data, doctor, tools, ui), 13 testes bats, `shellcheck`, `ci-check.sh` (render de todos os templates em pt e en), o `straw-ui` num terminal virtual, o download do binário com checksum certo e errado, e `apt-cache` dos pacotes `apt` no Ubuntu 24.04.
- Confirmei por teste: o valor `"$HOME/llama-bin:$LD_LIBRARY_PATH"` com a variável vazia termina em `:` (achado 1). O resto é leitura.

## Achados

Gravidade: **alta** (corrigir já), **média** (corrigir na próxima versão), **baixa** (quando der).

| # | Gravidade | Onde | Problema | Sugestão |
|---|---|---|---|---|
| 1 | alta (corrigido) | `functions_ai_termux` (`llm`, `llm-server`) | `export LD_LIBRARY_PATH="$HOME/llama-bin:$LD_LIBRARY_PATH"` com a variável vazia gera um `:` no fim, que o carregador entende como "pasta atual": uma biblioteca plantada na pasta onde você está pode ser carregada. Além disso o `export` fica para sempre no shell. | Escopo só no comando: `LD_LIBRARY_PATH="$HOME/llama-bin${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ~/llama-bin/llama-cli "$@"`. |
| 2 | alta (corrigido) | `env_common` | `export LANG="en_US.UTF-8"` força inglês para quem escolheu `pt`, e o `install.sh` usa `LANG` para escolher o idioma, então reinstalar depois de aplicar pode mudar o idioma padrão. O Termux não tem locales instalados, então a variável pouco ajuda. | Remover, ou derivar de `.lang` (`pt_BR.UTF-8` ou `en_US.UTF-8`). |
| 3 | média | `aliases_termux`, `functions_termux` | Atalhos dependem de pacotes que não estão no núcleo: `battery`, `wifi`, `timer` (precisam do `termux-api`), `listen` e `tb` (`netcat-openbsd`), `ports` (`net-tools`), `cve` (`searchsploit`, que não existe no Termux). O aviso de "comando não encontrado" ajuda, mas o atalho parece quebrado. | Colocar `termux-api` e `netcat-openbsd` no núcleo ou envolver cada atalho em `command -v`; remover o `cve`; conferir `ip` e `netstat`. |
| 4 | média | `.chezmoiscripts/run_onchange_after_apply-termux-settings` | Toda vez que o perfil, as cores ou a fonte mudam, o script copia o perfil por cima do `~/.termux/termux.properties`. Qualquer edição manual (por exemplo ligar o `allow-external-apps`) é perdida sem aviso. | Guardar uma cópia (`termux.properties.bak`) antes de sobrescrever, e avisar no README. |
| 5 | média | `ui` (Go) | Se o programa tiver um pânico, o terminal fica em modo raw e na tela alternativa (sem eco). Mudança de tamanho da tela só é notada na próxima tecla. | `defer` que restaura o terminal e o cursor; tratar `SIGWINCH`. |
| 6 | média | `install.sh` | O `chezmoi init` sempre pega o `main`: se o `main` quebrar, quem instala naquele momento é afetado. O binário `straw-ui` vem da última release, o resto vem do `main`, então as versões podem divergir. | Opção de fixar uma versão (tag) e documentar; ou instalar sempre a última tag. |
| 7 | média | `functions_net_termux`, `aliases_termux` | `@ip-locator` usa `curl ipinfo.io/...` e `whatismyip` usa `curl ifconfig.me`, ambos em HTTP puro por padrão; `tb` envia texto sem criptografia para um serviço público. | `https://` e `curl -fsS`; documentar o `tb` (já está no `SECURITY.md`). |
| 8 | baixa | `functions_utils_termux` (`clone`) | `git clone -q "$1"` aceita um argumento que começa com `-` como opção. | `git clone -q -- "$1" "$destination"`. |
| 9 | baixa | `straw`, `ui`, script de pacotes | `dpkg -s` pode contar como instalado um pacote removido que manteve a configuração (estado `config-files`). Não consegui reproduzir aqui (nenhum pacote nesse estado), então está **a verificar**. | Se confirmar: `dpkg-query -W -f='${Status}' pkg` e procurar `install ok installed`. |
| 10 | baixa | `.github/workflows/*` | Actions fixadas por tag (`@v4`, `@v5`, `@v2`), não por hash de commit. O binário publicado não tem assinatura nem atestado de origem. | Fixar por hash; considerar `actions/attest-build-provenance` na release. |
| 11 | baixa | `functions_utils_termux` (`rsfile`) | A substring de busca em `${FNAME/${sstr}/${rstr}}` é tratada como padrão (`*`, `?`); nomes com esses caracteres se comportam de forma surpreendente. | Citar a variável: `${FNAME/"$sstr"/$rstr}`. |
| 12 | baixa | vários | Coisas pessoais ou de nome estranho no repositório público: banner "Obscure Society", pasta `WaRzOnE` num comentário do `termux.properties`, `reloa` (provável erro de digitação), função `google` que apenas faz `ping`, funções genéricas `ask`, `clone`, `tiny`. | Tornar o banner configurável; renomear ou documentar. |
| 13 | baixa | `functions_ai_termux` e módulo `ai` | As funções esperam binários em `~/llama-bin`, mas o módulo `ai` do `straw` instala o pacote `llama-cpp` do Termux. Os dois caminhos coexistem sem explicação. | Escolher um e documentar. |
| 14 | baixa | `.githooks/pre-commit` | O hook só vale depois de `git config core.hooksPath .githooks`, feito à mão em cada clone. | Documentar no `CONTRIBUTING.md` (planejado) ou ativar pelo `install.sh` no clone de desenvolvimento. |

## Pontos fortes (manter)

- Núcleo rápido e medido, com orçamento de tempo e cache nas ferramentas interativas.
- Instalação com fallback pacote a pacote e aviso do que falhou.
- Idiomas com fallback e verificador (`check-i18n.py`), então nada quebra por falta de texto.
- Bash como base e Go só onde compensa; o Go não tem dependências e é testável (sistema atrás de interface).
- Binário baixado com conferência de sha256 e saída limpa para bash puro se falhar.
- Segredos tratados em três camadas e política escrita.

## O que não foi revisado

- As peças do zsh (`zsh_*`), `scripts/ci-check.sh` e `check-i18n.py` por dentro, e o texto das mensagens `.chezmoidata/i18n.yaml`.
- `aliases_termux` foi lido só em parte (o restante apenas por busca de padrões perigosos).
- Nada foi executado em um Termux real nem em contêiner (o sandbox não tem Docker); Alpine ficou sem verificação de nomes de pacotes.
- Desempenho dos novos trechos em Go no celular além do que você já mediu.

## Correções já feitas

- Achado 1: `llm` e `llm-server` passam o `LD_LIBRARY_PATH` só para o comando, sem entrada vazia e sem `export` no shell (testado com a variável vazia e com valor).
- Achado 2: o `LANG` agora segue o idioma escolhido (`pt_BR.UTF-8` para pt, `en_US.UTF-8` para en). Conferi o render em pt e en.

## Ordem de correção sugerida

1. Achados 1 e 2 (rápidos, ganho imediato).
2. Achados 3, 4 e 7 (comportamento que o usuário percebe).
3. Achados 5 e 6 (robustez), junto da próxima release.
4. O resto, em lote, na v1.3.0.
