# Troubleshooting

Português: [TROUBLESHOOTING.pt-BR.md](TROUBLESHOOTING.pt-BR.md)

Start with `straw doctor`. It checks the environment and the packages and exits with an error if something is wrong.

## `straw: command not found` or an unknown subcommand
The files were not applied yet. Run:

```
chezmoi init -S ~/strawdotez && chezmoi apply -S ~/strawdotez
```

Then open a new session (or run `reload`).

## `straw doctor` or `straw tools` says the binary is missing
`straw-ui` could not be downloaded (offline, or the release has no binary for your architecture). Everything else keeps working in bash. To try again, run the installer again, or pin a version:

```
bash install.sh --version vX.Y.Z
```

## Emojis look broken
Use a font with emoji support, or turn them off for one command:

```
STRAW_PLAIN=1 straw
```

## `straw tools` looks wrong on a small terminal
Use the plain list, without the interactive screen:

```
STRAW_UI_SIMPLE=1 straw tools
```

## A package is reported as missing after you installed it
Run `pkg update` and then `straw doctor` again. A package only counts as installed when dpkg says `install ok installed`.

## `Permission denied` when writing to `/tmp`
Termux has no writable `/tmp`. Use `$TMPDIR` instead.

## My `termux.properties` changed
Before overwriting it, the setup saves your version to `~/.termux/termux.properties.bak`. Compare the two, then run `termux-reload-settings`.

## The menu opens at the wrong size
The `fzf` menu uses half of the screen at the bottom. Change it in `FZF_DEFAULT_OPTS` (file `env_common`) if you prefer another size.

## Still stuck?
Open an issue with the output of `straw doctor` and `straw version`. Never paste tokens, keys or e-mails. See [SECURITY.md](../SECURITY.md).
