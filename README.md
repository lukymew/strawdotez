# strawdotez

Configuração completa do **Termux** (celular e tablet), gerenciada com
[chezmoi](https://www.chezmoi.io/). Um comando instala pacotes, shell, tema,
fonte e atalhos.

## Instalação

```bash
pkg install -y chezmoi git
chezmoi init --apply lukymew/strawdotez
```

Na primeira vez ele pergunta seu nome e e-mail (para o git) e o perfil
(`cell` ou `tablet`). Depois instala os pacotes e aplica tudo.

## Uso no dia a dia

| Comando | O que faz |
|---|---|
| `chezmoi update` | baixa e aplica as novidades do repo |
| `chezmoi diff` | mostra o que vai mudar antes de aplicar |
| `termux-modo-tablet` / `termux-modo-celular` | troca o perfil da interface |
| `crb` | restaura o `bash.bashrc` se ele corromper |

## Estrutura

- `.chezmoidata/packages.yaml`: lista de pacotes (edite aqui para adicionar)
- `.chezmoiscripts/`: instalação de pacotes, bash.bashrc e reload das configs
- `.chezmoitemplates/`: peças reutilizadas (aliases, funções, opções do zsh)
- `private_dot_termux/`: `termux.properties` (celular e tablet), cores e fonte
