package main

import (
	"fmt"
	"os"

	"github.com/quackquackhonk/askier/imgconv"
)

func main() {
	args := os.Args

	// ensure we have all the arguments
	if len(args) < 2 {
		fmt.Println("usage: askier <file>")
		os.Exit(1)
	}

	path := args[1]

	// load the image
	ascii := imgconv.Load(path)

	// draw the ASCII to stdout
	fmt.Println(ascii)
}
