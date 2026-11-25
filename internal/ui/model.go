package ui

import (
	"github.com/lukymew/strawdotez/internal/tools"
)

// Action é o que o laço principal deve fazer depois de uma tecla.
type Action int

const (
	ActNone Action = iota
	ActQuit
	ActInstall
)

// Model é o estado da tela (sem nada de terminal, para ser testável).
type Model struct {
	All       []tools.Entry
	Installed map[string]bool
	Query     []rune
	Cursor    int
	Offset    int
	Marked    map[string]bool
	W, H      int
}

// New cria o modelo.
func New(all []tools.Entry, installed map[string]bool, w, h int) *Model {
	return &Model{All: all, Installed: installed, Marked: map[string]bool{}, W: w, H: h}
}

// Visible devolve as entradas que passam na busca.
func (m *Model) Visible() []tools.Entry { return tools.Filter(m.All, string(m.Query)) }

// Rows é quantas linhas da lista cabem na tela (cabeçalho, busca e rodapé ocupam 5).
func (m *Model) Rows() int {
	r := m.H - 5
	if r < 3 {
		r = 3
	}
	return r
}

// Update aplica uma tecla.
func (m *Model) Update(k Key) Action {
	vis := m.Visible()
	switch k.Kind {
	case KCtrlC:
		return ActQuit
	case KEsc:
		if len(m.Query) > 0 {
			m.Query = nil
			m.Cursor, m.Offset = 0, 0
			return ActNone
		}
		return ActQuit
	case KUp:
		m.Cursor--
	case KDown:
		m.Cursor++
	case KPgUp:
		m.Cursor -= m.Rows()
	case KPgDn:
		m.Cursor += m.Rows()
	case KHome:
		m.Cursor = 0
	case KEnd:
		m.Cursor = len(vis) - 1
	case KSpace, KTab:
		if m.Cursor >= 0 && m.Cursor < len(vis) {
			p := vis[m.Cursor].Pkg
			if !m.Installed[p] {
				m.Marked[p] = !m.Marked[p]
				if !m.Marked[p] {
					delete(m.Marked, p)
				}
			}
			m.Cursor++
		}
	case KEnter:
		if len(m.Marked) == 0 && m.Cursor >= 0 && m.Cursor < len(vis) && !m.Installed[vis[m.Cursor].Pkg] {
			m.Marked[vis[m.Cursor].Pkg] = true
		}
		if len(m.Marked) > 0 {
			return ActInstall
		}
	case KBackspace:
		if len(m.Query) > 0 {
			m.Query = m.Query[:len(m.Query)-1]
			m.Cursor, m.Offset = 0, 0
		}
	case KCtrlU:
		m.Query, m.Cursor, m.Offset = nil, 0, 0
	case KRune:
		m.Query = append(m.Query, k.R)
		m.Cursor, m.Offset = 0, 0
	}
	m.clamp(len(m.Visible()))
	return ActNone
}

func (m *Model) clamp(n int) {
	if m.Cursor >= n {
		m.Cursor = n - 1
	}
	if m.Cursor < 0 {
		m.Cursor = 0
	}
	rows := m.Rows()
	if m.Cursor < m.Offset {
		m.Offset = m.Cursor
	}
	if m.Cursor >= m.Offset+rows {
		m.Offset = m.Cursor - rows + 1
	}
	if m.Offset < 0 {
		m.Offset = 0
	}
}

// MarkedList devolve os pacotes marcados, na ordem da lista completa.
func (m *Model) MarkedList() []string {
	var out []string
	for _, e := range m.All {
		if m.Marked[e.Pkg] {
			out = append(out, e.Pkg)
		}
	}
	return out
}
