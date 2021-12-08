+++
title = "解决 macOS 执行 brew 升级后 PHP 损坏"
date = "2021-12-08"
description = "如果你使用 brew 包管理器升级了软件，但执行后 php 无法运行了"
+++

## 现象

在 macOS 系统中，如果通过 brew upgrade 升级了软件包，可能导致一些软件无法运行，比如 php 运行报错

```sh
$ php -a
dyld[98833]: Library not loaded: /usr/local/opt/openldap/lib/liblber-2.5.0.dylib
  Referenced from: /usr/local/Cellar/php@7.2/7.2.34_4/bin/php
  Reason: tried: '/usr/local/opt/openldap/lib/liblber-2.5.0.dylib' (no such file), '/usr/local/lib/liblber-2.5.0.dylib' (no such file), '/usr/lib/liblber-2.5.0.dylib' (no such file), '/usr/local/Cellar/openldap/2.6.0/lib/liblber-2.5.0.dylib' (no such file), '/usr/local/lib/liblber-2.5.0.dylib' (no such file), '/usr/lib/liblber-2.5.0.dylib' (no such file)
[1]    98833 abort      php -a
```

## 原因
查了一些说法 openldap 版本太新了，当前安装的是 2.6.0，然而 php 运行需要的是 2.5.0。
有的说回退版本能解决问题，但这样做并不太好，因为以后还会需要升级。有的说重新安装 php 与 openldap
但试了不换版本没有作用。

```sh
$ brew info openldap
openldap: stable 2.6.0 (bottled) [keg-only]
```


## 解决办法
用了一个骚操作，让 php 能够找到依赖文件。先进入当前安装的 openldap 2.6.0 目录，看看有哪些库文件

```sh
$ ls -alh /usr/local/opt/openldap/lib/
drwxr-xr-x   9 ferdi  staff   288B Oct 26 04:40 .
drwxr-xr-x  15 ferdi  staff   480B Dec  8 21:44 ..
-rw-r--r--   1 ferdi  staff    94K Dec  8 21:44 liblber.2.dylib
-r--r--r--   1 ferdi  staff    83K Oct 26 04:40 liblber.a
lrwxr-xr-x   1 ferdi  staff    15B Oct 26 04:40 liblber.dylib -> liblber.2.dylib
-r--r--r--   1 ferdi  staff   347K Dec  8 21:44 libldap.2.dylib
-r--r--r--   1 ferdi  staff   521K Oct 26 04:40 libldap.a
lrwxr-xr-x   1 ferdi  staff    15B Oct 26 04:40 libldap.dylib -> libldap.2.dylib
drwxr-xr-x   4 ferdi  staff   128B Dec  8 21:44 pkgconfig
```

可以看到存在 libldap.dylib 但文件名中不再带有 2.5.0 或 2.6.0 的版本号了。那么只需要进行软链接

```sh
$ ln -s libldap.2.dylib libldap-2.5.0.dylib
$ ln -s liblber.2.dylib liblber-2.5.0.dylib
```

加了第二行，是因为再次运行 php -a 发现又缺少另一个文件 /usr/local/opt/openldap/lib/liblber-2.5.0.dylib

这样再次运行 php 便不再报错了

```sh
$ php -a
Interactive shell

php >
```

如果仍然缺少别的文件，也可以使用类似的方式，先找到缺少的库对应的软件包，进到目录，把文件复制或者创建一个软链接，多数时候能解决，不用再辛苦检索解决方案或者回退版本。

如果这个页面能帮到你，那么我没有白写，评论里让我知道吧！
