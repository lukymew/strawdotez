# Security / Segurança

English first, português abaixo.

## English

### Secrets policy
- This repository is public. **Never commit** tokens, passwords, private keys, SSH keys, `.env` files, cookies, personal e-mail or real names. Git identity is asked at install time and stays only in `~/.gitconfig-local`, which is not versioned.
- Three layers protect this: `.gitignore` (common secret file names), the pre-commit hook (`git config core.hooksPath .githooks`, uses gitleaks when installed or a built-in pattern list) and the `secrets` job in CI (gitleaks).
- If a secret was committed: **revoke it first** (the token or key is compromised the moment it is pushed), then remove it from history. Deleting it in a new commit is not enough.
- Need a secret on your device? Keep it outside the repo (`~/.config`, `pass`, `age` or `gpg`) and read it from there.

### What the setup changes on your device
- `allow-external-apps = true` in `termux.properties` lets other apps run commands in Termux, but only apps you granted the `RUN_COMMAND` permission. It is needed for automation (Tasker and similar). If you do not use that, set it to `false` (or comment it out) and run `termux-reload-settings`.
- Dangerous aliases were removed (`rmrf`, `iptablesflush`). `rm`, `cp` and `mv` ask for confirmation (`-i`).
- Aliases worth knowing: `gita` runs `git add .` (stages everything; the pre-commit hook is your safety net), `shareterm` starts an SSH server, `listen` opens a port and `tb` sends text to a public paste service (termbin). Use them knowingly.
- `straw` and the installer only install packages from your configured package manager and download `straw-ui` from this repository's releases, checking its sha256.

### Checking the installer before running it (optional)
The one-line installer runs a script from the internet. To read and verify it first:

```sh
curl -fsSLO https://github.com/lukymew/strawdotez/releases/latest/download/install.sh
curl -fsSLO https://github.com/lukymew/strawdotez/releases/latest/download/SHA256SUMS
grep ' install.sh$' SHA256SUMS | sha256sum -c -
less install.sh
bash install.sh
```

The checksum is published next to the file, so it detects a corrupted download, not a compromised GitHub account. Reading the script is the real check; it is short.

### Reporting a vulnerability
Open a private report in the repository's **Security** tab ("Report a vulnerability"). Please do not open a public issue with details of a problem that exposes users.

## Português

### Política de segredos
- Este repositório é público. **Nunca versione** tokens, senhas, chaves privadas, chaves SSH, arquivos `.env`, cookies, e-mail pessoal ou nome real. A identidade do git é perguntada na instalação e fica só no `~/.gitconfig-local`, que não é versionado.
- Há três camadas de proteção: o `.gitignore` (nomes comuns de arquivos secretos), o hook de pre-commit (`git config core.hooksPath .githooks`, usa o gitleaks se estiver instalado ou uma lista própria de padrões) e o job `secrets` no CI (gitleaks).
- Se um segredo foi commitado: **revogue primeiro** (o token ou chave está comprometido assim que vai para o GitHub) e depois tire do histórico. Apagar em um commit novo não basta.
- Precisa de um segredo no aparelho? Guarde fora do repositório (`~/.config`, `pass`, `age` ou `gpg`) e leia de lá.

### O que a configuração muda no seu aparelho
- `allow-external-apps = true` no `termux.properties` deixa outros apps rodarem comandos no Termux, mas só os que você deu a permissão `RUN_COMMAND`. É necessário para automação (Tasker e parecidos). Se não usa isso, ponha `false` (ou comente) e rode `termux-reload-settings`.
- Aliases perigosos foram removidos (`rmrf`, `iptablesflush`). `rm`, `cp` e `mv` pedem confirmação (`-i`).
- Aliases que merecem atenção: `gita` faz `git add .` (põe tudo na área de preparo; o hook de pre-commit é a rede de proteção), `shareterm` inicia um servidor SSH, `listen` abre uma porta e `tb` envia texto a um serviço público (termbin). Use sabendo disso.
- O `straw` e o instalador só instalam pacotes pelo gerenciador configurado e baixam o `straw-ui` das releases deste repositório, conferindo o sha256.

### Conferir o instalador antes de rodar (opcional)
O instalador de uma linha roda um script da internet. Para ler e verificar antes:

```sh
curl -fsSLO https://github.com/lukymew/strawdotez/releases/latest/download/install.sh
curl -fsSLO https://github.com/lukymew/strawdotez/releases/latest/download/SHA256SUMS
grep ' install.sh$' SHA256SUMS | sha256sum -c -
less install.sh
bash install.sh
```

O checksum é publicado junto do arquivo, então detecta download corrompido, não uma conta do GitHub comprometida. Ler o script é a verificação de verdade; ele é curto.

### Relatar uma vulnerabilidade
Abra um relato privado na aba **Security** do repositório ("Report a vulnerability"). Não abra uma issue pública com detalhes de um problema que exponha usuários.
