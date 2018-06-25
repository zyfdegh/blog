+++
date = "2018-05-04"
title = "[译] 手把手教你 Go 程序的国际化和本土化"
+++

原文：[《A Step-by-Step Guide to Go Internationalization (i18n) & Localization (l10n)》][origin]

译者按：原文写得超详细，让我学习了 Go 中未曾使用到的但很有用的 i18n 知识，因而有了翻译文章的想法。
在征得原文作者同意的前提下，我开始了翻译工作。为了适应中文读者，我修改了原文中部分示例代码，还将
其中的希腊文，替换成了简体中文。

<center>
<img src="title-gopher.png" width=100% />
</center>

# 概述

Go 是静态编译的编程语言，最近很受欢迎，因为它简单、性能好而且非常适合开发云端应用。它有强大的能够
处理国际化（i18n）和本地化（l10n）的库，比如处理字符编码、文本转换还有特定地区的文本，但这个包的
文档写得不够好。让我们来看看该怎么使用这个库，并且让我们的 Go 程序能适应不同区域。

上面说的包是 `golang.org/x/text`，如果用得好，在你想让应用全球化时能帮上大忙。此包带有一系列
抽象，让你翻译消息（message）、格式化、处理单复数，还有 Unicode 等更简单。

本文包含两部分，一是大致了解 `golang.org/x/text` 这个包，看它提供了什么用来格式化和本地化的工具。
由于 Go 擅长构建微服务（microservice）架构，为了不破坏这个传统，在第二部分我们将创建一个微服务
架构的服务端程序，这将让我们对 Go 的国际化和本地化有更深刻的理解。

为了写这篇教程，我将用最新的 Go 1.10，文章中的代码都已经托放于 [GitHub][tutorial-examples-repo]。

一起开始吧！

# 包概览
Go 中大多数消息（message）要么用 `fmt` 要么通过 template 包处理。

`golang.org/x/text` 包含多层子包，提供了很多的工具和函数，并且用 `fmt` 风格的 API 来格式化
字符串。来看看在实际中怎么使用。

## 消息和翻译集（Catalog）
消息（message）是某些想传达给用户的的内容。每条消息根据键（key）进行区分，这可以有很多形式。
比如可以这样创建一条消息：

```go
p := message.NewPrinter(language.BritishEnglish)
p.Printf("There are %v flowers in our garden.", 1500)
```

当调用 NewPrinter 函数时，你要提供**语言标签**（language tag）。想指定语言时，就使用这些
[语言标签][lang-tags]。有多种创建标签的方式，比如：

* 使用预定义的标签。如：

    ```go
    language.Greek, language.BrazilianPortuguese
    ```
    完整的预定义标签在[这里][lang-tags]。
* 从字符串解析。如：

    ```go
    language.Make("el"), language.Parse("en-UK")
    ```
* 通过组合 Tag、Base、Script、Region、Variant, []Variant, Extension, []Extension 或
error。比如：

    ```go
    ja, _ := language.ParseBase("ja")
    jp, _ := language.ParseRegion("JP")
    jpLngTag, _ := language.Compose(ja, jp)
    fmt.Println(jpLngTag) // 打印 ja-JP
    ```
    如果你给了一个无效的字符串，会得到一个 Und，意思是未定义的语言标签。
    
    ```go
    fmt.Println(language.Compose(language.ParseRegion("AL"))) 
    // 打印 Und-AL
    ```
    
想了解更多有关语言的接口，看[这个文档][pkg-index]。

回到刚刚的消息，我们可以使用不同语言来指定一个新的 printer，并打出格式化后的字符串。这个库将
替你处理任何在做本地化时需要考量的差异：

```go
package main
 
import (
 "golang.org/x/text/message"
 "golang.org/x/text/language"
)
 
func main()  {
 p := message.NewPrinter(language.BritishEnglish)
 p.Printf("There are %v flowers in our garden.\n", 1500)
 
 p = message.NewPrinter(language.Greek)
 p.Printf("There are %v flowers in our garden.", 1500)
}
```

如果跑这段程序，将会得到

```sh
➜ go run main.go
There are 1,500 flowers in our garden.
There are 1.500 flowers in our garden.
```

（译者注：请留意两行输出中数字 1500 的差异。）

好了，为了打印翻译后的消息，我们需要将消息加到翻译集（catalog）中，这样 **Printer** 就能
根据语言标签找到它们。

