+++
title = "Golang Concurrency with HTTP Example"
description = "Benchmark server API with goroutine, channel, waitgroup"
date = "2017-03-06"
categories = ["tech", "go", "tutorial"]
tags = [
	"tech",
	"go",
	"tutorial"
]
+++

# Summary

I have a server running on remote. I want to simply benchmark on one API, and get the 
average response time of that API. So I simply wrote a few lines of a Golang programme.

# I want to benchmark

Call server API concurrently(about 1000 times at once) and see how long it takes.

# Why not use Apache ab?

Well, [Apache HTTP server Benchmarking tool](https://httpd.apache.org/docs/2.4/programs/ab.html) is powerful.
But It is a bit complex to learn and use, I want to do it by myself.

# Source codes

Github [zyfdegh/iotserver-apibench](https://github.com/zyfdegh/iotserver-apibench.git)

