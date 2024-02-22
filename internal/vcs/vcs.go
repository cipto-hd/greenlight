package vcs

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"
)

func Version() string {
	cmd := exec.Command("git", "describe", "--always", "--dirty", "--tags", "--long")
	var out bytes.Buffer
	cmd.Stdout = &out

	err := cmd.Run()
	if err != nil {
		fmt.Println(err)
		return ""
	}

	return strings.TrimSpace(out.String())
}