翻译集（Catalog）定义了翻译后字符串的集合。可以这样理解，翻译集是一组各个语言的词典，每个词典
包含一些键，并含有相应语言的译文。要使用翻译集，我们需要先用译文来生成它们。

实际操作时，译文会由翻译器的数据源自动提供。来看看我们如何手动实现：

```go
package main

import (
	"fmt"

	"golang.org/x/text/language"
	"golang.org/x/text/message"
)

func init() {
	message.SetString(language.Chinese, "%s went to %s.", "%s去了%s。")
	message.SetString(language.AmericanEnglish, "%s went to %s.", "%s is in %s.")
	message.SetString(language.Chinese, "%s has been stolen.", "%s被偷走了。")
	message.SetString(language.AmericanEnglish, "%s has been stolen.", "%s has been stolen.")
	message.SetString(language.Chinese, "How are you?", "你好吗?.")
}

func main() {
	p := message.NewPrinter(language.Chinese)
	p.Printf("%s went to %s.", "彼得", "英格兰")
	fmt.Println()
	p.Printf("%s has been stolen.", "宝石")
	fmt.Println()

	p = message.NewPrinter(language.AmericanEnglish)
	p.Printf("%s went to %s.", "Peter", "England")
	fmt.Println()
	p.Printf("%s has been stolen.", "The Gem")
}

```

如果运行这段程序，会得到以下输出：

```sh
➜ go run main.go
彼得去了英格兰。
宝石被偷走了。
Peter is in England.
The Gem has been stolen.
```

（译者注：已将原来这段程序中的希腊文替换成了中文。）

注意：你在使用 `SetString` 方法（函数）时，所指定的键（key）是区分大小写的，
也区分换行。意思是你尝试用 `Println` 或者在行尾加上 `\n` 时，就不能用了：

```go
p = message.NewPrinter(language.Greek)

p.Printf("%s went to %s.\n", "彼得", "英格兰") 
// 打印：彼得 went to 英格兰.
p.Println("How are you?")                 
// 打印：How are you?
```

通常情况下， 你不需要手动创建翻译集，而是让这个库去处理。你也可以通过 [catalog.Builder][catalog-builder]
来让程序生成翻译集。

### 处理单复数
在一些情况下，你需要根据词语的单、复数而添加多个翻译后的字符串，并且要在翻译集里
加上专门的调用才能管理好单复数的情况。子包 `golang.org/x/text/feature/plural` 里有个
叫 [SelectF][selectf] 的函数用来处理文本里语法的复数形式。

下面我给个典型的 SelectF 使用案例：

```go
func init() {
	message.Set(language.English, "我有 %d 个苹果",
		plural.Selectf(1, "%d",
			"=1", "I have an apple",
			"=2", "I have two apples",
			"other", "I have %[1]d apples",
		))
	message.Set(language.English, "还剩余 %d 天",
		plural.Selectf(1, "%d",
			"one", "One day left",
			"other", "%[1]d days left",
		))

}

func main() {
	p := message.NewPrinter(language.English)
	p.Printf("我有 %d 个苹果", 1)
	fmt.Println()
	p.Printf("我有 %d 个苹果", 2)
	fmt.Println()
	p.Printf("我有 %d 个苹果", 5)
	fmt.Println()
	p.Printf("还剩余 %d 天", 1)
	fmt.Println()
	p.Printf("还剩余 %d 天", 10)
	fmt.Println()
}
```

运行这段程序，你将得到下面输出：

```
➜ go run main.go
I have an apple
I have two apples
I have 5 apples
One day left
10 days left
```

（译者注：由于中文词语 “苹果”、“天” 既表示单数又能表示复数，而对应的英文单词是分单、复数的，
用 “汉译英” 的方式更易向读者说明这段代码的功能。因而将[原文][origin]程序中的英文改成了中文，
希腊文换成了英文。下同。）

这里例子里，SelectF 能识别和支持几个量词，比如 `zero`、`one`、`two`、`few` 和 `many`，
此外还能匹配比较符如 `>x` 或 `<x`。

### 插补字符串到消息中
还有一些情况下，你想进一步处理消息中的量词，你可以用占位符变量（placeholder variables）来
处理一些特定的语法特性。比如说，在前面我们使用复数的例子，可以改写成这样：

