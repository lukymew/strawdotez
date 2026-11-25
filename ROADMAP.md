# Roadmap

Legenda: `[x]` feito, `[ ]` planejado. As fases estão em ordem de prioridade, e dentro de cada uma os itens também.

## Fase 0: base (concluída)
- [x] Repo só Termux, gerenciado com chezmoi
- [x] Instalação em um comando e idempotente
- [x] Perguntas na instalação: nome, e-mail (opcionais) e perfil celular/tablet
- [x] Opções na instalação: logo e cabeçalho, e mensagem de boas-vindas do Termux (`.hushlogin`)
- [x] Pacotes em um arquivo de dados (`.chezmoidata/packages.yaml`)
- [x] Plugins do zsh baixados do GitHub (`.chezmoiexternal.toml`)
- [x] Código comum a bash e zsh, dividido por assunto
- [x] Desempenho: bash ~15ms e zsh ~30ms de abertura
- [x] fzf e zoxide com cache; autocompletar do zsh carregado no primeiro Tab
- [x] README, `CLAUDE.md`, licença MIT e créditos

## Fase 1: lançamento
- [x] Descrição e tópicos no GitHub (`termux`, `dotfiles`, `chezmoi`, `bash`, `zsh`)
- [x] Teste de instalação limpa como estranho (repo público, sem login)
- [x] Prints no README (bash e zsh)
- [x] Português e inglês: idioma escolhido na instalação, mensagens em `.chezmoidata/i18n.yaml`, README nos dois idiomas
- [x] Primeira versão marcada (`v1.0.0`) e `CHANGELOG.md`
- [x] Script de instalação em uma linha (instala `chezmoi` e `git` e já roda o `init`)
- [x] Aviso de pacotes que falharam no final da instalação

## Fase 2: qualidade e automação
- [x] CI no GitHub: renderizar todos os templates em cada push
- [x] CI: `bash -n`, `zsh -n` e `shellcheck` nos scripts e nas peças
- [ ] CI: teste de instalação em um contêiner do Termux
- [x] Script de medição de abertura no repo (`scripts/bench.sh`) com orçamento de tempo
- [x] Verificação de segredos antes de cada commit (gitleaks ou semelhante)
- [x] Testes do comando `straw` com bats (`tests/straw.bats`)
- [ ] Testes para as funções utilitárias do shell mais usadas

## Fase 3: personalização
- [x] Comando `straw` com `straw menu`: ferramentas por módulo e perfis (mínimo, padrão e completo)
- [ ] Módulos opcionais por pergunta: IA local (llama.cpp), rede e segurança, criptografia
- [x] Perfis de instalação: mínimo, padrão e completo (`straw menu`)
- [ ] Escolha de tema de cores (temas do Gogh) e de fonte na instalação
- [ ] Mais perfis de tela, como celular com teclado físico
- [ ] Escolha do shell padrão (bash ou zsh) por pergunta
- [ ] Opção de prompt: o atual ou o Starship

## Fase 4: ambiente completo
- [ ] Configuração do tmux
- [ ] Configuração do neovim
- [ ] Configuração do lazygit e extras do git (aliases, ignore global)
- [ ] Ajuda para chaves SSH (gerar e cadastrar no GitHub)
- [ ] Integração com Termux:API (bateria, notificações, área de transferência)
- [ ] Scripts de inicialização com Termux:Boot e atalhos com Termux:Widget
- [ ] Configuração do Termux:Styling

## Fase 5: desempenho
- [ ] Carregar o syntax-highlighting depois do primeiro prompt (zsh-defer)
- [ ] Compilar o `.zshrc` (`zcompile`) se o ganho compensar
- [ ] Revisar o cabeçalho do bash: logo e cálculo de largura
- [ ] Meta fixa: bash abaixo de 30ms e zsh abaixo de 50ms, verificada no CI

## Fase 6: segurança e privacidade
- [ ] Política escrita de segredos (nunca no repo)
- [ ] Criptografia de arquivos sensíveis com `age`, se algum dia houver
- [ ] Revisar aliases perigosos (`rmrf`, `iptablesflush`) e documentar
- [ ] Revisar o `allow-external-apps` do `termux.properties` e documentar o risco
- [ ] Verificação de integridade do script de instalação em uma linha

