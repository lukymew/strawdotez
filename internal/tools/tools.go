// Package tools monta e filtra a lista de ferramentas do ambiente.
package tools

import (
	"fmt"
	"io"
	"sort"
	"strings"

	"github.com/lukymew/strawdotez/internal/data"
)

// Entry é um pacote com o módulo de onde veio.
type Entry struct {
	Pkg, Module, Icon, Group, Desc string
}

var groupOrder = []string{"cli", "dev", "net"}

// Build lista os pacotes do ambiente, sem repetir (vale o primeiro módulo).
func Build(d *data.Data, env string) []Entry {
	seen := map[string]bool{}
	var out []Entry
	for _, g := range groupOrder {
		for _, m := range d.Modules {
			if m.Group != g {
				continue
			}
			for _, p := range m.Pkgs(env) {
				if seen[p] {
					continue
				}
				seen[p] = true
				out = append(out, Entry{p, m.ID, m.Icon, m.Group, m.Desc})
			}
		}
	}
	return out
}

// Filter mantém as entradas que contêm todas as palavras da busca
// (ignora maiúsculas) no pacote, módulo, grupo ou descrição.
func Filter(es []Entry, query string) []Entry {
	words := strings.Fields(strings.ToLower(query))
	if len(words) == 0 {
		return es
	}
	var out []Entry
	for _, e := range es {
		hay := strings.ToLower(e.Pkg + " " + e.Module + " " + e.Group + " " + e.Desc)
		ok := true
		for _, w := range words {
			if !strings.Contains(hay, w) {
				ok = false
				break
			}
		}
		if ok {
			out = append(out, e)
		}
	}
	return out
}

// Render escreve a lista agrupada. installed pode ser nil.
func Render(w io.Writer, d *data.Data, es []Entry, plain bool, installed func(string) bool) {
	byGroup := map[string][]Entry{}
	for _, e := range es {
		byGroup[e.Group] = append(byGroup[e.Group], e)
	}
	groups := make([]string, 0, len(byGroup))
	for g := range byGroup {
		groups = append(groups, g)
	}
	sort.Slice(groups, func(i, j int) bool { return rank(groups[i]) < rank(groups[j]) })
	for _, g := range groups {
		head := d.M("group_" + g)
		if plain {
			head = stripEmoji(head)
		}
		fmt.Fprintf(w, "\n%s\n", head)
		for _, e := range byGroup[g] {
			mark := "  "
			if installed != nil && installed(e.Pkg) {
				mark = "✔ "
			}
			fmt.Fprintf(w, "  %s%-16s %s\n", mark, e.Pkg, e.Module)
		}
	}
	if len(es) == 0 {
		fmt.Fprintln(w, d.M("tools_none"))
	}
}

func rank(g string) int {
	for i, x := range groupOrder {
		if x == g {
			return i
		}
	}
	return len(groupOrder)
}

func stripEmoji(s string) string {
	var b strings.Builder
	skip := false
	for _, r := range s {
		if r >= 0x1F000 || r == 0xFE0F {
			skip = true
			continue
		}
		if skip && r == ' ' {
			skip = false
			continue
		}
		skip = false
		b.WriteRune(r)
	}
	return b.String()
}
