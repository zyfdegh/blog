+++
date = "2018-05-29"
title = "[译] 选择 Go 嵌入静态资源的库"
+++

原文：[《Choosing A Library to Embed Static Assets in Go
》][origin]

作者：Tim Shannon

译者按：文章介绍了 Go 嵌入静态文件的几种方法，接着讲自己在使用某一个库期间遇到的麻烦，
最后比较不同库的特点。对于想要将静态资源构建到可执行文件里的开发者来说，有一定参考意义。
在征得原文作者同意的前提下，我开始了翻译工作。

# 背景
Go 中一个常被吹捧的特性是 Go 应用容易部署，原因是 Go 写的程序是静态编译的。但在你
运行一个 Web 应用时，如果需要管理一系列文件的路径和权限的话，这个优势就基本不复存在了。

解决方法是把必要的文件编译到应用二进制里去。在 Go 中可以用字节切片存放文件中
[String literals][string-literals] 形式的字节内容。

```go
 fileData := []byte("\x1f\x8b\ ... \x0f\x00\x00")
```

但这种方法最大的几个坏处是：

* 更大的二进制文件
    * 对我当前的项目 [Lex Library][lex-library] 而言，在没嵌入静态文件之前，
    可执行文件大小为 20MB，嵌入后为 21MB。
* 更长的编译时间
    * 最新 Go 编译器的[缓存机制][go-caching]能有效减少构建时间。
* 编译时更占内存
    * 如果你在用小内存的设备开发，这会影响到你。但对我个人来说，还无需关心。

你需要在开发效率和运维管理时间上作取舍。如果你的应用受众是普罗大众（或者是那些有
个人网上应用的极客用户），就更值得权衡利弊了。

# 嵌入方式选择
第一个处理 Go 嵌入静态文件的库，或者说第一个真正知名的，应该是 [jteeuwen 的 Go-BinData][go-bindata]。
这是个命令行应用，你输入一个文件路径，它会生成包含静态文件的 `.go` 文件。

然而，作者 jteeuwen 似乎离开了星球，并在走时候把 GitHub 上这个仓库中所有东西删了。
幸运的是，他的代码是开源的，并在社区被广泛 fork。你在 GitHub 能找到好几个维护得很好的 fork。
我起初选的 fork 是 [shuLhan 的][shuLhan-fork]，但后来又选了别的方案，原因下面会讲。

更多有关 jteewen 项目的细节在这里：https://github.com/jteeuwen/go-bindata/issues/5

## 备选方案
既然 jteewen 的库有很多很多替代品。下面是我搜索并整理的一个不完全列表：

* vfsgen - https://github.com/shurcooL/vfsgen
* go.rice - https://github.com/GeertJohan/go.rice
* statik - https://github.com/rakyll/statik
* esc - https://github.com/mjibson/esc
* go-embed - https://github.com/pyros2097/go-embed
* go-resources - https://github.com/omeid/go-resources
* packr - https://github.com/gobuffalo/packr
* statics - https://github.com/go-playground/statics
* templify - https://github.com/wlbr/templify
* gnoso/go-bindata - https://github.com/gnoso/go-bindata
* shuLhan/go-bindata - https://github.com/shuLhan/go-bindata
* fileb0x - https://github.com/UnnoTed/fileb0x
* gobundle - https://github.com/alecthomas/gobundle
* parcello - https://github.com/phogolabs/parcello

本文目的是帮你弄明白这些库的差别，并帮你在选择上面的某个库时决定所需要考虑的特性。

# 去芜存菁
有了这么多选项，当决定要用哪一个才最适合需求时，就让人头大。你的程序和我的可能不一样，
但如果是 Web 应用的话，那会有很多可借鉴的地方。如果你需要做同样的选择，下文的比较
将会很有用。

## 判断标准

### 压缩
上文提到的，嵌入静态文件一个缺点是增加了可执行文件大小。你可以在嵌入静态文件之前，
用一个库去压缩，这样能减少一些空间。同时也需要花点小功夫去解压缩，但这通常是值得的，
因为除了节省空间外，构建时内存占用量也会减少。此外，网页静态文件压缩率较高（相比
图片），这就是为什么大多数浏览器支持 gzip 压缩的原因。这就引入了下一个标准。

### 可选解压缩
如果你的可执行文件中存有 gzip 压缩的静态文件，并且你想把这些文件按 gzip 格式提供
给客户端，那为何不直接发送这些已经压缩的文件呢？理想的库应该支持一个选项，让你在
运行时去设定直接接受压缩后的文件，而不需要先解压。

### 从本地文件系统加载
在你开发 Web 应用时，在你修改代码与看到改变之间，任何增加了时间或困难的事都应该
被避免。如果在你每次修改 CSS 或 HTML 代码时，都必须重新构建 Go 程序来静态嵌入文件，
你很快（就会放弃并）会选别的方案。

理想的库应该允许我们轻松切换开发中构建的程序，从本地快速加载静态文件；在生产中，静态
文件已经嵌入可执行程序并准备好发布了。

### 可重现的构建
这个准则让我很意外，在我着手开发 [Lex Library][lex-library] 时，我起初都没有考虑过。
前面提到的，我第一个选择的库是 [shuLhan fork 的 go-bindata][shuLhan-fork]。
我选择它主要是因为我对原始的 go-bindata 库熟悉，而且这个 fork 看起来维护得很好。

