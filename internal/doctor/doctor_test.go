package doctor

import (
	"bytes"
	"strings"
	"testing"

	"github.com/lukymew/strawdotez/internal/data"
)

type fake struct {
	tools   map[string]bool
	env     map[string]string
	missing map[string]bool
}

func (f fake) LookPath(n string) bool     { return f.tools[n] }
func (f fake) Getenv(k string) string     { return f.env[k] }
func (f fake) PkgExists(_, p string) bool { return !f.missing[p] }

func sample() *data.Data {
	return &data.Data{Lang: "en", Msg: map[string]string{
		"doctor_pkgs_bad":     "no such package: %s",
		"doctor_pkgs_ok":      "%d packages ok",
		"doctor_tool_missing": "missing %s",
		"doctor_summary":      "%d ok, %d warn, %d fail",
	}, Modules: []data.Module{
		{ID: "a", Packages: map[string][]string{"apt": {"jq", "nmap"}}},
		{ID: "b", Packages: map[string][]string{"apt": {"nmap", "xyz"}}},
	}}
}

func TestMissingToolAndPackages(t *testing.T) {
	f := fake{tools: map[string]bool{"git": true}, env: map[string]string{"HOME": "/h", "PATH": "/h/.local/bin"}, missing: map[string]bool{"xyz": true}}
	rs := Run(sample(), data.Env{Key: "apt", Name: "debian"}, f, true)
	var buf bytes.Buffer
	code := Print(&buf, sample(), rs, false)
	out := buf.String()
	if code != 1 {
		t.Errorf("exit = %d, esperava 1", code)
	}
	for _, want := range []string{"missing fzf", "no such package: xyz"} {
		if !strings.Contains(out, want) {
			t.Errorf("saída sem %q:\n%s", want, out)
		}
	}
	if strings.Contains(out, "nmap,") || strings.Count(out, "nmap") > 0 {
		t.Errorf("nmap existe e não deveria ser citado:\n%s", out)
	}
}

func TestAllGood(t *testing.T) {
	tools := map[string]bool{"fzf": true, "chezmoi": true, "git": true, "bash": true, "zsh": true}
	f := fake{tools: tools, env: map[string]string{"HOME": "/h", "PATH": "/x:/h/.local/bin"}}
	var buf bytes.Buffer
	if code := Print(&buf, sample(), Run(sample(), data.Env{Key: "apt", Name: "d"}, f, true), false); code != 0 {
		t.Errorf("exit = %d\n%s", code, buf.String())
	}
}

func TestInPath(t *testing.T) {
	if !inPath("/a:/b", "/b") || inPath("/a:/bb", "/b") {
		t.Error("inPath errado")
	}
}
