+++
date = "2018-09-29"
title = "[译] 炫酷的 macOS Mojave 动态时移壁纸是怎么实现的？"
+++

原文：[《How macOS Mojave’s awesome time-shifting Dynamic Desktop wallpapers work》][origin]  
作者：Christian Zibreg  
时间：2018/06/06

<center>
<img src="1.jpg" width=100% />
</center>

除了抢眼的主要功能外，macOS Mojave 还多了个动态桌面的特性，它能够按照一天中的时间自动选择适合的壁纸。

本文要点：

* 动态桌面是 macOS Mojave 10.14 中新功能
* Mojave 自带了两款动态壁纸：Mojave 沙漠和日光度图
* 这些壁纸会从白天到黑夜无缝地切换
* 壁纸打包在 .HEIC 文件中，含多个图
* 用户无法创作自己的动态时移壁纸

## 时移桌面壁纸

由于需要知道你住在哪，动态桌面需要位置服务，就像夜览模式也需要定位才能知道日出、日落时间一样。
“动态桌面根据您的位置更换一天中的图片”，特性说明上写道。

<center>
<img src="2.jpg" width=100% />
</center>

这几年来，macOS 有个选项，能让你每次登录到系统或者唤醒电脑时，更换桌面壁纸图片。

你还可以设定每隔几分钟自动切换壁纸，或者每几小时、几天这样。这只是个简单的循环，按照你的选择去图库里切换。
有了动态桌面，这些壁纸能巧妙并且渐进地更改图片，以适合你的位置。

## 如何试用动态桌面

语言已经无法恰如其分地形容动态桌面之妙了。最好的办法是你亲身体验一下，去设定一个动态壁纸，还有屏幕节能设定。

教程：[《How to use Nigh Shift for Mac》][tutorial]

动态桌面需要特殊制作的壁纸。

## 动态壁纸是怎么打包的？

前面提到的，macOS Mojave 带了两款动态壁纸，名字都含有 “动态”。他们都是与 Mojave 浅色、深色模式相配套的主题，
其中一个是沙漠亮暗色主题。

所以时移桌面的秘诀在哪？

动态壁纸使用 Apple 的 HEIF 格式的图像文件，省空间，拓展名是 .HEIC。它是 2017 年发布的，用在 iOS 11 还有 macOS High Sierra 上。想要看看所有高分辨率壁纸的话，打开访达（Finder）点击 “转到” 菜单，然后点 “前往文件夹...” 选项。

输入下面的路径，按回车：

`/Library/Desktop Pictures`

默认的 Mojave 动态壁纸是个 114MB 的 HEIC 文件。

（译注：Mojave 10.14 正式版中为 134.8MB）

<center>
<img src="3.jpg" width=100% />
<p>动态壁纸编码在省空间的 HEIC 格式的图片中</p>
</center>

通过比较，Mojave 中其他所有壁纸都存储在常见的 JPEG 文件里（每个文件大约 10MB）。Apple 目前对想要自己创建动态壁纸的人，
还没提供说明。

## Hello, HEIC！
所以这个 114MB 的 HEIC 文件是如何工作的？

Apple 在同一地点每隔一段时间拍摄了从日出到黄昏的照片，然后打包为从白天到夜晚平滑过渡的图像。感谢爱好者，我们知道了
Mojave 的动态壁纸的 HEIC 文件中包含了 16 层图像。

在这里可以找到每张图：[GitHub 可下载的 JPG 图][github]

<center>
<img src="4.png" width=100% />
<p>预览沙漠主题的 HEIC 壁纸</p>
</center>

（译注：此段略有修改，测试版 Mojave 还不支持预览 HEIC 文件，现已支持）

还不太清楚用户是不是能为 Mojave 创建自己的动态壁纸文件，也不知道是不是需要特殊的软件工具，或者 Apple 是不是
计划详细说明动态桌面的支持。

## 总结
我是 macOS Mojave 动态桌面的大大...大粉丝。

配合新的[超赞的暗色模式][dark-mode]，动态桌面改变了用户交互界面，也在一整天中不断改变你的壁纸。

对动态桌面有何想法？

评论里说说吧！

[origin]: http://www.idownloadblog.com/2018/06/06/macos-mojave-dynamic-wallpaper-desktop/
[tutorial]: http://www.idownloadblog.com/2018/05/21/tutorial-night-shift-for-mac/
[github]: https://github.com/xtai/mojave-dynamic-heic/blob/master/README.md
[dark-mode]: http://www.idownloadblog.com/2018/06/13/mac-dark-mode-tutorial/