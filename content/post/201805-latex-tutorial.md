+++
date = "2018-05-02"
title = "LaTeX 公式极简笔记"
+++

（本文在移动设备上显示效果可能不佳）

# 为什么要写
网上的教程，一搜一大片，为什么还要亲手写一篇？原因是自己在体验 LaTeX 写公式时，的确感受到这
很强，很酷。

# LaTeX 是什么
一种置标语言（标记语言）， 类似 Markdown，用纯文本实现文档排版和渲染。可写章节、表格，以及公式。
还能添加各种样式、扭曲文字，写艺术字、古字等。易导出为 PDF，mobi，HTML 等格式。

# LaTeX 用处
在学术界比较流行，尤其是数学、物理学和计算机科学界。通过一些拓展（宏包），还能制作乐谱、棋谱、
化学式、电路图等[^wiki1]。

# 为什么还要用 LaTeX
写论文、期刊容易通过纯文本看到格式啦，如果用 Microsoft Word + MathType 的确能写，但比较相像
的格式时不易分辨，还会受版本影响。对咯，LaTeX 更美观，还易于版本控制。

# 用什么写哇
推荐的一些编辑器。

Online:  https://latexbase.com/  
macOS: [TexPad][texpad]  
Linux: [Tex Live][texlive]  
Windows: [MiKTeX][miktex]  

# 开始

## 公式

既然 LaTeX 较擅长公式，就先从公式写起。

用一对 `$` 符来嵌入公式到当前行，比如 $E=mc^2$ ,
用两对 `$` 符号来在单独一行显示公式。如 `$$E=mc^2$$` 

一些语法规则  

* 对于键盘上能打出来的常规字符，比如 `E`、`=` 和 `2` 直接书写；
* 上标用脱字号 “^”，比如 `x^2` 显示为 $x^2$；
* 下标用下划线 “_”，比如 `H_2O` 显示为 $H_2O$；
* 特殊字符，如希腊字、希伯来字、箭头、函数名、操作符等，都有对应的名字，用 `\name` 表示。如 \pi 为 $\pi$；
* 使用 `{}` 来框住连在一起的表达式，比如要写 $e^{i\pi}=-1$，要用 `e^{i\pi}=-1`；
* 通过 \frac 来写除法，如 \frac{1}{2} 得到 $\frac{1}{2}$；
* 乘法符 ‧ 用 \cdot 来写；
* 要写大括号本身，需要用 `\` 转义，如 \{\} 得到 $\{\}$；


从 [Wikipedia 量子力学][wiki-liangzilixue]页面找了一些公式用来训练。

```latex
$$E=h\nu$$
```
$$E=h\nu$$

```latex
$$-\frac{\hbar^2}{2m}\frac{d^2 \psi}{dx^2}=E\psi$$
```
$$-\frac{\hbar^2}{2m}\frac{d^2 \psi}{dx^2}=E\psi$$

```latex
$$\hat{p}_x=-i\hbar\frac{d}{dx}$$
```
$$\hat{p}_x=-i\hbar\frac{d}{dx}$$

```latex
$$\frac{1}{2m}\hat{p}_x^2=E$$
```
$$\frac{1}{2m}\hat{p}_x^2=E$$

```latex
$$\psi(x)=Ae^{ikx}+Be^{-ikx}$$
```
$$\psi(x)=Ae^{ikx}+Be^{-ikx}$$

```latex
$$E=\frac{\hbar^2 k^2}{2m}$$
```
$$E=\frac{\hbar^2 k^2}{2m}$$

```latex
$$\psi(x)=C\sin kx+D\cos kx$$
```
$$\psi(x)=C\sin kx+D\cos kx$$

```latex
$$\psi(0)=0=C\sin 0+D\cos 0=D$$
```
$$\psi(0)=0=C\sin 0+D\cos 0=D$$

```latex
$$\psi(L)=0=C\sin kL$$
```
$$\psi(L)=0=C\sin kL$$

```latex
$$k=\frac{n\pi}{L}$ \qquad $n=1,2,3,....$$
```
$$k=\frac{n\pi}{L}$ \qquad $n=1,2,3,....$$

```latex
$$E=\frac{\hbar^2 \pi^2 n^2}{2mL^2}=\frac{n^2h^2}{8mL^2}$$
```
$$E=\frac{\hbar^2 \pi^2 n^2}{2mL^2}=\frac{n^2h^2}{8mL^2}$$

```latex
$$V(x)=\frac{1}{2}m\omega^2x^2$$
```
$$V(x)=\frac{1}{2}m\omega^2x^2$$

```latex
$$\psi(x)=\sqrt{\frac{1}{2^n n!}}\cdot
\left( \frac{m\omega}{\pi\hbar} \right)^{\frac{1}{4}}\cdot
 e^{-\frac{m\omega x^2}{2\hbar}}\cdot 
 H_n \left( \sqrt{\frac{m\omega}{\hbar}x} \right)$$
```
$$\psi(x)=\sqrt{\frac{1}{2^n n!}}\cdot
\left( \frac{m\omega}{\pi\hbar} \right)^{\frac{1}{4}}\cdot
 e^{-\frac{m\omega x^2}{2\hbar}}\cdot 
 H_n \left( \sqrt{\frac{m\omega}{\hbar}x} \right)$$

看着挺牛，可有些符号我不认得，不知道名字怎么打出来？

数学符号可查这个文档 [LaTeX Mathematical Symbols][latex-symbols].

<center>
<img src="latex-symbols.png" width=80% />
</center>

文档挺全的，怎么快速查？

还有个叫 [Detexify][detexify] 的网站，能识别手写的符号，然后得到对应的名称。🧐

<center>
<img src="detexify.png" width=80% />
</center>

[^wiki1]: 维基百科 - LaTeX 趣味应用 https://zh.wikipedia.org/wiki/LaTeX

[texpad]: https://www.texpad.com/osx
[mactex]: http://www.tug.org/mactex/
[miktex]: https://miktex.org/
[texlive]: http://www.tug.org/texlive/
[wiki-liangzilixue]: https://zh.wikipedia.org/wiki/%E9%87%8F%E5%AD%90%E5%8A%9B%E5%AD%A6
[latex-symbols]: https://reu.dimacs.rutgers.edu/Symbols.pdf
[detexify]: http://detexify.kirelabs.org/classify.html
