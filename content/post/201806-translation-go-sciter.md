+++
date = "2018-06-25"
title = "[译] sciter: 使用 HTML/CSS 构建 Golang 图形界面程序"
+++

原文：[《SCITER : GUI APPLICATION WITH GOLANG USING HTML/CSS》][origin]

作者：Manish Champaneri

<center>
<img src="sciter.png" width=100% />
<p>Golang 可视化库 sciter</p>
</center>

这是来自 sciter 网站的几句话，

> sciter 桌面 UI 开发带来了一系列网页技术。网页设计者和开发者可以复用他们
> 的经验和专长来构建看起来现代的桌面应用。

> 多种多样的 GUI 框架提供了不同的 UI 声明和格式语言，比如 QML 和 XAML（Microsoft WPF）。
> 不同的是， sciter 使用长期证明的、健壮的、灵活的 HTML 和 CSS 来定义 GUI，并
> 支持 GPU 加速。

在我使用 sciter 之前，我试过了其他几种选择，但没有一个满足我的要求。比如最开始，我用了
[andlabs/ui][andlabs-ui]，我写过一篇关于这个库的文章，可以去读这篇
[《Golang 图形界面编程》][go-gui]。不过这个库仍在开发中，不足以支持生产环境下的应用。

另外我用了 Eletron，然而问题是一个简单的计算器软件要占用 150MB，其中 15MB 是 Go 程序，
其余的都是 Electron 本身。

不久前，我找到了另一个替换品，就是 sciter。现在还能免费试用包含商业性的内容（有一定期限）。

我假定你已经阅读了开头引用的两段话，如果你想了解更多关于 sciter 的信息，可以访问网站
https://sciter.com/ 。

下面是 sciter 应用的简单实例

<center>
<img src="calc.png" width=50% />
<p>使用 Sciter & Golang 构建的简单 GUI 程序</p>
</center>

接下来我分享一下 Go 和 HTML 文件的源码（放在相同目录）。

Go 文件
```go
package main

import (
	"fmt"

	"github.com/fatih/color"
	sciter "github.com/sciter-sdk/go-sciter"
	"github.com/sciter-sdk/go-sciter/window"
)

// Specifying  havily used
// Singltons to make them
// package wide available
var root *sciter.Element
var rootSelectorErr error
var w *window.Window
var windowErr error

// Preapare Scitre For Execution ///
func init() {

	// initlzigin window for downloaer
	// app with appropriate properties
	rect := sciter.NewRect(0, 100, 300, 350)
	w, windowErr = window.New(sciter.SW_TITLEBAR|
		sciter.SW_CONTROLS|
		sciter.SW_MAIN|
		sciter.SW_GLASSY,
		rect)

	if windowErr != nil {
		fmt.Println("Can not create new window")
		return
	}
	// Loading main html file for app
	htloadErr := w.LoadFile("./main.html")
	if htloadErr != nil {
		fmt.Println("Can not load html in the screen", htloadErr.Error())
		return
	}

	// Initializng  Selector at global level as we  are going to need
	// it mostly and as it is
	root, rootSelectorErr = w.GetRootElement()
	if rootSelectorErr != nil {
		fmt.Println("Can not select root element")
		return
	}

	// Set title of the appliaction window
	w.SetTitle("Simple Calc")

}

// Preaprare Program for execution ///
func main() {

	addbutton, _ := root.SelectById("add")

	out1, errout1 := root.SelectById("output1")
	if errout1 != nil {
		color.Red("failed to bound output 1 ", errout1.Error())
	}
	addbutton.OnClick(func() {
		output := add()
		out1.SetText(fmt.Sprint(output))
	})

	w.Show()
	w.Run()

}


//////////////////////////////////////////////////
/// Function of calc                           ///
//////////////////////////////////////////////////

func add() int {

	
	// Refreshing and fetching inputs()
	in1, errin1 := root.SelectById("input1")
	if errin1 != nil {
		color.Red("failed to bound input 1 ", errin1.Error())
	}
	in2, errin2 := root.SelectById("input2")
	if errin2 != nil {
		color.Red("failed to bound input 2 ", errin2.Error())
	}

	in1val, errv1 := in1.GetValue()
	color.Green(in1val.String())

	if errv1 != nil {
		color.Red(errv1.Error())
	}
	in2val, errv2 := in2.GetValue()
	if errv2 != nil {
		color.Red(errv2.Error())
	}
	color.Green(in2val.String())

	return in1val.Int() + in2val.Int()
}

///////////////////////////////////////////////////
```

HTML 文件
```html
<html>
<head>
    <head>
        <title>Simple Calc</title> 
        <meta name="viewport" content="width=device-width, initial-scale=1.0">  
    </head>
</head>
<body>
    
    <label for="">Input First</label>
    <input type="number" style="width: 250px; margin: 0 auto;" id="input1" >
    <label for="">Input Second</label>
    <input type="number" style="width: 250px; margin: 0 auto;" id="input2" >
    <input type="button" style="width: 125px; margin: 0 auto;" value="Add ( + )" id="add"> 
    <hr>
    <input type="number" style="width: 250px; margin: 0 auto;" id="output1" disabled>
 

</body>
</html>
```

实际上，我发现的一个问题是，我需要刷新 HTML 元素绑定才能从中获得最新的值。

可能是我什么地方做错了，可能也有别人遇到了这个问题，没办法了。

无论如何总结一下，sciter 是 Go 中用来构建可视化应用最具前途的 GUI 库了。

希望对你有帮助！


[origin]: https://www.mchampaneri.in/2018/06/sciter-gui-application-with-golang.html#comment-form
[andlabs-ui]: https://github.com/andlabs/ui
[go-gui]: https://www.mchampaneri.in/2018/02/gui-programming-with-golang.html