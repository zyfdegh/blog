+++
title = "[译] 借助 go-i18n 更简单地实现全球化"
date = "2018-09-04"
description = "使用 Markdown 的表格，公式与绘制图形"
+++

原文：[《A Simple Way to Internationalize in Go with go-i18n》][origin]

作者：Theo PhraseApp Content Team

<center>
<img src="top.jpg" width=100% />
<p>
今天我们来探索另外一种 Go 全球化的库，叫作 go-i18n。它提供了一种支持翻译文件
的方便的接口，并实现自动化的流程。
</p>
</center>

以前我们用了 `golang.org/x/text` 包来[实现 Go 的国际化][old-post-en]。
（译注：这一篇译文在 [《[译] 手把手教你 Go 程序的国际化和本土化》][old-post-zh]）
尽管那个包拓展性很好，但操作起来较为困难，而且文档也不清楚。要想用更简单的办法来本地化我们的
 Go 程序，还有另一种方案，叫 [go-i18n][go-i18n]。

go-i18n 支持：

* 200 多种语言的复数形式
* 带有命名的字符串
* 任一种格式的翻译文件（如 JSON, TOML, YAML 等）
* 文档很好

但它当前还不支持性别规则，也不支持复杂的模版变量。不过对于大多数情况，本地化现有程序已经足够了。
这篇教程中，我们将看到一些实际案例，同时试着去集成 PhraseApp 的上下文编辑器到程序中。所有示例
代码都托管在 [GitHub][github] 上了。来开始吧！

## 定义和翻译消息

在使用这个库之前，我们需要先将它下载到 **$GOPATH**，使用下面命令：

```sh
$ go get -u github.com/nicksnyder/go-i18n/v2/i18n
```

接着新建一个文件，来测试一下翻译：

```sh
$ touch example.go
```

**文件：** example.go

```go
package main

import (
  "github.com/nicksnyder/go-i18n/v2/i18n"
  "golang.org/x/text/language"
)

func main() {
}
```

第一步是建立语言包，包含支持的语言和默认语言。我们来建一个默认为英语的：

```go
// 第一步: 新建语言包
func main() {
  bundle := &i18n.Bundle{DefaultLanguage: language.English}
}
```

为了进行翻译，需要创建一个 Localizer 对象，传入我们需要翻译的语言列表。有了一系列语言包后，
程序会按照语言标签去选择对应的语言包。

```go
// 第二步：使用一到多个语言标签来创建 localizer
loc := i18n.NewLocalizer(bundle, language.English.String())
```

现在还没有任何要翻译的消息，我们来加一些：

```go
// 第三步：定义消息
messages := &i18n.Message{
  ID: "Emails",
  Description: "The number of unread emails a user has",
  One: "{{.Name}} has {{.Count}} email.",
  Other: "{{.Name}} has {{.Count}} emails.",
}
```

从上面能看到复数规则的使用，还用到了模版变量。

最后一步，进行翻译操作：

```go
// 第四步：翻译消息
messagesCount := 2
translation := loc.MustLocalize(&i18n.LocalizeConfig{
  DefaultMessage: messages,
  TemplateData: map[string]interface{}{
    "Name": "Theo",
    "Count": messagesCount,
  },
  PluralCount: messagesCount,
})

fmt.Println(translation)
```

如果出错的话，**MustLocalize** 方法会出现 panic。有一个相关的方法叫 **Localize** ，会返回错误。

上面的代码中，我们传了 **messagesCount** 到 **TemplateData** 和
**PluralCount** 中，以正确生成复数，这至关重要。
 
### 定义分隔符

如果不喜欢双括弧的话，我们有选项去定义另外的分割符。只需要设定 **LeftDelim** 和
**RightDelim** 并把消息里的字符串设置为对应的符号就行了。

```go
// 定义不同的分隔符
messages = &i18n.Message{
  ID: "Notifications",
  Description: "The number of unread notifications a user has",
  One: "<<.Name>> has <<.Count>> notification.",
  Other: "<<.Name>> has <<.Count>> notifications.",
  LeftDelim: "<<",
  RightDelim: ">>",
}

notificationsCount := 1
translation = loc.MustLocalize(&i18n.LocalizeConfig{
  DefaultMessage: messages,
  TemplateData: map[string]interface{}{
    "Name": "Theo",
    "Count": notificationsCount,
  },
  PluralCount: notificationsCount,
})

fmt.Println(translation)
```

### 从文件加载消息

我们也可以从文件加载翻译内容。要这样用的话，需要先在语言包里定义 Unmarshal 函数，然后从某个文件
读取消息。

