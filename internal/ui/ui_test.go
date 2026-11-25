package ui

import (
	"strings"
	"testing"

	"github.com/lukymew/strawdotez/internal/data"
	"github.com/lukymew/strawdotez/internal/tools"
)

func TestParseKeys(t *testing.T) {
	cases := []struct {
		in   string
		want []KeyKind
	}{
		{"\x1b", []KeyKind{KEsc}},
		{"\x1b[A", []KeyKind{KUp}},
		{"\x1b[B", []KeyKind{KDown}},
		{"\x1bOA", []KeyKind{KUp}},
		{"\x1b[5~", []KeyKind{KPgUp}},
		{"\x1b[6~", []KeyKind{KPgDn}},
		{"\x1b[C", nil}, // seta direita é ignorada
		{"\r", []KeyKind{KEnter}},
		{" ", []KeyKind{KSpace}},
		{"\x7f", []KeyKind{KBackspace}},
		{"\x03", []KeyKind{KCtrlC}},
		{"ab", []KeyKind{KRune, KRune}},
		{"é", []KeyKind{KRune}},
		{"\x1b[A\x1b[B", []KeyKind{KUp, KDown}},
	}
	for _, c := range cases {
		var got []KeyKind
		for _, k := range ParseKeys([]byte(c.in)) {
			got = append(got, k.Kind)
		}
		if len(got) != len(c.want) {
			t.Errorf("%q: veio %v, esperava %v", c.in, got, c.want)
			continue
		}
		for i := range got {
			if got[i] != c.want[i] {
				t.Errorf("%q: veio %v, esperava %v", c.in, got, c.want)
			}
		}
	}
}

func sample() *Model {
	all := []tools.Entry{
		{Pkg: "jq", Module: "utils", Icon: "🧰", Group: "cli"},
		{Pkg: "tree", Module: "utils", Icon: "🧰", Group: "cli"},
		{Pkg: "nmap", Module: "network", Icon: "📡", Group: "net"},
	}
	return New(all, map[string]bool{"tree": true}, 40, 12)
}

func typ(m *Model, s string) {
	for _, k := range ParseKeys([]byte(s)) {
		m.Update(k)
	}
}

func TestSearchFiltersAndResetsCursor(t *testing.T) {
	m := sample()
	typ(m, "\x1b[B")
	typ(m, "nm")
	if v := m.Visible(); len(v) != 1 || v[0].Pkg != "nmap" || m.Cursor != 0 {
		t.Errorf("visíveis %v cursor %d", v, m.Cursor)
	}
	typ(m, "\x7f\x7f")
	if len(m.Visible()) != 3 {
		t.Error("backspace deve restaurar a lista")
	}
}

func TestMarkAndInstall(t *testing.T) {
	m := sample()
	typ(m, " ") // marca jq e desce
	typ(m, " ") // tree já está instalada: não marca
	if !m.Marked["jq"] || m.Marked["tree"] {
		t.Errorf("marcados: %v", m.Marked)
	}
	if act := m.Update(Key{Kind: KEnter}); act != ActInstall {
		t.Errorf("enter com marcados deve instalar, veio %v", act)
	}
	if got := m.MarkedList(); len(got) != 1 || got[0] != "jq" {
		t.Errorf("lista: %v", got)
	}
}

func TestEnterWithoutMarkInstallsCurrent(t *testing.T) {
	m := sample()
	if act := m.Update(Key{Kind: KEnter}); act != ActInstall || !m.Marked["jq"] {
		t.Errorf("enter sem marcas deve instalar o item atual (%v %v)", act, m.Marked)
	}
	m = sample()
	typ(m, "\x1b[B") // cursor em tree, já instalada
	if act := m.Update(Key{Kind: KEnter}); act != ActNone {
		t.Error("não deve reinstalar pacote instalado")
	}
}

func TestEscClearsThenQuits(t *testing.T) {
	m := sample()
	typ(m, "jq")
	if m.Update(Key{Kind: KEsc}) != ActNone || len(m.Query) != 0 {
		t.Error("primeiro Esc limpa a busca")
	}
	if m.Update(Key{Kind: KEsc}) != ActQuit {
		t.Error("segundo Esc sai")
	}
}

func TestCursorStaysInRange(t *testing.T) {
	m := sample()
	for i := 0; i < 10; i++ {
		typ(m, "\x1b[B")
	}
	if m.Cursor != 2 {
		t.Errorf("cursor %d, esperava 2", m.Cursor)
	}
	for i := 0; i < 10; i++ {
		typ(m, "\x1b[A")
	}
	if m.Cursor != 0 {
		t.Errorf("cursor %d, esperava 0", m.Cursor)
	}
}

func TestScrollKeepsCursorVisible(t *testing.T) {
	var all []tools.Entry
	for i := 0; i < 30; i++ {
		all = append(all, tools.Entry{Pkg: string(rune('a'+i%26)) + string(rune('a'+i/26)), Group: "cli"})
	}
	m := New(all, nil, 40, 10)
	for i := 0; i < 20; i++ {
		typ(m, "\x1b[B")
	}
	if m.Cursor < m.Offset || m.Cursor >= m.Offset+m.Rows() {
		t.Errorf("cursor %d fora da janela [%d,%d)", m.Cursor, m.Offset, m.Offset+m.Rows())
	}
}

func dat() *data.Data {
	return &data.Data{Msg: map[string]string{"ui_title": "tools", "ui_hint": "hint", "ui_hint_short": "short",
		"ui_selected": "%d marked", "group_cli": "🧰 CLI", "group_net": "Net", "tools_none": "none"}}
}

func TestViewContent(t *testing.T) {
	m := sample()
	typ(m, " ")
	out := View(m, dat(), Theme{})
	for _, w := range []string{"tools", "3/3", "CLI", "Net", "● jq", "✔ tree", "🧰 CLI", "1 marked"} {
		if !strings.Contains(out, w) {
			t.Errorf("falta %q:\n%s", w, out)
		}
	}
	if strings.Contains(out, "\x1b[") {
		t.Error("sem cor não deve ter escapes")
	}
	if !strings.Contains(View(m, dat(), Theme{Color: true}), "\x1b[") {
		t.Error("com cor deve ter escapes")
	}
	plain := View(m, dat(), Theme{Plain: true})
	if strings.Contains(plain, "🧰") || !strings.Contains(plain, "CLI") {
		t.Errorf("plain deve ter o texto sem emoji:\n%s", plain)
	}
}

func TestViewWidthNeverExceeded(t *testing.T) {
	m := sample()
	m.W = 24
	m.All[0].Module = strings.Repeat("longo", 20)
	for _, ln := range strings.Split(View(m, dat(), Theme{}), "\n") {
		if cells(ln) > m.W {
			t.Errorf("linha larga demais (%d): %q", cells(ln), ln)
		}
	}
}

func TestViewEmpty(t *testing.T) {
	m := sample()
	typ(m, "zzzz")
	if !strings.Contains(View(m, dat(), Theme{}), "none") {
		t.Error("lista vazia deve avisar")
	}
}
