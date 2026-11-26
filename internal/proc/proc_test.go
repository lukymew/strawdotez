package proc

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestLookPathAcha(t *testing.T) {
	dir := t.TempDir()
	prog := filepath.Join(dir, "meuprog")
	os.WriteFile(prog, []byte("#!/bin/sh\necho oi\n"), 0o755)
	os.WriteFile(filepath.Join(dir, "semexec"), []byte("x"), 0o644)
	os.Mkdir(filepath.Join(dir, "pasta"), 0o755)
	t.Setenv("PATH", dir)
	if p, err := LookPath("meuprog"); err != nil || p != prog {
		t.Errorf("meuprog: %q %v", p, err)
	}
	for _, n := range []string{"semexec", "pasta", "naoexiste"} {
		if _, err := LookPath(n); !errors.Is(err, exec.ErrNotFound) {
			t.Errorf("%s deveria dar ErrNotFound, veio %v", n, err)
		}
	}
	if _, err := LookPath(prog); err != nil {
		t.Errorf("caminho com barra: %v", err)
	}
}

func TestCommandRoda(t *testing.T) {
	dir := t.TempDir()
	os.WriteFile(filepath.Join(dir, "meuprog"), []byte("#!/bin/sh\necho oi \"$1\"\n"), 0o755)
	t.Setenv("PATH", dir)
	out, err := Command("meuprog", "mundo").Output()
	if err != nil || strings.TrimSpace(string(out)) != "oi mundo" {
		t.Errorf("saída %q erro %v", out, err)
	}
}

func TestCommandInexistenteDaErroSemPanico(t *testing.T) {
	t.Setenv("PATH", t.TempDir())
	if err := Command("naoexiste").Run(); err == nil {
		t.Error("esperava erro")
	}
}

// Garante que o projeto não volta a usar o os/exec direto (ele chama faccessat2).
func TestNinguemUsaExecLookPathDireto(t *testing.T) {
	proibidos := []string{"exec.LookPath(", "exec.Command("}
	raiz := filepath.Join("..", "..")
	filepath.Walk(raiz, func(p string, fi os.FileInfo, err error) error {
		if err != nil || fi.IsDir() || !strings.HasSuffix(p, ".go") || strings.HasSuffix(p, "_test.go") {
			return nil
		}
		if strings.Contains(filepath.ToSlash(p), "internal/proc/") {
			return nil
		}
		b, _ := os.ReadFile(p)
		for _, f := range proibidos {
			if strings.Contains(string(b), f) {
				t.Errorf("%s usa %s: use o pacote proc", p, f)
			}
		}
		return nil
	})
}
