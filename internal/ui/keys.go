// Package ui é a interface de terminal do straw, feita só com a biblioteca padrão.
package ui

import "unicode/utf8"

// KeyKind diz que tecla foi apertada.
type KeyKind int

const (
	KRune KeyKind = iota
	KUp
	KDown
	KPgUp
	KPgDn
	KHome
	KEnd
	KEnter
	KEsc
	KTab
	KBackspace
	KSpace
	KCtrlC
	KCtrlU
)

// Key é uma tecla; R só vale em KRune.
type Key struct {
	Kind KeyKind
	R    rune
}

// ParseKeys converte o que o terminal mandou em teclas. Um ESC sozinho é Esc.
func ParseKeys(b []byte) []Key {
	var out []Key
	for len(b) > 0 {
		c := b[0]
		switch {
		case c == 0x1b:
			if len(b) == 1 {
				out = append(out, Key{Kind: KEsc})
				b = b[1:]
				continue
			}
			if b[1] == '[' || b[1] == 'O' {
				k, n := csi(b[2:])
				if k.Kind != KRune || n > 0 {
					if k.Kind != KRune {
						out = append(out, k)
					}
					b = b[2+n:]
					continue
				}
			}
			out = append(out, Key{Kind: KEsc})
			b = b[1:]
		case c == '\r' || c == '\n':
			out = append(out, Key{Kind: KEnter})
			b = b[1:]
		case c == '\t':
			out = append(out, Key{Kind: KTab})
			b = b[1:]
		case c == 0x7f || c == 0x08:
			out = append(out, Key{Kind: KBackspace})
			b = b[1:]
		case c == 0x03:
			out = append(out, Key{Kind: KCtrlC})
			b = b[1:]
		case c == 0x15:
			out = append(out, Key{Kind: KCtrlU})
			b = b[1:]
		case c == ' ':
			out = append(out, Key{Kind: KSpace})
			b = b[1:]
		case c < 0x20:
			b = b[1:]
		default:
			r, n := utf8.DecodeRune(b)
			if r != utf8.RuneError {
				out = append(out, Key{Kind: KRune, R: r})
			}
			b = b[n:]
		}
	}
	return out
}

// csi lê o resto de uma sequência ESC [ ... ou ESC O ...; n é quantos bytes consumiu.
func csi(b []byte) (Key, int) {
	for i, c := range b {
		if c >= 0x40 && c <= 0x7e { // byte final
			switch c {
			case 'A':
				return Key{Kind: KUp}, i + 1
			case 'B':
				return Key{Kind: KDown}, i + 1
			case 'H':
				return Key{Kind: KHome}, i + 1
			case 'F':
				return Key{Kind: KEnd}, i + 1
			case '~':
				switch string(b[:i]) {
				case "5":
					return Key{Kind: KPgUp}, i + 1
				case "6":
					return Key{Kind: KPgDn}, i + 1
				case "1", "7":
					return Key{Kind: KHome}, i + 1
				case "4", "8":
					return Key{Kind: KEnd}, i + 1
				}
			}
			return Key{Kind: KRune}, i + 1 // sequência que ignoramos (setas laterais etc.)
		}
	}
	return Key{Kind: KRune}, 0
}
