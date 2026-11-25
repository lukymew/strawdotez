// straw-ui complementa o `straw` em bash: doctor e, no futuro, menus próprios.
package main

import (
	"fmt"
	"os"

	"github.com/lukymew/strawdotez/internal/data"
	"github.com/lukymew/strawdotez/internal/doctor"
)

// version é preenchida no build: -ldflags "-X main.version=v1.2.0".
var version = "dev"

func main() {
	os.Exit(run(os.Args[1:]))
}

func run(args []string) int {
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "uso: straw-ui doctor [--quick]")
		return 2
	}
	switch args[0] {
	case "version":
		fmt.Println(version)
		return 0
	case "doctor":
		d, err := data.Load(data.DefaultPath())
		if err != nil {
			fmt.Fprintln(os.Stderr, "straw-ui:", err)
			return 1
		}
		quick := len(args) > 1 && args[1] == "--quick"
		env := data.DetectEnv(os.Getenv, os.ReadFile)
		rs := doctor.Run(d, env, doctor.Real{}, !quick)
		color := os.Getenv("NO_COLOR") == "" && isTTY()
		return doctor.Print(os.Stdout, d, rs, color)
	}
	fmt.Fprintln(os.Stderr, "straw-ui: comando desconhecido:", args[0])
	return 2
}

func isTTY() bool {
	fi, err := os.Stdout.Stat()
	return err == nil && fi.Mode()&os.ModeCharDevice != 0
}
