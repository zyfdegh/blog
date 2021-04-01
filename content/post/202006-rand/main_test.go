package main

import (
	"fmt"
	"testing"
)

func TestLotto(t *testing.T) {
	n := 1000000000
	nhit, nmiss := 0, 0
	for i := 0; i < n; i++ {
		hit := lotto(0.2)
		if hit {
			nhit++
		} else {
			nmiss++
		}
	}
	fmt.Println(nhit, nmiss)
	fmt.Printf("p: %v\n", float64(nhit)/float64(n))
}
