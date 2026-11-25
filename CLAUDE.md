# strawdotez: instruções para o Claude Code

## Objetivo
Configuração completa do **Termux** (celular e tablet) gerenciada com chezmoi.
Quem clonar o repo instala tudo com um comando e personaliza na instalação.
O projeto é **só Termux**: não há suporte a PC/Linux, e não deve voltar a haver.

## Princípios
1. Instalação em um comando, rápida e idempotente (rodar de novo não quebra nada).
2. Abertura do shell rápida: meta de bash abaixo de 30ms e zsh abaixo de 50ms.
3. Personalizável por pergunta na instalação (nome, e-mail, perfil celular/tablet).
4. Zero segredos no repo. Nunca fixar nome ou e-mail em arquivo versionado.
5. Bash é o shell principal; o zsh é opcional, mas deve funcionar igual.

## Estrutura
- `.chezmoi.toml.tmpl`: perguntas da instalação; define `.name`, `.email`, `.device`.
- `.chezmoidata/packages.yaml`: lista de pacotes do Termux (fonte única).
- `.chezmoiexternal.toml`: baixa os plugins do zsh do GitHub.
- `.chezmoiscripts/`: instala pacotes (before), copia o bash.bashrc do Termux, aplica o perfil e recarrega as configurações (after).
- `.chezmoitemplates/`: peças reutilizáveis (ver abaixo).
- `dot_bashrc.tmpl` e `dot_zshrc.tmpl`: só montam as peças, em ordem.
- `private_dot_gitconfig` e `create_private_dot_gitconfig-local.tmpl`: git.
- `private_dot_termux/`: `termux.properties.cell` e `.tablet`, cores e fonte.
- `.chezmoidata/straw.yaml`: módulos (com `icon`, `group` cli/dev/net e pacotes por ambiente termux/apt/apk) e perfis (com `icon`) do comando `straw`.
- `dot_local/bin/executable_straw`: o comando `straw` em bash (menu fzf, install, doctor, tools). É a base e o plano B.
- `dot_local/share/strawdotez/`: dados gerados pelo chezmoi para o `straw`: `messages.sh`, `modules.tsv` (7 colunas), `profiles.tsv` (5 colunas) e `straw.json` (para o Go).
- `cmd/straw-ui/` e `internal/{data,doctor,tools,pm}/`: parte em Go que **completa** o bash (`straw doctor` e `straw tools`). Lê o `straw.json`. Não substitui o bash.

### Peças em `.chezmoitemplates/`
- Comuns a bash e zsh: `env_common`, `aliases_common`, `aliases_termux`, `functions_utils_termux`, `functions_net_termux`, `functions_termux`, `functions_ai_termux`, `shell_tools_termux` (fzf e zoxide). `shell_common_termux` só agrega as funções e aliases.
- Só bash: `bashrc_termux` e `bash.bashrc_termux` (logo e cabeçalho, copiado para `$PREFIX/etc/bash.bashrc`).
- Só zsh: `zsh_opts_termux`, `zsh_compat_termux`, `zsh_prompt_termux`, `zsh_plugins_termux`.

## Como o chezmoi funciona aqui
- O repo é a fonte; `chezmoi apply` junta as peças e escreve **um único** `~/.bashrc` e `~/.zshrc`.
- Prefixos: `dot_` vira `.`; `private_` gera permissão 600; `create_` só cria se o arquivo não existir; `run_onchange_` roda quando o conteúdo do script muda.
- Dados vêm de `.chezmoi.toml.tmpl` e `.chezmoidata/`. O chezmoi usa `missingkey=error`: remover uma chave exige atualizar todos os templates que a usam.
- Depois de mudar `.chezmoi.toml.tmpl`, rode `chezmoi init` para regenerar a configuração.

## Regras de edição
- Nada de condicional de plataforma (`isTermux`, Linux, PC). O repo recusa instalar fora do Termux.
  Planejado (ROADMAP, Fase 10): suporte a proot-distro (Debian, Ubuntu e Alpine). Quando começar, centralize a detecção em `.chezmoi.toml.tmpl` (variável `.target`) e não espalhe condicionais pelos templates. Até lá, não adicione condicionais.
- Pacotes só em `.chezmoidata/packages.yaml`, com o nome real do pacote do Termux (confira com `pkg search`).
- Código das peças comuns deve funcionar em **bash e zsh**: evite `read -p` e `read -n`, e prefira `[ ]` e `command -v`. O zsh recebe `unsetopt EQUALS` em `zsh_compat_termux` para aceitar `[ "$1" == "-h" ]`.
- Coisa específica de bash vai em `bashrc_termux`; de zsh, nas peças `zsh_*`.
- Não edite `$PREFIX/etc` direto: use o script em `.chezmoiscripts/`.
- Não adicione `$(...)` ou `eval` na abertura do shell sem medir. Para saídas de ferramentas, use cache (como em `shell_tools_termux`, com cache em `~/.cache`).
- Aliases e funções novos vão no arquivo do assunto, com comentário de uso.
- Mensagens de commit em português, curtas e no imperativo.

## Parte em Go
- Só o que compensa em Go (doctor, navegador com busca). O bash continua sendo a base; o menu principal é bash com fzf.
- Dados vêm do `straw.json`; mensagens do `.chezmoidata/i18n.yaml` (chaves `straw_*`, usadas sem o prefixo no Go).
- Sem dependências externas por enquanto (só a biblioteca padrão). Antes de adicionar uma, meça o tempo de build no celular.
- Código de sistema (`dpkg`, `apk`, `PATH`) fica atrás da interface `System` para os testes usarem um falso.
- Teste: `gofmt -l .`, `go vet ./...` e `go test ./...` (o CI roda os três). Compilar no celular: `go build -o ~/.local/bin/straw-ui ./cmd/straw-ui`.
- Colunas dos `.tsv` são conferidas em `scripts/ci-check.sh`: mudou a quantidade, ajuste lá e no bash.

