package data

import (
	"errors"
	"os"
	"path/filepath"
	"testing"
)

func TestLoadAndMessage(t *testing.T) {
	p := filepath.Join(t.TempDir(), "straw.json")
	os.WriteFile(p, []byte(`{"lang":"pt","msg":{"hi":"oi %s"},"modules":[{"id":"dev","packages":{"termux":["clang"]}}]}`), 0o600)
	d, err := Load(p)
	if err != nil {
		t.Fatal(err)
	}
	if got := d.M("hi", "ana"); got != "oi ana" {
		t.Errorf("M = %q", got)
	}
	if got := d.M("falta"); got != "falta" {
		t.Errorf("chave ausente deve voltar a própria chave, veio %q", got)
	}
	if got := d.Modules[0].Pkgs("termux"); len(got) != 1 || got[0] != "clang" {
		t.Errorf("Pkgs = %v", got)
	}
	if got := d.Modules[0].Pkgs("apt"); len(got) != 0 {
		t.Errorf("apt deveria vir vazio, veio %v", got)
	}
}

func TestLoadErrors(t *testing.T) {
	if _, err := Load(filepath.Join(t.TempDir(), "nao-existe.json")); err == nil {
		t.Error("esperava erro de arquivo ausente")
	}
	p := filepath.Join(t.TempDir(), "x.json")
	os.WriteFile(p, []byte("{quebrado"), 0o600)
	if _, err := Load(p); err == nil {
		t.Error("esperava erro de JSON inválido")
	}
}

func TestDetectEnv(t *testing.T) {
	none := func(string) ([]byte, error) { return nil, errors.New("sem arquivo") }
	osr := func(s string) func(string) ([]byte, error) {
		return func(string) ([]byte, error) { return []byte(s), nil }
	}
	env := func(m map[string]string) func(string) string { return func(k string) string { return m[k] } }
	cases := []struct {
		name string
		get  func(string) string
		rf   func(string) ([]byte, error)
		want string
	}{
		{"override", env(map[string]string{"STRAW_ENV": "apk"}), none, "apk"},
		{"termux", env(map[string]string{"PREFIX": "/data/data/com.termux/files/usr"}), none, "termux"},
		{"debian", env(nil), osr("ID=debian\n"), "apt"},
		{"ubuntu-like", env(nil), osr("ID=pop\nID_LIKE=\"ubuntu debian\"\n"), "apt"},
		{"alpine", env(nil), osr("ID=alpine\n"), "apk"},
		{"desconhecido", env(nil), osr("ID=arch\n"), ""},
		{"sem os-release", env(nil), none, ""},
	}
	for _, c := range cases {
		if got := DetectEnv(c.get, c.rf).Key; got != c.want {
			t.Errorf("%s: veio %q, esperava %q", c.name, got, c.want)
		}
	}
}
