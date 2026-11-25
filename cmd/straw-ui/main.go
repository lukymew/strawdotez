// straw-ui complementa o `straw` em bash: doctor e, no futuro, menus próprios.
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/lukymew/strawdotez/internal/data"
	"github.com/lukymew/strawdotez/internal/doctor"
	"github.com/lukymew/strawdotez/internal/pm"
	"github.com/lukymew/strawdotez/internal/tools"
)

// version é preenchida no build: -ldflags "-X main.version=v1.2.0".
var version = "dev"

func main() {
	os.Exit(run(os.Args[1:]))
}

func run(args []string) int {
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "uso: straw-ui doctor [--quick] | tools [busca]")
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
	case "tools":
		return runTools(args[1:])
	}
	fmt.Fprintln(os.Stderr, "straw-ui: comando desconhecido:", args[0])
	return 2
}

func isTTY() bool {
	fi, err := os.Stdout.Stat()
	return err == nil && fi.Mode()&os.ModeCharDevice != 0
}

func runTools(args []string) int {
	d, err := data.Load(data.DefaultPath())
	if err != nil {
		fmt.Fprintln(os.Stderr, "straw-ui:", err)
		return 1
	}
	env := data.DetectEnv(os.Getenv, os.ReadFile)
	all := tools.Build(d, env.Key)
	plain := os.Getenv("STRAW_PLAIN") == "1"
	inst := func(p string) bool { return pm.Installed(env.Key, p) }
	show := func(q string) { tools.Render(os.Stdout, d, tools.Filter(all, q), plain, inst) }

	if len(args) > 0 {
		show(strings.Join(args, " "))
		return 0
	}
	show("")
	if !isTTY() {
		return 0
	}
	in := bufio.NewScanner(os.Stdin)
	for {
		fmt.Print("\n" + d.M("tools_prompt") + " ")
		if !in.Scan() {
			return 0
		}
		q := strings.TrimSpace(in.Text())
		if q == "q" {
			return 0
		}
		show(q)
	}
}
