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
- Pacotes só em `.chezmoidata/packages.yaml`, com o nome real do pacote do Termux (confira com `pkg search`).
- Código das peças comuns deve funcionar em **bash e zsh**: evite `read -p` e `read -n`, e prefira `[ ]` e `command -v`. O zsh recebe `unsetopt EQUALS` em `zsh_compat_termux` para aceitar `[ "$1" == "-h" ]`.
- Coisa específica de bash vai em `bashrc_termux`; de zsh, nas peças `zsh_*`.
- Não edite `$PREFIX/etc` direto: use o script em `.chezmoiscripts/`.
- Não adicione `$(...)` ou `eval` na abertura do shell sem medir. Para saídas de ferramentas, use cache (como em `shell_tools_termux`, com cache em `~/.cache`).
- Aliases e funções novos vão no arquivo do assunto, com comentário de uso.
- Mensagens de commit em português, curtas e no imperativo.

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
- O `.chezmoiignore` precisa listar `README.md`, `LICENSE` e `CLAUDE.md`, senão o chezmoi tenta copiá-los para `~/`.

## Créditos e inspirações
Ver a seção "Inspirações" do README.