## Fase 7: experiência de uso
- [ ] Comando `strawdotez` com subcomandos: `update`, `doctor`, `perfil`, `bench`
- [x] `straw doctor` em Go: ambiente, ferramentas, PATH e pacotes que não existem (faltam plugins, identidade do git e permissões)
- [x] `straw tools`: lista com busca, agrupada, em Go
- [x] Emojis no menu (`STRAW_PLAIN=1` desliga)
- [x] Release do binário `straw-ui` por CI (arm64 e x86_64) e `install.sh` baixando e conferindo o sha256 (sem rede, segue só com bash)
- [ ] Instalar pelo navegador em Go (escolher e instalar de dentro do `straw tools`)
- [ ] Seção "Ferramentas específicas" com descrição por ferramenta
- [ ] Desinstalação e volta ao estado anterior (backup automático dos arquivos substituídos)
- [ ] Mensagem final da instalação dizendo o que foi instalado e o que fazer depois
- [ ] Mensagens e documentação em português e inglês

## Fase 8: documentação e comunidade
- [ ] Seção "Solução de problemas" com os erros já encontrados (pacote inexistente, `/tmp` sem permissão, `Repository not found`)
- [ ] Guia "Como personalizar" com exemplos
- [ ] `CONTRIBUTING.md` e modelos de issue e de pull request
- [ ] README em inglês
- [ ] Wiki ou site com a lista de aliases e funções
- [ ] Agradecimentos e links atualizados para as fontes de cada trecho

## Fase 9: menu interativo e addons
Inspiração: Dev Core Termux (adicionar o link do repositório aqui e estudar como ele organiza os menus).
- [ ] Menu interativo no terminal (`strawdotez menu`), com fzf ou gum
- [ ] Catálogo de ferramentas por categoria (dev, rede, mídia, IA local, segurança), com instalação em um toque
- [ ] Mostrar o que já está instalado e permitir remover
- [ ] Addons: módulos do projeto que podem ser ligados e desligados depois da instalação
- [ ] Lista de ferramentas escolhidas guardada em um arquivo local, aplicada pelo `chezmoi apply`
- [ ] Descrição curta de cada ferramenta e dos aliases que ela traz
- [ ] Documentar como criar um addon novo

## Fase 10: suporte a proot-distro (Debian, Ubuntu e Alpine)
- [ ] Detectar o ambiente em `.chezmoi.toml.tmpl` e criar a variável `.target`
- [ ] Trocar a trava "só Termux" por uma checagem dos alvos suportados
- [ ] Pacotes por alvo no `packages.yaml` (pkg, apt e apk)
- [ ] Instalação dos pacotes com `apt-get` e `apk`, sem `sudo` (no proot o usuário já é root)
- [ ] Guardas nos trechos que dependem do Termux (`$PREFIX`, `termux-*`, `.termux/`)
- [ ] Alpine: instalar bash, zsh, git e curl primeiro e tratar as diferenças do BusyBox
- [ ] Linha de instalação por distro (o chezmoi usa o instalador oficial no Debian e no Ubuntu)
- [ ] Testes em `proot-distro` e no CI com contêineres Debian, Ubuntu e Alpine
- [ ] Documentar no README e na solução de problemas

## Fase 11: bash enxuto (shell principal em todos os alvos)
- [x] Abertura sem processos extras para fzf e zoxide
- [ ] Zero processos (`$(...)`) em toda a abertura do bash
- [ ] Carregar sob demanda as funções raras (IA local, rede), mantendo só stubs na abertura
- [ ] Opção de instalação para desligar o logo e o cabeçalho (modo silencioso)
- [ ] Um único arquivo de configuração em vez de `/etc/bash.bashrc` mais `~/.bashrc`
- [ ] Meta: abertura a no máximo 1,5 vez o piso do bash (hoje 18ms contra 9ms)
- [ ] Mesma configuração de bash no Debian, Ubuntu e Alpine (Fase 10)

## Ideias futuras
- [ ] Perfil com `proot-distro` para quem precisa de Linux completo
- [ ] Configuração pronta para usar o Claude Code no Termux
- [ ] Sincronização entre vários dispositivos
- [ ] Backup e restauração dos dados do Termux
- [ ] Notificações de fim de comando longo