这个库用起来很赞，不过出乎意料的事，我的持续集成（CI）构建开始失败。像每一位碰到测试失败
的开发者一样，我想到的是**改动了什么**。我立刻去检查最新提交的改动，并试着弄明白为什么
这些改动导致模版处理失败。在我困惑一阵后，并没有找到原因，于是我重新跑了一次测试套件，
这次测试是基于最后一次构建成功的代码的，但也失败了。这说明改动在于环境，而不是我的代码。
不过这引出了更多了问题。

我是在 Docker 容器中跑持续集成测试的。测试环境应该是自我包好的、崭新的并且可复现的。
但我的假设并不正确。在我看 `Dockerfile` 时，找到了问题所在：

```sh
RUN go get -u github.com/shuLhan/go-bindata/...
```

库 go-bindata 有一次小的更新，这影响了我传静态文件路径的过程。突然间我嵌入的文件路径
就和我的预期不一样了。这可能怪一些因素，比如 go get 总是获取默认的分支。最后，
归结为这样简单的事实：程序中生成代码的模块版本没有被确定并让我的 git 仓库追踪。程序依赖的
外部代码如果改动了，就会在不知不觉时，导致我的构建或测试失败。

一种解决办法是存个预先编译的 go-bindata 可执行文件到我的 git 项目中，但是：

1. 通常 git 仓库中不宜存二进制文件。
2. 如果依赖的库修复了漏洞，我每次都需要手动更新 go-bindata。
3. 如果换一个平台，将会使构建变得困难。

此外，我找到了一个无需独立二进制文件的库，完全依赖代码版本，这可以用 vendor 来管理。
意思是有一个支持 go-generate 的库，但不同的是，不需要依赖外部程序运行。

### 附加的标准
上文讲你可能有不同的需求，所以在我的下面的对比表中，还添加了一些额外的标准，这或许对你有用。

#### 配置文件
如果你有大量不同的目录和文件需要管理，使用配置文件并放到你的源码里，这样管理就轻松多了。

#### http.FileSystem 接口
实现 [http.FileSystem][http-filesystem] 接口的库能让嵌入文件更容易处理。

#### GitHub 超过 200 星
这有点武断，星数不一定是衡量代码质量的方法。不过项目星数能说明库的活跃性，起码能说明是不是
一个在多处被引用的库。这反过来也说明很多人都在测试它，和（或）反馈问题。我选的库，
仅仅超过了这个星数，注意一下。

# 对比
|库|压缩|可选解压|本地文件系统|go generate|无可执行文件|配置文件|http.FS|多于 200 星|
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| vfsgen | ✓ | ✓ | ✓* | ✓ | ✓ | ✗  | ✓ | ✓
| go.rice | ✓ | ✗  | ✓ | ✗  | ✗  | ✗  | ✓ | ✓ | 
| statik | ✓ | ✗  | ✗  | ✗  | ✗  | ✗  | ✓ | ✓ | 
| esc | ✓ | ✗  | ✓ | ✓ | ✗  | ✗  | ✓ | ✓ | 
| go-embed | ✓ | ✗  | ✓* | ✗  | ✗  | ✗  | ✗  | ✗  | 
| go-resources | ✗  | ✗ 	 | ✓* | ✗  | ✗  | ✗  | ✓ | ✗  | 
| packr | 	✓ | ✗  | ✓ | ✗  | ✗  | ✗  | ✓ | ✓ | 
| statics | ✓ | ✗  | ✓ | ✓ | ✗  | ✗  | ✓ | ✗  | 
| templify | ✗  | ✗  | ✓ | ✓ | ✗  | ✗  | ✗  | ✗  | 
| gnoso/go-bindata | ✓ | ✗  | ✗  | ✗  | ✗  | ✗  | ✗  | ✓ | 
| shuLhan/go-bindata | ✓ | ✗  | ✓ | ✗  | ✗  | ✗  | ✗  | ✗  | 
| fileb0x | ✓ | ✓ | ✓ | ✓ | ✗  | ✓ | ✓ | ✓ | 
| gobundle | ✓ | ✗  | ✗  | ✗  | ✗  | ✗  | ✗  | ✗  | 
| parcello | ✓ |  ✗  | ✓ | ✓ | ✗  | ✗  | ✓ | ✓ | 

\* 需要额外代码

我使用这些库的经验是它们在写程序和部署时各有不同，要去看对应项目的 `README` 和文档。
如果你看到上表中不准确之处，请在评论中让我知道，我会更新。

# 我的选择
通过上面的比较表，就很清楚为什么我最终会用 [vfsgen][vfsgen]，并且我高度推荐它，
尤其在你需要可复现的构建时。稍逊一点的是 [fileb0x][fileb0x]，它需要独立的
可执行文件才能使用 `go generate`。

[origin]: http://tech.townsourced.com/post/embedding-static-files-in-go/
[string-literals]: https://golang.org/ref/spec#String_literals
[lex-library]: https://github.com/lexlibrary/lexlibrary
[go-caching]: https://golang.org/doc/go1.10#build
[go-bindata]: https://github.com/jteeuwen/go-bindata
[shuLhan-fork]: https://github.com/shuLhan/go-bindata
[http-filesystem]: https://golang.org/pkg/net/http/#FileSystem
[vfsgen]: https://github.com/shurcooL/vfsgen
[fileb0x]: https://github.com/UnnoTed/fileb0x