```go
// 从文件解析
bundle.RegisterUnmarshalFunc("json", json.Unmarshal)
bundle.MustLoadMessageFile("en.json")
bundle.MustLoadMessageFile("el.json")

loc = i18n.NewLocalizer(bundle, "el")
messagesCount = 10
translation = loc.MustLocalize(&i18n.LocalizeConfig{
  MessageID: "messages",
  TemplateData: map[string]interface{}{
    "Name": "Alex",
    "Count": messagesCount,
  },
  PluralCount: messagesCount,
})

fmt.Println(translation)
```

JSON 文件的内容如下：

**文件：** el.json

```json
{
"hello_world": "Για σου Κόσμε",
"messages": {
  "description": "The number of messages a person has",
  "one": "Ο {{.Name}} έχει {{.Count}} μύνημα.",
  "other": "Ο {{.Name}} έχει {{.Count}} μύνηματα."
  }
}
```

**文件：** en.json

```json
{
"hello_world": "Hello World",
"messages": {
  "description": "The number of messages a person has",
  "one": "{{.Name}} has {{.Count}} message.",
  "other": "{{.Name}} has {{.Count}} messages."
  }
}
```

试着运行完整的程序，看，翻译完成了。

```sh
$ go run example.go

Theo has 2 emails.
Nick has 1 notification.
Ο Alex έχει 10 μύνηματα.
```

## 使用命令行工具

这个库还带了个命令行工具，用来自动提取与合并翻译文件。

首先，我们需要安装

```sh
$ go get -u github.com/nicksnyder/go-i18n/v2/goi18n
```

目前它提供了两个命令：

* extract：从源程序提取消息并输出到特定格式的文件
* merge：合并两到多个特定格式文件中的消息

来看看这两个命令的使用示例。

先创建一个文件，名为 messages.go

```sh
$ touch messages.go
```

**文件：** messages.go

```go
package main

import "github.com/nicksnyder/go-i18n/v2/i18n"

var messages = i18n.Message{
    ID: "invoices",
    Description: "The number of invoices a person has",
    One: "You can {{.Count}} invoice",
    Other: "You have {{.Count}} invoices",
}
```

使用 extract 命令来导出消息为 JSON 格式。

```sh
$ mkdir out
$ goi18n extract -outdir=out -format=json newMessages.go
```

**文件：** out/active.en.json

```json
{
  "invoices": {
    "description": "The number of invoices a person has",
    "one": "You can {{.Count}} invoice",
    "other": "You have {{.Count}} invoices"
  }
}
```

接着对两个已有的翻译文件，我们来合并它们：

```sh
$ goi18n merge -outdir=out -format=json en.json out/active.en.json
```

**文件：** out/active.en.json

```json
{
  "hello_world": "Hello World",
  "invoices": {
    "description": "The number of invoices a person has",
    "one": "You can {{.Count}} invoice",
    "other": "You have {{.Count}} invoices"
  },
  "messages": {
    "description": "The number of messages a person has",
    "one": "{{.Name}} has {{.Count}} message.",
    "other": "{{.Name}} has {{.Count}} messages."
  }
}
```

如你所见，我们已将所有消息都合并到单个文件里了。

## 集成 PhraseApp 上下文编辑器

PhraseApp 的[上下文编辑器][in-context-editor]是个帮你在翻译时提升质量的工具，
它提供有用的上下文信息。借助这个编辑器，你可以在编辑文本的同时预览你的网站。

尽管 go-i18n 还没有内置这个编辑器，但你可以按照这篇向导来集成：

https://help.phraseapp.com/in-context-editor/configure/integrate-in-context-editor-into-any-web-framework/

然后我们可以注册自己的模版过滤器，并集成到自己的应用中。

来看看如何通过简单几步使用它。

新建一个叫 **inContext.go** 的文件，加入下面代码。

```sh
$ touch inContext.go
```

**文件：** inContext.go