```go
func init() {
    message.Set(language.English, "你迟了 %d 分钟。",
        catalog.Var("m", plural.Selectf(1, "%d",
            "one", "minute",
            "other", "minutes")),
        catalog.String("You are %[1]d ${m} late."))
}

func main() {
	p := message.NewPrinter(language.English)
	p.Printf("你迟了 %d 分钟。", 1)
        // 打印： You are 1 minute late.
	fmt.Println()
	p.Printf("你迟了 %d 分钟。", 10)
        // 打印： You are 10 minutes late.
	fmt.Println()
}
```

这里 `catalog.Var` 函数的第一个参数为字符串，即 `m`，是一个特殊的标签，根据 `%d` 参数的值，
这个标签会被一个更准确的翻译内容替换。

## 格式化货币
包 `golang.org/x/text/currency` 处理货币格式化。

有几个有用的函数可以打印出指定地区货币的金额。下面的例子显示了几种格式化的方式：

```go
package main

import (
	"fmt"

	"golang.org/x/text/currency"
	"golang.org/x/text/language"
	"golang.org/x/text/message"
)

func main() {
	p := message.NewPrinter(language.English)
	p.Printf("%d", currency.Symbol(currency.USD.Amount(0.1)))
	fmt.Println()
	p.Printf("%d", currency.NarrowSymbol(currency.JPY.Amount(1.6)))
	fmt.Println()
	p.Printf("%d", currency.ISO.Kind(currency.Cash)(currency.EUR.Amount(12.255)))
	fmt.Println()
}
```

结果会是：

```sh
➜ go run main.go
$ 0.10
¥ 2
EUR 12.26
```

## 加载消息
当你处理本地化工作时，通常你需要事先准备好译文以便应用程序能用上它们。你可以把这些译文文件
当作静态资源。有几种部署程序和译文文件的方式：

### 手动设置译文字符串
最简单的方式是把译文构建到你的应用程序里。你必须手动创建一个数组，包含原文和译文的条目，
在初始化时，那些消息会被加载到默认翻译集中。在你的应用里，你只能用 `NewPrinter` 函数切换区域。

下面这个应用，示范了如何在初始化时加载译文：

```go
package main

import (
	"golang.org/x/text/feature/plural"
	"golang.org/x/text/language"
	"golang.org/x/text/message"
	"golang.org/x/text/message/catalog"
)

type entry struct {
	tag, key string
	msg      interface{}
}

var entries = [...]entry{
	{"en", "Hello World", "Hello World"},
	{"zh", "Hello World", "你好世界"},
	{"en", "%d task(s) remaining!", plural.Selectf(1, "%d",
		"=1", "One task remaining!",
		"=2", "Two tasks remaining!",
		"other", "[1]d tasks remaining!",
	)},
	{"zh", "%d task(s) remaining!", plural.Selectf(1, "%d",
		"=1", "剩余一项任务！",
		"=2", "剩余两项任务！",
		"other", "剩余 [1]d 项任务！",
	)},
}

func init() {
	for _, e := range entries {
		tag := language.MustParse(e.tag)
		switch msg := e.msg.(type) {
		case string:
			message.SetString(tag, e.key, msg)
		case catalog.Message:
			message.Set(tag, e.key, msg)
		case []catalog.Message:
			message.Set(tag, e.key, msg...)
		}
	}
}

func main() {
	p := message.NewPrinter(language.Chinese)

	p.Printf("Hello World")
	p.Println()
	p.Printf("%d task(s) remaining!", 2)
	p.Println()

	p = message.NewPrinter(language.English)
	p.Printf("Hello World")
	p.Println()
	p.Printf("%d task(s) remaining!", 2)

}
```

```sh
➜ go run main.go
你好世界
剩余两项任务！
Hello World
Two tasks remaining!
```

实际上，这种办法易于实现，但不太方便拓展。只适用于有少量翻译的小程序。你还得手动去设置译文，
想要自动化很难。种种原因下，我们推荐使用自动加载消息的方式，接下来我详细说明。

### 自动加载消息
一直以来，大多数本地化的框架都会把每个语言的译文分别存于文件里，这些文件会被动态加载。你可以把
这些文件交给翻译的人，在他们搞定后，你再把译文合并到你的应用中。

为了协助这个过程，Go 作者们开发了一个命令行小工具叫 `gotext`，用来管理 Go 源码中的文本。

