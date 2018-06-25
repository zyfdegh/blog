+++
date = "2018-06-25"
title = "让 macOS 中的 gitk 支持高清显示"
+++

使用 macOS 有一段时间了，大多数应用都能正常显示，并且效果很好。
但是 gitk（git-gui） 不行，显示毛糙，字体发虚，每次打开都无法接受。

<center>
<img src="gitk-origin.png" width=100%/>
<p>gitk 原始显示效果</p>
</center>

先放一下**修改后**的效果图，对比一下，再说修改步骤。
<center>
<img src="gitk-now.png" width=100%/>
<p>gitk 修改后显示效果</p>
</center>

## 修改步骤
1. 下载 Retinizer 并安装, 地址 http://retinizer.mikelpr.com/
<center>
<img src="retinazier-logo.png" width=20%/>
<p>Retinazier</p>
</center>
2. 打开 Wish 目录，并拖动 Wish.app 到 Retinizer 上。  
gitk 其实是一段 Tk 脚本，由 macOS 中的 Wish 执行，所以想要更改 gitk 的
图形化界面，其实是更改 Wish。Wish 路径在 `/System/Library/Frameworks/Tk.framework/Versions/Current/Resources/`
<center>
<img src="drag-wish.png" width=100%/>
<p>拖动 Wish.app 到 Retinazier 窗口中</p>
</center>
3. 点击 `Retinize!` 按钮，完成。

如果想要还原，再次打开 Retinizer，拖入 Wish.app，然后按钮会变成 `De-retinize`，
点完就好了。

除了 gitk 之外，上面的操作过程应该也适用于别的应用，但我还没有试过别的软件。如果你也有相似
的情况，可以试一试看咯。

最后查了一下原因和原理，发现是 Wish 应用中的 Info.plish 少了一段 NSHighResolutionCapable
的设定，而 Retinazer 正是通过修改这个文件才让程序得以适配 Retina 屏。