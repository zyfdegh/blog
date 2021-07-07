+++
title = "CUDA 编程入门：GPU 驱动、CUDA 与样例程序"
date = "2020-05-31"
description = "从一台旧笔电折腾 nVidia CUDA 编程之旅"
+++

[TOC]

## 缘由
显卡这东西就目前来讲，通常两个作用，图形加速、机器学习，要么就数字货币挖矿，但这几年矿场倒的多。
不论如何，GPU 拼的都是算力，比 CPU 高很多。作为将近 8 年的卡巴基佬（手动斜眼），日常除了看各路
显卡性能 PK、购买攻略外，没做过其他研究，实在惭愧。

前些时间，在工作中要处理两个 CSV 文件，里面都是数字，要找出第二个文件比第一个多的数。
最先想到自然是用 Excel，VLOOKUP 函数能办到，但只能单核运行。两个文件较大时，就非常慢，
比如几十万行时，经常 Excel 无响应几分钟然后卡死。

举例来说，文件 a.csv

```csv
1
2
3
```

文件 b.csv
```csv
2
1
4
3
5
```

要做的便找出在 b.csv 但不在 a.csv 的数字，上例结果应为
```csv
4
5
```

为了比 Excel 运算更快，我自己写了个程序。

## 程序
逻辑蛮简单的，取 b.csv 每一行与 a.csv 所有行比较，相等跳过，无的话便符合，输出。伪代码如下
```php
FOR n1 IN b.csv {
    found = false
    FOR n2 IN a.csv {
        IF n1 == n2 {
            found = true
            BREAK
        }
    }
    if !found {
        print n1
    }
}
```

这样做的话时间复杂度为 O(n^2)，如果两个文件分别为 100k 行，则运算次数为 100 亿。

由于对输出数字顺序并无要求，多核并行的话，能更好发挥 CPU 算力。把 b.csv 切分为 N 份，
N 为核数（或称超线程数），每份分别与 a.csv 比对，最后把结果合并，这样核心数越多应该越快。

拿了一些不同 CPU 的机器分别试了试，得到以下结果。

| CPU | Cores, Threads | Base Freq | OS | Single core | Multicores |
|--|:--:|--|--|--|--|
| AMD R5 3600 | 6, 12 | 3.6GHz | Windows 10 | | 27.2s |
| Intel i5-7500  | 4, 4 | 3.4GHz | macOS 10.14 | 3m01.35s | 48.856s |
| Intel i5-7267U | 2, 4 | 3.1GHz | macOS 10.14 | - | 1m36.56s |
| Intel i5-2520M | 2, 4 | 2.5GHz | Linux 5.5   | 4m41.82s | 2m16.95s |
| Intel Atom N270 | 1, 2 | 1.6GHz | Linux 5.5 | - | ~15m |


这个 csv 文件处理的程序，放在了 GitHub https://github.com/zyfdegh/csvdiff

可以跑一下看看你的 CPU 耗时多久，欢迎在下面留言。

## CUDA
后来一直在想怎样提升速度，不改变算法复杂度的话，貌似只能加钱升级 AMD YES 了。这时想到手头一台老笔电
装有 nVidia GT635M 弱鸡显卡，平常打 CSGO 都非常吃力，开着还白耗电，不如折腾下看看。

以前听闻过各路 ML 大佬谈笑风生 tf, pytorch, dnn, cuda, nvidia-docker 之类的，作为菜鸟只能
在一旁黯然，也未曾想过去利用 GPU 来编程做通用计算，上老黄官网查了几天下来，逐渐对 GPU 运算有了了解。

## 相关链接

1. GPU Accelerated Computing with C and C++
https://developer.nvidia.com/how-to-cuda-c-cpp

2. CUDA Quick Start Guide (Install, Run Sample)
https://docs.nvidia.com/cuda/cuda-quick-start-guide/index.html

3. An Even Easier Introduction to CUDA
https://devblogs.nvidia.com/even-easier-introduction-cuda/

4. CUDA Compatibility
https://docs.nvidia.com/deploy/cuda-compatibility/index.html