开始吧，先保证你有最新的工具：

```sh
$ go get -u golang.org/x/text/cmd/gotext
```

运行这个工具，会显示可用的命令。用 `help <command>` 来查看某个指令的帮助信息。

```
➜ gotext
gotext is a tool for managing text in Go source code.
 
Usage:
 
        gotext command [arguments]
 
The commands are:
 
        update      merge translations and generate catalog
        extract     extracts strings to be translated from code
        rewrite     rewrites fmt functions to use a message Printer
        generate    generates code to insert translated messages
```

这篇教程里，我们要用 **update** 指令。这个命令会做下面两步：

1. 从代码中提取出要翻译的键，并写入文件中；
2. 更新代码，使得程序加载那些键到翻译集中以便使用。

创建一个 *main.go* 文件，并调用一些 `Printf` 函数，然后再确保加了 `go:generate` 注释。

（译者注：这条注释是 build constraint，斜线 // 后不加空格。）

```sh
$ touch main.go
```

***文件***: *main.go*

```go
package main

//go:generate gotext -srclang=en update -out=catalog/catalog.go -lang=en,el

import (
	"golang.org/x/text/language"
	"golang.org/x/text/message"
)

func main() {
	p := message.NewPrinter(language.Greek)
	p.Printf("Hello world!")
	p.Println()

	p.Printf("Hello", "world!")
	p.Println()

	person := "Alex"
	place := "Utah"

	p.Printf("Hello ", person, " in ", place, "!")
	p.Println()

	// Greet everyone.
	p.Printf("Hello world!")
	p.Println()

	city := "Munich"
	p.Printf("Hello %s!", city)
	p.Println()

	// Person visiting a place.
	p.Printf("%s is visiting %s!",
		person,
		place)
	p.Println()

	// Double arguments.
	miles := 1.2345
	p.Printf("%.2[1]f miles traveled (%[1]f)", miles)
}
```

执行下面命令：

```sh
$ mkdir catalog
$ go generate
```

然后加一条 import 语句，来引入 ***catalog.go*** 文件：

***文件***: *main.go*

```go
package main

//go:generate gotext -srclang=en update -out=catalog/catalog.go -lang=en,el

import (
	"golang.org/x/text/language"
	"golang.org/x/text/message"
	_ "golang.org/x/text/message/catalog"
)
...
```

这时，你看看项目结构，会有这些文件被创建：

```sh
$ tree .
.
├── catalog
│   └── catalog.go
├── locales
│   ├── el
│   │   └── out.gotext.json
│   └── en
│       └── out.gotext.json
├── main.go
```

`locales` 目录含有翻译消息，格式是这个库支持的。这就是你要提供翻译的地方。创建一个文件，名叫
`messages.gotext.json` 然后在里面写入希腊文翻译。

***文件***: *locales/el/messages.gotext.json*

```json
{
  "language": "el",
  "messages": [
    {
      "id": "Hello world!",
      "message": "Hello world!",
      "translation": "Γιά σου Κόσμε!"
    },
    {
      "id": "Hello",
      "message": "Hello",
      "translation": "Γιά σας %[1]v",
      "placeholders": [
        {
          "id": "World",
          "string": "%[1]v",
          "type": "string",
          "underlyingType": "string",
          "argNum": 1,
          "expr": "\"world!\""
        }
      ]
    },
    {
      "id": "Hello {City}!",
      "message": "Hello {City}!",
      "translation": "Γιά σου %[1]s",
      "placeholders": [
        {
          "id": "City",
          "string": "%[1]s",
          "type": "string",
          "underlyingType": "string",
          "argNum": 1,
          "expr": "city"
        }
      ]
    },
    {
      "id": "{Person} is visiting {Place}!",
      "message": "{Person} is visiting {Place}!",
      "translation": "Ο %[1]s επισκέπτεται την %[2]s",
      "placeholders": [
        {
          "id": "Person",
          "string": "%[1]s",
          "type": "string",
          "underlyingType": "string",
          "argNum": 1,
          "expr": "person"
        },
        {
          "id": "Place",
          "string": "%[2]s",
          "type": "string",
          "underlyingType": "string",
          "argNum": 2,
          "expr": "place"
        }
      ]
    },
    {
      "id": "{Miles} miles traveled ({Miles_1})",
      "message": "{Miles} miles traveled ({Miles_1})",
      "translation": "%.2[1]f μίλια ταξίδεψε %[1]f",
      "placeholders": [
        {
          "id": "Miles",
          "string": "%.2[1]f",
          "type": "float64",
          "underlyingType": "float64",
          "argNum": 1,
          "expr": "miles"
        },
        {
          "id": "Miles_1",
          "string": "%[1]f",
          "type": "float64",
          "underlyingType": "float64",
          "argNum": 1,
          "expr": "miles"
        }
      ]
    }
  ]
}
```

