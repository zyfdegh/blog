+++
title = "系统调用：Linux 源码如何实现"
date = "2021-04-01"
description = "想知道 Go 中执行 time.Now() 如何获得系统时间"
draft = true
+++

查看 Linux 源码实现
--------------------------------------------------------------------------------
Linux 最新代码，https://github.com/torvalds/linux，Commit 5e46d1b78a

找到了 `clock_gettime` 的定义，是 `__vdso_clock_gettime` 的 alias

arch/x86/entry/vdso/vclock_gettime.c
```cpp
int clock_gettime(clockid_t, struct old_timespec32 *)
	__attribute__((weak, alias("__vdso_clock_gettime")));

int clock_gettime64(clockid_t, struct __kernel_timespec *)
	__attribute__((weak, alias("__vdso_clock_gettime64")));
```

arch/x86/um/vdso/um_vdso.c
```cpp
int __vdso_clock_gettime(clockid_t clock, struct __kernel_old_timespec *ts)
{
	long ret;

	asm("syscall" : "=a" (ret) :
		"0" (__NR_clock_gettime), "D" (clock), "S" (ts) : "memory");

	return ret;
}
int clock_gettime(clockid_t, struct __kernel_old_timespec *)
	__attribute__((weak, alias("__vdso_clock_gettime")));
```

如何编写一个 Linux 系统调用？
--------------------------------------------------------------------------------
能改 Linux 源码，实现一个系统调用，叫 get_my_birthday()，返回我的出生年月时间戳？
```cpp

```

硬件时间
--------------------------------------------------------------------------------
石英钟如何计时？

BIOS 芯片如何存储、读取时间？

参考文档
1. 《时间到底是什么？1 秒究竟有多长？李永乐老师讲石英钟和原子钟》https://www.youtube.com/watch?v=cXX_f_pWLQI