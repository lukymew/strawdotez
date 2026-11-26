// Package data lê o straw.json gerado pelo chezmoi e detecta o ambiente.
package data

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Module é um grupo de pacotes do straw.yaml.
type Module struct {
	ID       string              `json:"id"`
	Icon     string              `json:"icon"`
	Group    string              `json:"group"`
	Desc     string              `json:"desc"`
	Packages map[string][]string `json:"packages"`
}

// Profile é um conjunto de módulos.
type Profile struct {
	ID      string   `json:"id"`
	Desc    string   `json:"desc"`
	Modules []string `json:"modules"`
	Only    []string `json:"only"`
}

// Data é o conteúdo do straw.json.
type Data struct {
	Lang     string            `json:"lang"`
	Msg      map[string]string `json:"msg"`
	Tools    map[string]string `json:"tools"`
	Modules  []Module          `json:"modules"`
	Profiles []Profile         `json:"profiles"`
}

// DefaultPath devolve o caminho do straw.json (STRAW_DIR muda a pasta).
func DefaultPath() string {
	dir := os.Getenv("STRAW_DIR")
	if dir == "" {
		home, _ := os.UserHomeDir()
		dir = filepath.Join(home, ".local", "share", "strawdotez")
	}
	return filepath.Join(dir, "straw.json")
}

// Load lê e valida o arquivo.
func Load(path string) (*Data, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var d Data
	if err := json.Unmarshal(b, &d); err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	if d.Msg == nil {
		d.Msg = map[string]string{}
	}
	return &d, nil
}

// M devolve a mensagem da chave (ou a própria chave se faltar), formatada com args.
func (d *Data) M(key string, args ...any) string {
	s, ok := d.Msg[key]
	if !ok {
		s = key
	}
	if len(args) > 0 {
		return fmt.Sprintf(s, args...)
	}
	return s
}

// Pkgs devolve os pacotes do módulo para o ambiente (termux, apt ou apk).
func (m Module) Pkgs(env string) []string {
	return m.Packages[env]
}

// Env descreve o ambiente detectado.
type Env struct {
	Key  string // termux, apt ou apk ("" se não suportado)
	Name string // nome para mostrar
}

// DetectEnv usa STRAW_ENV, o PREFIX do Termux e o /etc/os-release.
func DetectEnv(getenv func(string) string, readFile func(string) ([]byte, error)) Env {
	if k := getenv("STRAW_ENV"); k != "" {
		return Env{Key: k, Name: k}
	}
	if strings.HasPrefix(getenv("PREFIX"), "/data/data/com.termux") {
		return Env{Key: "termux", Name: "Termux"}
	}
	b, err := readFile("/etc/os-release")
	if err != nil {
		return Env{}
	}
	var id, like string
	for _, ln := range strings.Split(string(b), "\n") {
		switch {
		case strings.HasPrefix(ln, "ID="):
			id = strings.Trim(strings.TrimPrefix(ln, "ID="), `"`)
		case strings.HasPrefix(ln, "ID_LIKE="):
			like = strings.Trim(strings.TrimPrefix(ln, "ID_LIKE="), `"`)
		}
	}
	all := id + " " + like
	switch {
	case strings.Contains(all, "alpine"):
		return Env{Key: "apk", Name: orDefault(id, "alpine")}
	case strings.Contains(all, "debian"), strings.Contains(all, "ubuntu"), strings.Contains(all, "kali"):
		return Env{Key: "apt", Name: orDefault(id, "apt")}
	}
	return Env{Name: id}
}

func orDefault(s, d string) string {
	if s == "" {
		return d
	}
	return s
}