现在执行 `go generate` 命令，并运行程序，将会看到翻译：

```sh
$ go generate
$ go run main.go
Γιά σου Κόσμε!
Γιά σας world!
 
Γιά σου Κόσμε!
Γιά σου Munich
Ο Alex επισκέπτεται την Utah
1,23 μίλια ταξίδεψε 1,234500%
```

如果你感兴趣的话，**rewrite** 指令会搜索源码中调用 `fmt` 的地方，并把它们替换为 `p.Print` 
函数。举例来说，假如我们有这样一段程序：

***文件***：*main.go*
```go
func main() {
   p := message.NewPrinter(language.German)
   fmt.Println("Hello world")
   fmt.Printf("Hello world!")
   p.Printf("Hello world!\n")
}
```

如果你运行下面的命令：

```sh
$ gotext rewrite -out main.go
```

这个文件将会变为：

```go
func main() {
   p := message.NewPrinter(language.German)
   p.Printf("Hello world\n")
   p.Printf("Hello world!")
   p.Printf("Hello world!\n")
}
```

# 微服务样例
这是本文的第二部分，我们将使用学到的 `golang/x/text` 包构建一个简单的 HTTP 服务端。该服务
会提供一个接口（endpoint）用来接受用户的语言，作为参数。接着服务端会尝试把该参数与后台已经支持的
语言列表匹配，最后（如果匹配上的话）会提供一个最适合该区域的翻译好的响应。

首先，要确认你已安装好了所有依赖。

先建好应用的骨架：

```sh
$ go get -u github.com/golang/dep/cmd/dep
$ dep init
$ touch main.go
```

***文件***：*main.go*

```go
package main

import (
	"flag"
	"fmt"
	"html"
	"log"
	"net/http"
	"time"
)

const (
	httpPort = "8090"
)

func PrintMessage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, %s", html.EscapeString(r.Host))
}

func main() {
	var port string
	flag.StringVar(&port, "port", httpPort, "http port")
	flag.Parse()

	server := &http.Server{
		Addr:           ":" + port,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 16,
		Handler:        http.HandlerFunc(PrintMessage)}

	log.Fatal(server.ListenAndServe())
}
```

这个程序还没有处理翻译。我们可以把 `fmt.Fprintf` 替换为 `p.Fprintf` ：

```go
func PrintMessage(w http.ResponseWriter, r *http.Request) {
   p := message.NewPrinter(language.English)
   p.Fprintf(w,"Hello, %v", html.EscapeString(r.Host))
}
```

在源码中添加下列代码，然后调用 go generate 命令：

```go
//go:generate gotext -srclang=en update -out=catalog/catalog.go -lang=en,el
```

```sh
$ dep ensure -update
$ go generate        
el: Missing entry for "Hello, {Host}".
```

给丢失的条目添加翻译：

```sh
$ cp locales/el/out.gotext.json locales/el/messages.gotext.json
```

***文件***：*locales/el/messages.gotext.json*

```json
{
    "language": "el",
    "messages": [
        {
            "id": "Hello, {Host}",
            "message": "Hello, {Host}",
            "translation": "Γιά σου %[1]v",
            "placeholders": [
                {
                    "id": "Host",
                    "string": "%[1]v",
                    "type": "string",
                    "underlyingType": "string",
                    "argNum": 1,
                    "expr": "html.EscapeString(r.Host)"
                }
            ]
        }
    ]
}
```

再次运行 `go generate` 命令，然后在在 `main.go` 中引用 **catalog** 包：

```sh
$ go generate
```

***文件***：*main.go*

```go
package main

import (
	"html"
	"log"
	"net/http"
	"flag"
	"time"
	"golang.org/x/text/message"
	"golang.org/x/text/language"

	_ "go-internationalization/catalog"
)
...
```

