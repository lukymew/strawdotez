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
	for {
		act, err := screen(fd, m, d, th)
		if err != nil {
			fmt.Fprintln(os.Stderr, "straw-ui:", err)
			return 1
		}
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
		w, rows = Size(fd)
		m = New(all, inst(), w, rows)
	}
}

// screen mostra a interface até o usuário sair ou pedir a instalação.
// O defer garante que o terminal volta ao normal mesmo se houver um pânico.
func screen(fd int, m *Model, d *data.Data, th Theme) (act Action, err error) {
	old, err := MakeRaw(fd)
	if err != nil {
		return ActQuit, err
	}
	fmt.Print("\x1b[?1049h\x1b[?25l") // tela alternativa e cursor escondido
	defer func() {
		fmt.Print("\x1b[?25h\x1b[?1049l")
		Restore(fd, old)
	}()

	buf := make([]byte, 64)
	draw := true
	for {
		if w, h := Size(fd); w != m.W || h != m.H {
			m.W, m.H = w, h
			m.clamp(len(m.Visible()))
			draw = true
		}
		if draw {
			fmt.Print("\x1b[H\x1b[2J" + strings.ReplaceAll(View(m, d, th), "\n", "\r\n"))
			draw = false
		}
		n, rerr := syscall.Read(fd, buf)
		if rerr == syscall.EINTR || (rerr == nil && n == 0) {
			continue // tempo limite sem tecla: volta a checar o tamanho
		}
		if rerr != nil {
			return ActQuit, nil
		}
		for _, k := range ParseKeys(buf[:n]) {
			if a := m.Update(k); a != ActNone {
				return a, nil
			}
		}
		draw = true
	}
}
