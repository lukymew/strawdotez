package tools

import (
	"bytes"
	"strings"
	"testing"

	"github.com/lukymew/strawdotez/internal/data"
)

func sample() *data.Data {
	return &data.Data{Msg: map[string]string{"group_cli": "🧰 CLI tools", "group_net": "Network", "tools_none": "nothing found"},
		Modules: []data.Module{
			{ID: "network", Icon: "📡", Group: "net", Desc: "Network tools", Packages: map[string][]string{"apt": {"nmap", "whois"}}},
			{ID: "utils", Icon: "🧰", Group: "cli", Desc: "Everyday utilities", Packages: map[string][]string{"apt": {"jq", "nmap"}}},
			{ID: "ai", Icon: "🤖", Group: "cli", Packages: map[string][]string{"termux": {"llama-cpp"}}},
		}}
}

func TestBuildDedupAndOrder(t *testing.T) {
	es := Build(sample(), "apt")
	var names []string
	for _, e := range es {
		names = append(names, e.Pkg+":"+e.Module)
	}
	got := strings.Join(names, " ")
	if got != "jq:utils nmap:utils whois:network" {
		t.Errorf("veio %q (cli antes de net, nmap só uma vez, no 1º módulo)", got)
	}
	if len(Build(sample(), "apk")) != 0 {
		t.Error("apk não tem pacotes")
	}
}

func TestFilter(t *testing.T) {
	es := Build(sample(), "apt")
	if n := len(Filter(es, "")); n != 3 {
		t.Errorf("busca vazia deve devolver tudo, veio %d", n)
	}
	if n := len(Filter(es, "NMAP")); n != 1 {
		t.Errorf("NMAP: %d", n)
	}
	if n := len(Filter(es, "util jq")); n != 1 {
		t.Errorf("duas palavras: %d", n)
	}
	if n := len(Filter(es, "zzz")); n != 0 {
		t.Errorf("zzz: %d", n)
	}
}

func TestRender(t *testing.T) {
	d := sample()
	es := Build(d, "apt")
	var b bytes.Buffer
	Render(&b, d, es, false, func(p string) bool { return p == "jq" })
	out := b.String()
	for _, w := range []string{"🧰 CLI tools", "Network", "✔ jq", "whois"} {
		if !strings.Contains(out, w) {
			t.Errorf("falta %q:\n%s", w, out)
		}
	}
	b.Reset()
	Render(&b, d, es, true, nil)
	if strings.Contains(b.String(), "🧰") || !strings.Contains(b.String(), "CLI tools") {
		t.Errorf("plain: texto sem emoji esperado:\n%s", b.String())
	}
	b.Reset()
	Render(&b, d, nil, true, nil)
	if !strings.Contains(b.String(), "nothing found") {
		t.Error("sem resultados deve avisar")
	}
}

func TestDescricaoPorPacote(t *testing.T) {
	d := sample()
	d.Tools = map[string]string{"jq": "filtra JSON"}
	es := Build(d, "apt")
	var jq, whois Entry
	for _, e := range es {
		switch e.Pkg {
		case "jq":
			jq = e
		case "whois":
			whois = e
		}
	}
	if jq.Label() != "filtra JSON" {
		t.Errorf("jq deve mostrar a própria descrição, veio %q", jq.Label())
	}
	if whois.Label() != "network" {
		t.Errorf("sem descrição, mostra o módulo; veio %q", whois.Label())
	}
	if n := len(Filter(es, "filtra")); n != 1 {
		t.Errorf("a busca deve achar pela descrição do pacote: %d", n)
	}
	var b bytes.Buffer
	Render(&b, d, es, true, nil)
	if !strings.Contains(b.String(), "jq") || !strings.Contains(b.String(), "filtra JSON") {
		t.Errorf("Render sem a descrição:\n%s", b.String())
	}
}
