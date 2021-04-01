package main

import (
	"math/rand"
	"time"
)

func init() {
	rand.Seed(time.Now().UnixNano())
}

func lotto(p float64) bool {
	if rand.Float64() < p {
		return true
	}
	return false
}