现在为了能让程序决定切换到什么语言，我们需要添加一个 [Matcher][matcher] 对象，这个对象会
从我们支持的语言标签列表中，选择出一个最匹配的一个语言。

从 `gotext` 工具生成的 `message.DefaultCatalog` 来新建一个 **Matcher**：

***文件***：*main.go*

```go
var matcher = language.NewMatcher(message.DefaultCatalog.Languages())
```

添加一个函数，根据请求的参数，来匹配正确的语言。

```go
package main

import (
	"html"
	"log"
	"net/http"
	"flag"
        "context"
	"time"
	"golang.org/x/text/message"
	"golang.org/x/text/language"

	_ "go-internationalization/catalog"
	
)

//go:generate gotext -srclang=en update -out=catalog/catalog.go -lang=en,el

var matcher = language.NewMatcher(message.DefaultCatalog.Languages())

type contextKey int

const (
	httpPort  = "8090"
	messagePrinterKey contextKey = 1
)

func withMessagePrinter(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		lang, ok := r.URL.Query()["lang"]

		if !ok || len(lang) < 1 {
			lang = append(lang, language.English.String())
		}
		tag,_, _ := matcher.Match(language.MustParse(lang[0]))
		p := message.NewPrinter(tag)
		ctx := context.WithValue(context.Background(), messagePrinterKey, p)

		next.ServeHTTP(w, r.WithContext(ctx))
	}
}
...
```

我只在请求查询串（query string）中提供了一个参数。你可以混合 cookie 或者请求头中的
 Accept-Language 去匹配额外的语言标识。

现在你只需要把处理函数 `PrintMessage` 套上 `withMessagePrinter`，然后从 **context** 里
取出 printer 就好了。


***文件***：*main.go*

```go
...
func PrintMessage(w http.ResponseWriter, r *http.Request) {
	p := r.Context().Value(messagePrinterKey).(*message.Printer)
	p.Fprintf(w,"Hello, %v", html.EscapeString(r.Host))
}

func main() {
	var port string
	flag.StringVar(&port, "port", httpPort, "http port")
	flag.Parse()

	server := &http.Server{
		Addr:           ":" + port,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 16,
		Handler:        http.HandlerFunc(withMessagePrinter(PrintMessage))}

	log.Fatal(server.ListenAndServe())
}
```

启动服务，并发些请求来看看翻译是否成功：

```sh
$ go run main.go
```

<center>
<img src="request-1.png" width=80% />
</center>

<center>
<img src="request-2.png" width=80% />
</center>

从现在起，世界如你所愿... 😎

# 使用 PhraseApp
PhraseApp 支持多种语言个框架，包括 Go。它能让翻译数据的导入、导出变得简单，并且能搜索丢掉的
翻译，很方便。最重要的是，你可以和翻译者一同协作，因为用了[专业的本地化][profession-translate]，
你的网站体验会更好。想了解 PhraseApp 的话，参考 [入门指南][guide]。你有 [14 天免费试用期][trial]。
还等什么呢？

# 总结
这篇文章里，我们探索了 Go 如何用 `golang/x/text` 包管理本地化，我们实现了一个样例网页服务器，
展现了翻译过程，整合了各个知识点。由于官方文档缺少实际应用案例，我希望这篇文章解释清楚了如何向
你的 Go 应用中以一种简单方式添加 i18n 支持。本文也作为未来的参考。

但这绝不是一份终极指南，因为应用有不同的需求，领域要求也多种多样。请继续关注此主题的更多详细文章。

----------

[origin]: https://phraseapp.com/blog/posts/internationalization-i18n-go/
[tutorial-examples-repo]: https://github.com/PhraseApp-Blog/go-internationalization
[lang-tags]: https://godoc.org/golang.org/x/text/language#Tag
[pkg-index]: https://godoc.org/golang.org/x/text/language#pkg-index
[catalog-builder]: https://godoc.org/golang.org/x/text/message/catalog#Builder
[selectf]: https://godoc.org/golang.org/x/text/feature/plural#Selectf
[matcher]: https://godoc.org/golang.org/x/text/language#Matcher
[profession-translate]: https://phraseapp.com/blog/posts/translation-management-why-authentic-human-translation-is-still-essential-for-localizing-software/
[guide]: https://phraseapp.com/docs/guides/setup/getting-started/
[trial]: https://phraseapp.com/signup
