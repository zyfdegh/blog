+++
title = "Markdown 进阶教程"
date = "2018-04-28T13:10:32+08:00"
description = "使用 Markdown 的表格，公式与绘制图形"
+++

（本文在移动设备上显示效果可能不佳）

掌握了一些基础的 Markdown 语法后，便能轻松书写，但想学习更多技巧，请浏览这篇文章。

# 特殊字符
如果想打出 Markdown 语法已经占用的字符，比如 \*，\#，\| 等该怎么办？简单，在这些字符前加
上反斜线  \\ 就好了，如 `\*`。

\\   反斜线  
\`   反引号  
\*   星号  
\_   底线  
\{\}  花括号  
\[\]  方括号  
\(\)  括弧  
\#   井字号  
\+   加号  
\-   减号  
\.   英文句点  
\!   惊叹号  

# 分行
通常当你输入一段文字时，Markdown 并不会按回车符 (Enter) 进行分行。

```
We are the impact and the glue.
Capable of more than we know,
We call this fixer-upper home.
With each year, our color fades.
Slowly, our paint chips away.
```

实际排版会按页面宽度拉伸：

```
We are the impact and the glue. Capable of more than we know, We call
this fixer-upper home. With each year, our color fades. Slowly, our paint
chips away.
```

这时又不想在每行间敲回车，那么可以在**每一行最后加两个空格**。

# 词语定义

如果想给**术语**、**词汇**加定义，那么除了使用加粗外，还有专门的方式。

如使用下面两行
```
ĐApp
: A decentralized application (dapp, dApp, DAPP or DApp) is an application
 that runs on a decentralized network.
```

将显示为

ĐApp
: A decentralized application (dapp, dApp, DAPP or DApp) is an application that runs on a decentralized network.


# 脚注
旧金山和约，是第二次世界大战的大部分同盟国成员与日本签订的和平条约，1951年9月8日由包括日本
在内的49个国家的代表[^1]在美国旧金山的战争纪念歌剧院签订。

[^1]: 不包括中国、俄国。

```
49个国家的代表[^1]在美国

[^1]: 不包括中国、俄国。
```

脚注会自动按文中出现顺序编号 1，2，3...，脚注名并不是实际序号。可用英文替换，避免处使用时混淆。

```
49个国家的代表[^countries]在美国

[^countries]: 不包括中国、俄国。
```

# LaTeX 公式
LaTeX 行内公式，用一对 `$` 隔开，如 $E=mc^2$。

了解更多 LaTeX 语法，可看我的另一篇文章[《LaTeX 公式极简笔记》](https://zyfdegh.github.io/post/201805-latex-tutorial/)。

# 绘制图形
当前 GitHub Pages 主题未支持，请参考 [Draw Diagrams With Markdown
](http://support.typora.io/Draw-Diagrams-With-Markdown/)。

# 嵌入 HTML
比如，想要个按钮？
```
<button class="button large">Press here</button>
```
<button class="button large">Press here</button>

想要文字带有颜色并使用字体？

```
<font face="verdana" color="red">RED text, font verdana</font>
```
<font face="verdana" color="red">RED text, font verdana</font>

**参考文档**

\[1\] 黄学涛.[Markdown进阶语法整理](https://www.jianshu.com/p/0b257de21eb5), 2015-11-14

\[2\] [Advanced use of Markdown](https://docs.moodle.org/24/en/Advanced_use_of_Markdown)

[latex-pdf]: https://www.cs.princeton.edu/courses/archive/spr10/cos433/Latex/latex-guide.pdf
