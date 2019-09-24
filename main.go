package main

import (
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/peterbourgon/ff"
)

func main() {
	// flag parsing
	fs := flag.NewFlagSet("metronome", flag.ExitOnError)
	var (
		bpm = fs.Int("bpm", 120, "if zero, will ask you to type using your keyboard")
		_   = fs.String("config", "", "config file (optional)")
	)
	if err := ff.Parse(fs, os.Args[1:]); err != nil {
		panic(err)
	}

	// loop
	duration := time.Minute / time.Duration(*bpm) / 2
	i := 0
	start := time.Now()
	for range time.Tick(duration) {
		bips := i / 2
		uptime := time.Since(start)
		switch i % 4 {
		case 0:
			fmt.Printf("\b\r\\   bpm=%d bips=%d uptime=%s", *bpm, bips, uptime)
		case 2:
			fmt.Printf("\b\r  / bpm=%d bips=%d uptime=%s", *bpm, bips, uptime)
		case 1, 3:
			fmt.Printf("\b\r |  bpm=%d bips=%d uptime=%s", *bpm, bips, uptime)
		}
		i++
	}
}
