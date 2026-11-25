// Package pm consulta o gerenciador de pacotes do ambiente.
package pm

import (
	"os/exec"
	"strings"
)

// Installed diz se o pacote já está instalado (termux e apt usam dpkg, apk usa apk).
func Installed(env, pkg string) bool {
	switch env {
	case "termux", "apt":
		return exec.Command("dpkg", "-s", pkg).Run() == nil
	case "apk":
		out, err := exec.Command("apk", "info", "-e", pkg).Output()
		return err == nil && strings.TrimSpace(string(out)) != ""
	}
	return false
}
