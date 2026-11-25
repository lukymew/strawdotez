// Package doctor roda as verificações do `straw doctor`.
package doctor

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"sync"

	"github.com/lukymew/strawdotez/internal/data"
)

// Status de um resultado.
type Status int

const (
	OK Status = iota
	Warn
	Fail
)

// Result é uma linha do relatório.
type Result struct {
	Status Status
	Text   string
}

// System isola o que toca o sistema, para os testes usarem um falso.
type System interface {
	LookPath(name string) bool
	Getenv(key string) string
	// PkgExists diz se o gerenciador do ambiente conhece o pacote.
	PkgExists(env, pkg string) bool
}

// Real é o System de verdade.
type Real struct{}

func (Real) LookPath(n string) bool { _, err := exec.LookPath(n); return err == nil }
func (Real) Getenv(k string) string { return os.Getenv(k) }

func (Real) PkgExists(env, pkg string) bool {
	var cmd *exec.Cmd
	switch env {
	case "termux":
		cmd = exec.Command("pkg", "show", pkg)
	case "apt":
		cmd = exec.Command("apt-cache", "show", pkg)
	case "apk":
		cmd = exec.Command("apk", "info", "-e", pkg)
		out, err := cmd.Output()
		return err == nil && strings.TrimSpace(string(out)) != ""
	default:
		return true
	}
	return cmd.Run() == nil
}

// Run executa todas as checagens e devolve os resultados em ordem fixa.
func Run(d *data.Data, env data.Env, sys System, checkPkgs bool) []Result {
	var rs []Result
	add := func(s Status, key string, args ...any) {
		rs = append(rs, Result{s, d.M(key, args...)})
	}

	if env.Key == "" {
		add(Warn, "doctor_env_unknown", env.Name)
	} else {
		add(OK, "doctor_env", env.Name)
	}
	add(OK, "doctor_lang", d.Lang)

	for _, t := range []struct {
		name string
		need bool
	}{{"fzf", true}, {"chezmoi", true}, {"git", true}, {"bash", true}, {"zsh", false}} {
		switch {
		case sys.LookPath(t.name):
			add(OK, "doctor_tool_ok", t.name)
		case t.need:
			add(Fail, "doctor_tool_missing", t.name)
		default:
			add(Warn, "doctor_tool_optional", t.name)
		}
	}

	if inPath(sys.Getenv("PATH"), filepath.Join(sys.Getenv("HOME"), ".local", "bin")) {
		add(OK, "doctor_path_ok")
	} else {
		add(Warn, "doctor_path_bad")
	}

	if checkPkgs && env.Key != "" {
		rs = append(rs, checkPackages(d, env, sys)...)
	}
	return rs
}

func inPath(path, dir string) bool {
	for _, p := range strings.Split(path, ":") {
		if p == dir {
			return true
		}
	}
	return false
}

// checkPackages consulta em paralelo (até 8) se cada pacote existe.
func checkPackages(d *data.Data, env data.Env, sys System) []Result {
	seen := map[string]bool{}
	var pkgs []string
	for _, m := range d.Modules {
		for _, p := range m.Pkgs(env.Key) {
			if !seen[p] {
				seen[p] = true
				pkgs = append(pkgs, p)
			}
		}
	}
	sort.Strings(pkgs)
	missing := make([]bool, len(pkgs))
	var wg sync.WaitGroup
	sem := make(chan struct{}, 8)
	for i, p := range pkgs {
		wg.Add(1)
		go func(i int, p string) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			missing[i] = !sys.PkgExists(env.Key, p)
		}(i, p)
	}
	wg.Wait()
	var bad []string
	for i, p := range pkgs {
		if missing[i] {
			bad = append(bad, p)
		}
	}
	if len(bad) == 0 {
		return []Result{{OK, d.M("doctor_pkgs_ok", len(pkgs))}}
	}
	return []Result{{Fail, d.M("doctor_pkgs_bad", strings.Join(bad, ", "))}}
}

// Print escreve o relatório e devolve o código de saída (0 ok/avisos, 1 falhas).
func Print(w io.Writer, d *data.Data, rs []Result, color bool) int {
	mark := map[Status]string{OK: "✔", Warn: "!", Fail: "✘"}
	col := map[Status]string{OK: "32", Warn: "33", Fail: "31"}
	fails, warns := 0, 0
	for _, r := range rs {
		switch r.Status {
		case Fail:
			fails++
		case Warn:
			warns++
		}
		m := mark[r.Status]
		if color {
			m = "\x1b[" + col[r.Status] + "m" + m + "\x1b[0m"
		}
		fmt.Fprintf(w, " %s %s\n", m, r.Text)
	}
	fmt.Fprintln(w, d.M("doctor_summary", len(rs)-fails-warns, warns, fails))
	if fails > 0 {
		return 1
	}
	return 0
}