## Como testar (sempre antes de commitar)
    chezmoi -S ~/strawdotez diff
    chezmoi -S ~/strawdotez apply -v
    bash -n ~/.bashrc && zsh -n ~/.zshrc
    zsh -i -c 'type timer; type z'

Medir a abertura (rode duas vezes e use a segunda):

    time (for i in 1 2 3 4 5 6 7 8 9 10; do bash -i -c exit >/dev/null 2>&1; done)
    time (for i in 1 2 3 4 5 6 7 8 9 10; do zsh -i -c exit >/dev/null 2>&1; done)

Teste de instalação limpa, em um HOME temporário:

    export TESTHOME=$(mktemp -d)
    HOME=$TESTHOME chezmoi init --apply lukymew/strawdotez

Se o repo estiver privado, acrescente `GH_CONFIG_DIR=$HOME/.config/gh GIT_CONFIG_GLOBAL=$HOME/.gitconfig` antes de `HOME=`.

## Armadilhas já conhecidas
- `/tmp` não é gravável no Termux: use `$HOME` ou `$TMPDIR`.
- `zsh-autosuggestions` e `zsh-syntax-highlighting` não existem no `pkg`: vêm do `.chezmoiexternal.toml`. O `p7zip` agora se chama `7zip`.
- `eval "$(fzf --bash)"` é lento (registra autocompletar de vários comandos): no bash use só o `key-bindings.bash`.
- O `create_` nunca sobrescreve: para regenerar o `~/.gitconfig-local`, apague-o e rode `chezmoi apply`.
- O `~/.gitconfig` é gerenciado: não use `git config --global` para a identidade. Ela vem do `.gitconfig-local`, gerado pelas perguntas.
- `compinit` é carregado no primeiro Tab (peça `zsh_opts_termux`): não mova para a abertura.
- Textos das perguntas em `.chezmoi.toml.tmpl` não podem ter vírgula nem `=`: o texto vira a chave das opções `--promptString`, `--promptBool` e `--promptChoice` (usadas em automação e CI).
- O `.chezmoiignore` precisa listar `README.md`, `LICENSE` e `CLAUDE.md`, senão o chezmoi tenta copiá-los para `~/`.

- Pacotes de rede no Termux: `mtr` e `tcpdump` estão no `root-repo` (precisam de `pkg install root-repo`); `hydra`, `sqlmap`, `john` e `nikto` não foram achados nos repositórios do Termux (main, root, x11 e tur) pelo caminho do pacote. `openssl-tool` é subpacote do `openssl`. Confirme sempre com `straw doctor`.

## Créditos e inspirações
Ver a seção "Inspirações" do README.

## Idiomas (pt e en)

- O idioma vem da chave `lang` (pergunta no `chezmoi init`). Mensagens de execução ficam em `.chezmoidata/i18n.yaml`, sempre nos dois idiomas, e entram nos templates com `{{ template "t" (list . "chave") }}`. Se faltar a chave no idioma escolhido, a peça `.chezmoitemplates/t` usa o inglês, depois o português, e por fim mostra o nome da chave (nada quebra). Rode `python scripts/check-i18n.py` para ver o que falta.
- As perguntas da instalação ficam dentro de `.chezmoi.toml.tmpl` (o init não enxerga `.chezmoidata`).
- Texto de pergunta não pode ter vírgula nem `=` (as flags `--promptString` usam o texto como chave).
- README.md é em inglês e README.pt-BR.md em português: ao mudar um, mude o outro.

## Estado atual (2026-11-25)

- v1.2.0 lançada (2026-11-25): `straw` com menu, módulos e perfis; parte em Go (`straw doctor`, `straw tools`); emojis no menu; release do binário `straw-ui` por CI (arm64 e amd64, com sha256) e `install.sh` baixando-o, com fallback em bash.
- Fase 2: faltam o teste em contêiner (Ubuntu e Alpine, prompt para o Gemini pronto) e os testes das funções (bats).
- Pacotes que não existem no Termux padrão (`hydra`, `sqlmap`, `mtr`) foram removidos da lista do Termux; falta confirmar nomes e o `tur-repo`.
- Repositório público, licença MIT. Bash abre em ~15 ms e zsh em ~30 ms no celular do dono.

## Como trabalhar neste projeto

- O dono usa só o celular (Termux). Trabalhe com comandos curtos, um passo por vez, e peça a saída de cada um.
- Arquivos grandes: envie como arquivo para baixar. Colar heredocs longos no Termux quebra.
- O repo de desenvolvimento fica em `~/strawdotez`: sempre `chezmoi -S ~/strawdotez ...`. A pasta `~/.local/share/chezmoi` é a cópia instalada pelo `install.sh`.
- Mudou uma chave em `.chezmoi.toml.tmpl` ou em `.chezmoidata/`? Rode `chezmoi init -S ~/strawdotez` (senão `missingkey=error`).
- Shebang dos scripts: `#!{{ env "PREFIX" }}/bin/bash` (o Termux não tem `/usr/bin/env`). `/tmp` não é gravável: use `$HOME` ou `$TMPDIR`.
- Zsh e bash dividem os mesmos templates: mexeu em um, confira o outro (`bash -n` e `zsh -n` na saída renderizada).
- Nunca versionar tokens, chaves ou e-mails reais. Teste mudanças renderizando os templates antes de pedir ao dono para aplicar.
- Ao concluir um item, marque no ROADMAP e registre no CHANGELOG.

- Antes de cada push, siga o `CHECKLIST.md`.