```go
package main

import (
	"html/template"
	"log"
	"net/http"
	"github.com/nicksnyder/go-i18n/v2/i18n"
	"golang.org/x/text/language"
	"encoding/json"
	"flag"
	"fmt"
)


var page = template.Must(template.New("").Parse(`
<!DOCTYPE html>
<html>
<body>
<h1>{{ .Title }}</h1>
{{range .Paragraphs}}<p>{{ . }}</p>{{end}}
</body>
</html>
`))

func main() {

	bundle := &i18n.Bundle{DefaultLanguage: language.English}
	bundle.RegisterUnmarshalFunc("json", json.Unmarshal)
	for _,lang := range []string{"en" ,"el"} {
		bundle.MustLoadMessageFile(fmt.Sprintf("active.%v.json", lang))
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		lang := r.FormValue("lang")
		accept := r.Header.Get("Accept-Language")
		localizer := i18n.NewLocalizer(bundle, lang, accept)

		name := r.FormValue("name")
		if name == "" {
			name = "Alex"
		}

		myInvoicesCount := 10

		helloPerson := localizer.MustLocalize(&i18n.LocalizeConfig{
			DefaultMessage: &i18n.Message{
				ID:    "HelloPerson",
			},
			TemplateData: map[string]interface{}{
				"Name": name,
			},
		})

		myInvoices := localizer.MustLocalize(&i18n.LocalizeConfig{
			DefaultMessage: &i18n.Message{
				ID:          "invoices",
			},
			TemplateData: map[string]interface{}{
				"Count": myInvoicesCount,
			},
			PluralCount: myInvoicesCount,
		})

		err := page.Execute(w, map[string]interface{}{
			"Title": helloPerson,
			"Paragraphs": []string{
				myInvoices,
			},
		})
		if err != nil {
			panic(err)
		}
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

这段程序创建一个 Web 服务器，提供一个带有默认语言的页面。如果你打开浏览器并访问 `localhost:8080/?lang=el`
将会看到翻译后的希腊语页面。

要想集成 PhraseApp 的上下文编辑器进去，我们需要把模版变量封装到 `{{__phrase_` 和 `__}}` 
两个分隔符之间，接着加载 JavaScript 客户端。

可以使用 https://golang.org/pkg/text/template/#Template.Funcs 函数去注册我们自己的翻译过滤器，
一旦配置好后，就可以用来封装上面的参数。现在就来做。

**文件：** inContext.go

```go
// 从配置加载
var isPhraseAppEnabled bool

func init()  {
	flag.BoolVar(&isPhraseAppEnabled,"phraseApp", false, "Enable PhraseApp mode")
	flag.Parse()
}

var apiToken = os.Getenv("PHRASE_APP_TOKEN")

func translate(s string) string  {
	if isPhraseAppEnabled {
		return "{{__phrase_" + s + "__}}"
	} else {
		return s
	}
}

var funcs = template.FuncMap{
    "translate": translate,
}
```

这里我们加了一个 translate 函数，它按照 **phraseApp** 的配置（去设置是不是替换字符串为模版变量）。

现在只需要把这个过滤器加到每个模版参数上，再加上 PhraseApp 脚本就好了。

```js
var page = template.Must(template.New("").Funcs(funcs).Parse(`
<!DOCTYPE html>
<html lang= {{ .CurrentLocale }}>
<body>
<h1>{{ translate .Title }}</h1>
{{range .Paragraphs}}<p>{{ translate . }}</p>{{end}}
</body>

window.PHRASEAPP_CONFIG = {
   projectId: {{ .apiToken }}
};
(function() {
   var phraseapp = document.createElement('script'); phraseapp.type = 'text/javascript'; phraseapp.async = true;
   phraseapp.src = ['https://', 'phraseapp.com/assets/in-context-editor/2.0/app.js?', new Date().getTime()].join('');
   var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(phraseapp, s);
})();

</html>
`))
```

更新模版以包含 **apiToken** 参数。

```go
err := page.Execute(w, map[string]interface{}{
			"apiToken": apiToken,
			"Title": helloPerson,
			"CurrentLocale": language.Greek.String(),
			"Paragraphs": []string{
				myInvoices,
			},
		})
```

如果你没有令牌（token），到 https://phraseapp.com/ 注册并使用试用版。

在你设置好账号后，就可以新建项目并在 Project Setting 页找到 **projectId** 的令牌。

<center>
<img src="phrase-app-new-project.png" width=100% />
</center>

<center>
<img src="phrase-app-setting.png" width=100% />
</center>

在启动服务端前，用这个令牌去设置环境变量 `PHRASE_APP_TOKEN` 的值。

打开应用的页面后，你将看到 PhraseApp 登录的页面，在授权后你会看到翻译后的文本，
这些字符串旁边带有编辑按钮。下面还显示编辑器面板。

<center>
<img src="phrase-app-demo.png" width=100% />
</center>


在这里你可以轻松管理你的翻译啦！

## 结论

这篇文章里，我们看了如何使用 go-i18n 库去翻译 Go 应用，还了解了如何集成 PhraseApp
的上下文编辑器进来。如果你还有什么问题，别犹豫，在下面留言或私信我。感谢阅读，下次再见！

[origin]: https://phraseapp.com/blog/posts/internationalisation-in-go-with-go-i18n/
[old-post-en]: https://phraseapp.com/blog/posts/internationalization-i18n-go/
[old-post-zh]: https://zyfdegh.github.io/post/201805-translation-go-i18n/
[go-i18n]: https://github.com/nicksnyder/go-i18n
[github]: https://github.com/PhraseApp-Blog/phrase-app-go-i18n
[in-context-editor]: https://phraseapp.com/blog/posts/use-phraseapp-in-context-editor/
