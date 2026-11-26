//go:build linux

package ui

import (
	"syscall"
	"unsafe"
)

// MakeRaw coloca o terminal em modo raw e devolve o estado antigo.
func MakeRaw(fd int) (*syscall.Termios, error) {
	var old syscall.Termios
	if _, _, e := syscall.Syscall(syscall.SYS_IOCTL, uintptr(fd), syscall.TCGETS, uintptr(unsafe.Pointer(&old))); e != 0 {
		return nil, e
	}
	raw := old
	raw.Iflag &^= syscall.IGNBRK | syscall.BRKINT | syscall.PARMRK | syscall.ISTRIP | syscall.INLCR | syscall.IGNCR | syscall.ICRNL | syscall.IXON
	raw.Oflag &^= syscall.OPOST
	raw.Lflag &^= syscall.ECHO | syscall.ECHONL | syscall.ICANON | syscall.ISIG | syscall.IEXTEN
	raw.Cflag &^= syscall.CSIZE | syscall.PARENB
	raw.Cflag |= syscall.CS8
	// lê com tempo limite de 0,2 s: sem tecla, o laço pode notar mudança de tamanho
	raw.Cc[syscall.VMIN] = 0
	raw.Cc[syscall.VTIME] = 2
	if _, _, e := syscall.Syscall(syscall.SYS_IOCTL, uintptr(fd), syscall.TCSETS, uintptr(unsafe.Pointer(&raw))); e != 0 {
		return nil, e
	}
	return &old, nil
}

// Restore volta o terminal ao estado salvo.
func Restore(fd int, st *syscall.Termios) {
	syscall.Syscall(syscall.SYS_IOCTL, uintptr(fd), syscall.TCSETS, uintptr(unsafe.Pointer(st)))
}

// Size devolve colunas e linhas do terminal (80x24 se não souber).
func Size(fd int) (int, int) {
	var ws struct{ Row, Col, X, Y uint16 }
	if _, _, e := syscall.Syscall(syscall.SYS_IOCTL, uintptr(fd), syscall.TIOCGWINSZ, uintptr(unsafe.Pointer(&ws))); e != 0 || ws.Col == 0 {
		return 80, 24
	}
	return int(ws.Col), int(ws.Row)
}
