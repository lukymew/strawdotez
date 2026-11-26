package ui

import (
	"fmt"
	"strings"

	"github.com/lukymew/strawdotez/internal/data"
)

// Theme controla cores e emojis.
type Theme struct {
	Color bool
	Plain bool // sem emojis
}

func (t Theme) c(code, s string) string {
	if !t.Color {
		return s
	}
	return "\x1b[" + code + "m" + s + "\x1b[0m"
}

// label tira os emojis do texto quando o tema é plain.
func (t Theme) label(s string) string {
	if !t.Plain {
		return s
	}
	return StripEmoji(s)
}

// StripEmoji remove emojis e o espaço que vem depois deles.
func StripEmoji(s string) string {
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

// cells estima a largura de uma string no terminal (emoji conta 2).
func cells(s string) int {
	n := 0
	for _, r := range s {
		switch {
		case r == 0xFE0F || r == 0x200D:
		case r >= 0x1F000 || (r >= 0x2600 && r <= 0x27BF && r != 0x2714 && r != 0x2190 && r != 0x2191 && r != 0x2193):
			n += 2
		default:
			n++
		}
	}
	return n
}

// fit corta s para caber em w células e completa com espaços.
func fit(s string, w int) string {
	var b strings.Builder
	n := 0
	for _, r := range s {
		cw := cells(string(r))
		if n+cw > w {
			break
		}
		b.WriteRune(r)
		n += cw
	}
	if n < w {
		b.WriteString(strings.Repeat(" ", w-n))
	}
	return b.String()
}

// View monta a tela inteira como texto (linhas separadas por \n).
func View(m *Model, d *data.Data, th Theme) string {
	vis := m.Visible()
	w := m.W
	if w < 20 {
		w = 20
	}
	var lines []string

	title := th.label(d.M("ui_title"))
	count := fmt.Sprintf("%d/%d", len(vis), len(m.All))
	pad := w - cells(title) - cells(count) - 2
	if pad < 1 {
		pad = 1
	}
	lines = append(lines, th.c("1;36", " "+title)+strings.Repeat(" ", pad)+th.c("2", count))
	lines = append(lines, th.c("2", strings.Repeat("─", w)))
	lines = append(lines, " "+th.c("33", "🔎 ")+string(m.Query)+th.c("7", " "))

	rows := m.Rows()
	lastGroup := ""
	shown := 0
	for i := m.Offset; i < len(vis) && shown < rows; i++ {
		e := vis[i]
		if e.Group != lastGroup && (i == m.Offset || vis[i-1].Group != e.Group) {
			lastGroup = e.Group
			if shown >= rows-1 && i != m.Offset {
				break
			}
			lines = append(lines, th.c("1;35", " "+fit(th.label(d.M("group_"+e.Group)), w-2)))
			shown++
			if shown >= rows {
				break
			}
		}
		mark := "  "
		switch {
		case m.Installed[e.Pkg]:
			mark = th.c("32", "✔ ")
		case m.Marked[e.Pkg]:
			mark = th.c("1;33", "● ")
		}
		text := fit(fmt.Sprintf("%-14s %s", e.Pkg, e.Label()), w-5)
		line := " " + mark + text
		if i == m.Cursor {
			line = th.c("7", " "+stripMark(m, e.Pkg)+text+" ")
		}
		lines = append(lines, line)
		shown++
	}
	if len(vis) == 0 {
		lines = append(lines, " "+th.c("2", d.M("tools_none")))
	}
	for len(lines) < rows+3 {
		lines = append(lines, "")
	}
	lines = append(lines, th.c("2", strings.Repeat("─", w)))
	status := d.M("ui_hint")
	if n := len(m.Marked); n > 0 {
		status = th.c("1;33", d.M("ui_selected", n)) + "  " + th.c("2", d.M("ui_hint_short"))
	} else {
		status = th.c("2", status)
	}
	lines = append(lines, " "+status)
	return strings.Join(lines, "\n")
}

// stripMark devolve a marca sem cor, para a linha do cursor (já vem invertida).
func stripMark(m *Model, pkg string) string {
	switch {
	case m.Installed[pkg]:
		return "✔ "
	case m.Marked[pkg]:
		return "● "
	}
	return "  "
}
