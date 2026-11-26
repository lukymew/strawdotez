// Package proc procura e roda programas sem usar a chamada de sistema faccessat2.
//
// O os/exec do Go checa se um arquivo é executável com faccessat2. Alguns Androids bloqueiam
// essa chamada com seccomp e, em vez de devolver "não suportada", matam o processo com
// SIGSYS ("bad system call"). Aqui a checagem é feita com os.Stat e os bits de permissão.
// Todo o projeto usa este pacote no lugar de exec.LookPath e exec.Command (há um teste
// que confere isso).
package proc

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func executavel(p string) bool {
	fi, err := os.Stat(p)
	return err == nil && !fi.IsDir() && fi.Mode()&0o111 != 0
}

// LookPath devolve o caminho do programa, procurando no PATH quando name não tem barra.
func LookPath(name string) (string, error) {
	if strings.Contains(name, "/") {
		if executavel(name) {
			return name, nil
		}
		return "", &exec.Error{Name: name, Err: exec.ErrNotFound}
	}
	for _, dir := range filepath.SplitList(os.Getenv("PATH")) {
		if dir == "" {
			dir = "."
		}
		p := filepath.Join(dir, name)
		if executavel(p) {
			return p, nil
		}
	}
	return "", &exec.Error{Name: name, Err: exec.ErrNotFound}
}

// Command é como exec.Command, mas resolve o programa com LookPath daqui.
// Se o programa não existir, o erro aparece em Run, Output ou Start.
func Command(name string, args ...string) *exec.Cmd {
	path, err := LookPath(name)
	if err != nil {
		c := &exec.Cmd{Path: name, Args: append([]string{name}, args...)}
		c.Err = err
		return c
	}
	c := exec.Command(path, args...)
	c.Args[0] = name
	return c
}
