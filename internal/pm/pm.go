// Package pm consulta o gerenciador de pacotes do ambiente.
package pm

import (
	"fmt"
	"os"
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

// Install instala os pacotes mostrando a saída do gerenciador. Fora do Termux
// usa sudo quando não é root.
func Install(env string, pkgs []string) error {
	var args []string
	switch env {
	case "termux":
		args = append([]string{"pkg", "install", "-y"}, pkgs...)
	case "apt":
		args = append([]string{"apt-get", "install", "-y"}, pkgs...)
	case "apk":
		args = append([]string{"apk", "add"}, pkgs...)
	default:
		return fmt.Errorf("ambiente não suportado")
	}
	if env != "termux" && os.Geteuid() != 0 {
		if _, err := exec.LookPath("sudo"); err == nil {
			args = append([]string{"sudo"}, args...)
		}
	}
	c := exec.Command(args[0], args[1:]...)
	c.Stdin, c.Stdout, c.Stderr = os.Stdin, os.Stdout, os.Stderr
	return c.Run()
}
