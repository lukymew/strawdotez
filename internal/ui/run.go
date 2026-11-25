package ui

import (
	"fmt"
	"os"
	"strings"
	"syscall"

	"github.com/lukymew/strawdotez/internal/data"
	"github.com/lukymew/strawdotez/internal/tools"
)

// Hooks isola o que toca o sistema.
type Hooks struct {
	Installed func(pkg string) bool
	Install   func(pkgs []string) error
}

// Run abre a interface. Devolve o código de saída.
func Run(d *data.Data, all []tools.Entry, th Theme, h Hooks) int {
	fd := int(os.Stdin.Fd())
	inst := func() map[string]bool {
		m := map[string]bool{}
		for _, e := range all {
			if h.Installed(e.Pkg) {
				m[e.Pkg] = true
			}
		}
		return m
	}
	w, rows := Size(fd)
	m := New(all, inst(), w, rows)
	buf := make([]byte, 64)
	for {
		old, err := MakeRaw(fd)
		if err != nil {
			fmt.Fprintln(os.Stderr, "straw-ui:", err)
			return 1
		}
		fmt.Print("\x1b[?1049h\x1b[?25l") // tela alternativa e cursor escondido
		act := ActNone
		for act == ActNone {
			m.W, m.H = Size(fd)
			m.clamp(len(m.Visible()))
			fmt.Print("\x1b[H\x1b[2J" + strings.ReplaceAll(View(m, d, th), "\n", "\r\n"))
			n, err := os.Stdin.Read(buf)
			if err != nil || n == 0 {
				act = ActQuit
				break
			}
			for _, k := range ParseKeys(buf[:n]) {
				if act = m.Update(k); act != ActNone {
					break
				}
			}
		}
		fmt.Print("\x1b[?25h\x1b[?1049l")
		Restore(fd, old)
		if act == ActQuit {
			return 0
		}
		pk := m.MarkedList()
		fmt.Println(d.M("installing", strings.Join(pk, " ")))
		if err := h.Install(pk); err != nil {
			fmt.Println(d.M("failed"), err)
		} else {
			fmt.Println(d.M("done"))
		}
		fmt.Print(d.M("continue") + " ")
		var b [1]byte
		syscall.Read(fd, b[:])
		fmt.Println()
		m = New(all, inst(), w, rows)
	}
}
