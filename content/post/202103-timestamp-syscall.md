+++
title = "系统调用：从获取系统时间戳开始"
date = "2021-03-31"
description = "想知道 Go 中执行 time.Now() 如何获得系统时间"
+++

想知道 Go 中执行 time.Now() 如何获得系统时间吗? 在调用时，发生了什么。这不是个简单的问题。

先来发问
--------------------------------------------------------------------------------

来看这样一段代码

main.go
```go
package main

import (
        "time"
)

func main() {
        println(time.Now().Unix())
}
```

运行，在控制台得到当前时间戳，如 1617174901。

<!-- 演示：样例 /src-now，获取时间 -->

那么运行时，究竟发生了什么？

本文档将一步一步，从 Go 源码中 Now() 函数开始剖析，到 Go 如何调用汇编，再到系统调用过程，
解释系统调用如何进行。

> 文档中用的 Go 版本为 1.15.2

Go 源码分析
--------------------------------------------------------------------------------

先找 Go 源码，time.Now() 定义在

src/time/time.go
```go
// Now returns the current local time.
func Now() Time {
    sec, nsec, mono := now()
    //-- ... 转换并返回 --//
}
```

时间来自小写 `now()` 函数，其定义为

src/time/time.go
```go
// Provided by package runtime.
func now() (sec int64, nsec int32, mono int64)
```

这个函数没有方法体，只提供函数名与签名，是由 Go 之外的语言实现的。
Go 中对函数定义的说明，见 https://golang.org/ref/spec#Function_declarations

> A function declaration may omit the body. Such a declaration provides the signature 
for a function implemented outside Go, such as an assembly routine.

注释写了 now() 由 runtime 包提供，那到 runtime 包去找

没找到 `func now()`，但有 `func time_now()`，是这个吗？

src/runtime/timestub.go
```go
// Declarations for operating systems implementing time.now
// indirectly, in terms of walltime and nanotime assembly.

// +build !windows

package runtime

import _ "unsafe" // for go:linkname

//go:linkname time_now time.now
func time_now() (sec int64, nsec int32, mono int64) {
	sec, nsec = walltime()
	return sec, nsec, nanotime()
}
```

那怎么确定是这个 `func time_now()` 呢？

看上面用了条特殊注释 `//go:linkname` ，称为 Compiler Directives，更多编译器指令见
https://golang.org/pkg/cmd/compile/

```go
//go:linkname localname [importpath.name]
```
> the //go:linkname directive instructs the compiler to use “importpath.name” as the object file
 symbol name for the variable or function declared as “localname” in the source code.


好，现在知道 `time.now` 是 `time_now` 对象文件的符号名，也就是 `runtime.time_now` 返回了时间。
注意 runtime 包中有两个 `func time_now()`，另一个是这样

src/runtime/timeasm.go
```go
// Declarations for operating systems implementing time.now directly in assembly.

// +build windows

package runtime

import _ "unsafe"

//go:linkname time_now time.now
func time_now() (sec int64, nsec int32, mono int64)
```

跟前一个文件 `src/runtime/timestub.go` 不同之处在于，顶部的 Build constraints 不一样

第一个
```go
// +build !windows
```

第二个
```go
// +build windows
```

不同 OS 构建时，用了不同文件。更多 Build constraints 见 https://golang.org/cmd/go/#hdr-Build_constraints

那先来看非 Windows 系统，也就是含 Linux 的，后者开源好查

src/runtime/timestub.go
```go

// Declarations for operating systems implementing time.now
// indirectly, in terms of walltime and nanotime assembly.

// +build !windows

package runtime

import _ "unsafe" // for go:linkname

//go:linkname time_now time.now
func time_now() (sec int64, nsec int32, mono int64) {
    //-- 通过 walltime() 返回秒、纳秒 --//
    sec, nsec = walltime()
	return sec, nsec, nanotime()
}
```

注释写：当前时间 time.now 是操作系统实现的，是通过 walltime, nanotime 汇编，这里是间接的定义。

先看 `walltime()`，它返回了 sec, nsec，最后 `nanotime()` 返回了一个值，叫做 mono

看变量名 sec 是秒，nsec 大胆推测是纳秒，mono 应该是不变的、一直自增的时间，先放一放。

那么秒、纳秒怎么来的？再跳转到定义

src/runtime/time_nofake.go
```go
func walltime() (sec int64, nsec int32) {
	return walltime1()
}
```

调用了 `walltime1()`，再跳，由于当前机器是 macOS，跳到了 `src/runtime/sys_darwin.go` 中。

实际在 runtime 目录检索 walltime1，找到多个 `.go` 文件中声明了该函数，还有很多 `.s` 文件包含这个函数名。

```sh
runtime$ grep -r 'walltime1' .
./sys_linux_mips64x.s:// func walltime1() (sec int64, nsec int32)
./sys_linux_mips64x.s:TEXT runtime·walltime1(SB),NOSPLIT,$16-12
./sys_openbsd_amd64.s:// func walltime1() (sec int64, nsec int32)
./sys_openbsd_amd64.s:TEXT runtime·walltime1(SB), NOSPLIT, $32
./sys_linux_amd64.s:// func walltime1() (sec int64, nsec int32)
./sys_linux_amd64.s:TEXT runtime·walltime1(SB),NOSPLIT,$16-12
./sys_netbsd_arm.s:// func walltime1() (sec int64, nsec int32)
./sys_netbsd_arm.s:TEXT runtime·walltime1(SB), NOSPLIT, $32
./sys_netbsd_amd64.s:// func walltime1() (sec int64, nsec int32)
./sys_netbsd_amd64.s:TEXT runtime·walltime1(SB), NOSPLIT, $32
./sys_linux_riscv64.s:// func walltime1() (sec int64, nsec int32)
./sys_linux_riscv64.s:TEXT runtime·walltime1(SB),NOSPLIT,$24-12
./sys_openbsd_386.s:// func walltime1() (sec int64, nsec int32)
./sys_openbsd_386.s:TEXT runtime·walltime1(SB), NOSPLIT, $32
./sys_plan9_386.s:// func walltime1() (sec int64, nsec int32)
./sys_plan9_386.s:TEXT runtime·walltime1(SB),NOSPLIT,$8-12
./sys_linux_s390x.s:// func walltime1() (sec int64, nsec int32)
./sys_linux_s390x.s:TEXT runtime·walltime1(SB),NOSPLIT,$16
./sys_linux_mipsx.s:// func walltime1() (sec int64, nsec int32)
./sys_linux_mipsx.s:TEXT runtime·walltime1(SB),NOSPLIT,$8-12
./sys_linux_386.s:// func walltime1() (sec int64, nsec int32)
./sys_linux_386.s:TEXT runtime·walltime1(SB), NOSPLIT, $8-12
./sys_openbsd_arm.s:// func walltime1() (sec int64, nsec int32)
./sys_openbsd_arm.s:TEXT runtime·walltime1(SB), NOSPLIT, $32
./sys_plan9_arm.s:// func walltime1() (sec int64, nsec int32)
./sys_plan9_arm.s:TEXT runtime·walltime1(SB),NOSPLIT,$12-12
./vdso_freebsd.go:func walltime1() (sec int64, nsec int32) {
./timestub2.go:func walltime1() (sec int64, nsec int32)
./os_windows.go:// walltime1 isn\'t implemented on Windows, but will never be called.
./os_windows.go:func walltime1() (sec int64, nsec int32)
./sys_linux_arm.s:TEXT runtime·walltime1(SB),NOSPLIT,$8-12
./sys_dragonfly_amd64.s:// func walltime1() (sec int64, nsec int32)
./sys_dragonfly_amd64.s:TEXT runtime·walltime1(SB), NOSPLIT, $32
./time_nofake.go:       return walltime1()
./sys_netbsd_386.s:// func walltime1() (sec int64, nsec int32)
./sys_netbsd_386.s:TEXT runtime·walltime1(SB), NOSPLIT, $32
./sys_plan9_amd64.s:// func walltime1() (sec int64, nsec int32)
./sys_plan9_amd64.s:TEXT runtime·walltime1(SB),NOSPLIT,$8-12
./sys_linux_arm64.s:// func walltime1() (sec int64, nsec int32)
./sys_linux_arm64.s:TEXT runtime·walltime1(SB),NOSPLIT,$24-12
./os_aix.go:func walltime1() (sec int64, nsec int32) {
./sys_openbsd_arm64.s:// func walltime1() (sec int64, nsec int32)
./sys_openbsd_arm64.s:TEXT runtime·walltime1(SB), NOSPLIT, $32
./os3_solaris.go:func walltime1() (sec int64, nsec int32) {
./sys_netbsd_arm64.s:// func walltime1() (sec int64, nsec int32)
./sys_netbsd_arm64.s:TEXT runtime·walltime1(SB), NOSPLIT, $32
./sys_linux_ppc64x.s:// func walltime1() (sec int64, nsec int32)
./sys_linux_ppc64x.s:TEXT runtime·walltime1(SB),NOSPLIT,$16-12
./sys_wasm.s:TEXT ·walltime1(SB), NOSPLIT, $0
./sys_darwin.go:func walltime1() (int64, int32) {
```

看了下几个 `.go` 文件，多数都是空的声明，比如

src/runtime/timestub2.go
```go
// +build !darwin
// +build !windows
// +build !freebsd
// +build !aix
// +build !solaris

package runtime

func walltime1() (sec int64, nsec int32)
```

如上所说，这个没有 body 的函数，是在别的语言实现的。根据上面的 Build constraints，知道 linux 是用的这个。

先铺垫下 Go 与汇编
--------------------------------------------------------------------------------
继续分析之前，需要温习一下汇编基础，并了解 Go 如何调用汇编代码。

<!-- 演示：样例 /src-var-asm，调用汇编 -->

汇编代码分析
--------------------------------------------------------------------------------

还是回到获取时间，Linux amd64 对应的汇编代码在 `sys_linux_arm64.s`，里面含有 `walltime1`。是这样一段汇编代码

src/runtime/sys_linux_arm64.s
```go
// func walltime1() (sec int64, nsec int32)
// non-zero frame-size means bp is saved and restored
TEXT runtime·walltime1(SB),NOSPLIT,$16-12
	// We don't know how much stack space the VDSO code will need,
	// so switch to g0.
	// In particular, a kernel configured with CONFIG_OPTIMIZE_INLINING=n
	// and hardening can use a full page of stack space in gettime_sym
	// due to stack probes inserted to avoid stack/heap collisions.
	// See issue #20427.

	MOVQ	SP, BP	// Save old SP; BP unchanged by C code.

	get_tls(CX)
	MOVQ	g(CX), AX
	MOVQ	g_m(AX), BX // BX unchanged by C code.

	// Set vdsoPC and vdsoSP for SIGPROF traceback.
	// Save the old values on stack and restore them on exit,
	// so this function is reentrant.
	MOVQ	m_vdsoPC(BX), CX
	MOVQ	m_vdsoSP(BX), DX
	MOVQ	CX, 0(SP)
	MOVQ	DX, 8(SP)

	LEAQ	sec+0(FP), DX
	MOVQ	-8(DX), CX
	MOVQ	CX, m_vdsoPC(BX)
	MOVQ	DX, m_vdsoSP(BX)

	CMPQ	AX, m_curg(BX)	// Only switch if on curg.
	JNE	noswitch

	MOVQ	m_g0(BX), DX
	MOVQ	(g_sched+gobuf_sp)(DX), SP	// Set SP to g0 stack

noswitch:
	SUBQ	$16, SP		// Space for results
	ANDQ	$~15, SP	// Align for C code

	MOVQ	runtime·vdsoClockgettimeSym(SB), AX
	CMPQ	AX, $0
	JEQ	fallback
	MOVL	$0, DI // CLOCK_REALTIME
	LEAQ	0(SP), SI
	CALL	AX
	MOVQ	0(SP), AX	// sec
	MOVQ	8(SP), DX	// nsec
ret:
	MOVQ	BP, SP		// Restore real SP
	// Restore vdsoPC, vdsoSP
	// We don't worry about being signaled between the two stores.
	// If we are not in a signal handler, we'll restore vdsoSP to 0,
	// and no one will care about vdsoPC. If we are in a signal handler,
	// we cannot receive another signal.
	MOVQ	8(SP), CX
	MOVQ	CX, m_vdsoSP(BX)
	MOVQ	0(SP), CX
	MOVQ	CX, m_vdsoPC(BX)
	MOVQ	AX, sec+0(FP)
	MOVL	DX, nsec+8(FP)
	RET
fallback:
	LEAQ	0(SP), DI
	MOVQ	$0, SI
	MOVQ	runtime·vdsoGettimeofdaySym(SB), AX
	CALL	AX
	MOVQ	0(SP), AX	// sec
	MOVL	8(SP), DX	// usec
	IMULQ	$1000, DX
	JMP ret
```

看到这儿怕了，学汇编还是在校园，快十年。还是继续研究下，得弄清楚时间到底哪里来。

根据这本书籍，[Go 汇编语言 - 函数基本语法](https://cloud.tencent.com/edu/learning/course-2412-38523)，现学现讲

先看第一句，是函数定义

```go
// func walltime1() (sec int64, nsec int32)
// non-zero frame-size means bp is saved and restored
TEXT runtime·walltime1(SB),NOSPLIT,$16-12
```

- TEXT 用来定义函数标识，名称为 `runtime·walltime1`，中间用的中点（·）连接包名与函数名

- SB 是 Go 定义的伪寄存器，Static Base pointer，见 [Go 汇编中的伪寄存器](https://cloud.tencent.com/edu/learning/course-2412-38485)

- NOSPLIT 告诉编译器，这是叶子函数，不要进行栈分裂

- 函数的局部变量需要的栈空间大小是 16 个字节

- 12 表示函数参数和返回值空间大小为 12 字节

> (SB) 表示是函数名符号相对于 SB 伪寄存器的偏移量，二者组合在一起最终是绝对地址。
作为全局的标识符的全局变量和全局函数的名字一般都是基于 SB 伪寄存器的相对地址。

> NOSPLIT 主要用于指示叶子函数不进行栈分裂。如果有 NOSPLIT 标注，会禁止汇编器为汇编函数插入栈分裂的代码。
NOSPLIT 对应 Go 语言中的 //go:nosplit 注释。

以上解释主要引用 《Go 语言高级编程》 https://cloud.tencent.com/edu/learning/course-2412-38523

继续下面几行
```s
    //-- MOVQ 就是 MOV，操作对象是四字长（Quadword），8 bytes 的值 --//
    //-- 作用是调用其他函数前，暂存 SP 指针，后面还会还原 --//
    MOVQ	SP, BP	// Save old SP; BP unchanged by C code.

    //-- get_tls 线程相关，Thread Local Storage 线程本地存储  --//
    //-- 作用是获取 Goroutine 所属的线程信息，把信息对应指针放到 CX 中  --//
    //-- 这句被称为 “宏定义”，在 src/runtime/go_tls.h --/
	get_tls(CX)

    //-- 从 TLS 中得到 g，g 指针是 Goroutine 的结构 --//
    //-- 见 https://cloud.tencent.com/edu/learning/course-2412-38569 --//
	MOVQ	g(CX), AX

    //-- 又是个宏，还没查，先略过。 --//
    //-- 不过此时 AX，BX 存的是跟线程、协程相关的东西 --//
	MOVQ	g_m(AX), BX // BX unchanged by C code.
```

```s
    //-- 又是一批高端代码 --//

	// Set vdsoPC and vdsoSP for SIGPROF traceback.
	// Save the old values on stack and restore them on exit,
	// so this function is reentrant.
	MOVQ	m_vdsoPC(BX), CX
	MOVQ	m_vdsoSP(BX), DX
	MOVQ	CX, 0(SP)
	MOVQ	DX, 8(SP)

    //-- LEA： 取偏移地址（Load effective address） 
	LEAQ	sec+0(FP), DX
	MOVQ	-8(DX), CX
	MOVQ	CX, m_vdsoPC(BX)
	MOVQ	DX, m_vdsoSP(BX)
```

- VDSO 是 virtual dynamic shared object，用于用户态调用内核态，能减少内核切换开销，见 https://en.wikipedia.org/wiki/VDSO

> vDSO (virtual dynamic shared object) is a kernel mechanism for exporting a carefully selected set
 of kernel space routines to user space applications so that applications can call these 
 kernel space routines in-process, without incurring the performance penalty of a mode switch from
  user mode to kernel mode that is inherent when calling these same kernel space routines by means
   of the system call interface.

继续往下，来到重点逻辑
```s
    CMPQ	AX, m_curg(BX)	// Only switch if on curg.
	JNE	noswitch

	MOVQ	m_g0(BX), DX
	MOVQ	(g_sched+gobuf_sp)(DX), SP	// Set SP to g0 stack

noswitch:
	SUBQ	$16, SP		// Space for results
	ANDQ	$~15, SP	// Align for C code

	MOVQ	runtime·vdsoClockgettimeSym(SB), AX
	CMPQ	AX, $0
	JEQ	fallback
	MOVL	$0, DI // CLOCK_REALTIME
	LEAQ	0(SP), SI
	CALL	AX
	MOVQ	0(SP), AX	// sec
	MOVQ	8(SP), DX	// nsec
ret:
	MOVQ	BP, SP		// Restore real SP
	// Restore vdsoPC, vdsoSP
	// We don't worry about being signaled between the two stores.
	// If we are not in a signal handler, we'll restore vdsoSP to 0,
	// and no one will care about vdsoPC. If we are in a signal handler,
	// we cannot receive another signal.
	MOVQ	8(SP), CX
	MOVQ	CX, m_vdsoSP(BX)
	MOVQ	0(SP), CX
	MOVQ	CX, m_vdsoPC(BX)
	MOVQ	AX, sec+0(FP)
	MOVL	DX, nsec+8(FP)
	RET
fallback:
	LEAQ	0(SP), DI
	MOVQ	$0, SI
	MOVQ	runtime·vdsoGettimeofdaySym(SB), AX
	CALL	AX
	MOVQ	0(SP), AX	// sec
	MOVL	8(SP), DX	// usec
	IMULQ	$1000, DX
	JMP ret
```

用 Go 伪代码来写的话（师爷你给翻译翻译，什么叫做汇编）

```go
func walltime1() (int64, int32) {
    // 预处理
    // 1. 暂存 SP
    // 2. 处理线程、协程
    // 3. 处理内核调用

    var sec int64
    var nsec int32

    if on_curg {
        // noswitch
        f = vdsoClockgettimeSym()
        if f != nil {
            clockRealtime := 0
            f(clockRealtime, &ti)
            // sec: AX
            // nsec: DX
        } else {
            // fallback
            f = vdsoGettimeofdaySym()
            f(&ti)
            // sec: AX
            // usec: DX
            // nsec: DX * 1000
        }
    }
    // 后处理
    // 1. 恢复 SP
    // 2. 再处理内核调用

    return sec, nsec
}
```
这些汇编代码，本质是完成了一次系统调用。

再坚持下，看下 `runtime·vdsoClockgettimeSym` 和 `runtime·vdsoGettimeofdaySym` 是什么

```go
package runtime

const (
	// vdsoArrayMax is the byte-size of a maximally sized array on this architecture.
	// See cmd/compile/internal/amd64/galign.go arch.MAXWIDTH initialization.
	vdsoArrayMax = 1<<50 - 1
)

var vdsoLinuxVersion = vdsoVersionKey{"LINUX_2.6", 0x3ae75f6}

var vdsoSymbolKeys = []vdsoSymbolKey{
	{"__vdso_gettimeofday", 0x315ca59, 0xb01bca00, &vdsoGettimeofdaySym},
	{"__vdso_clock_gettime", 0xd35ec75, 0x6e43a318, &vdsoClockgettimeSym},
}

// initialize with vsyscall fallbacks
var (
	vdsoGettimeofdaySym uintptr = 0xffffffffff600000
	vdsoClockgettimeSym uintptr = 0
)
```

网上大佬说 `0x315ca59` 这个码是用来校验的，还不清楚怎么生成。

之前恰好查过 Linux 系统调用文档 https://man7.org/linux/man-pages/man2/syscalls.2.html

`gettimeofday` 和 `clock_gettime` 都在里面，`clock_gettime` 调用出入参，文档在
https://man7.org/linux/man-pages/man2/clock_gettime.2.html

```cpp
    #include <time.h>

    int clock_gettime(clockid_t clockid, struct timespec *tp);
```
第一个入参 `clockid` 传 CLOCK_REALTIME 时，表示系统时间。可以被用户、NTP 改变的那个。

> A settable system-wide clock that measures real (i.e.,
wall-clock) time.  Setting this clock requires appropriate
privileges.  This clock is affected by discontinuous jumps
in the system time (e.g., if the system administrator
manually changes the clock), and by the incremental
adjustments performed by adjtime(3) and NTP.

第二个入参，`timespec` 指针，其实是返回值，包含秒、纳秒信息。

出参 int，用于表示调用是否成功。

Linux 系统调用
--------------------------------------------------------------------------------
我们都知道，系统调用是操作系统提供的接口，用户态进程根据输入输出规格，阻塞地调用。

系统调用提供几乎操作系统的一切功能，不限于管理
- CPU
- 内存
- 进程
- 用户
- 用户组
- 文件
- 文件系统
- 中断
- 时间
- 网络
- I/O 设备

在 Linux amd64 操作系统中，这个头文件定义了系统调用编号。`clock_gettime` 编号为 228。

/usr/include/asm/unistd_64.h
```h
#ifndef _ASM_X86_UNISTD_64_H
#define _ASM_X86_UNISTD_64_H

#ifndef __SYSCALL
#define __SYSCALL(a, b)
#endif

/*
 * This file contains the system call numbers.
 *
 * Note: holes are not allowed.
 */

/* at least 8 syscall per cacheline */
#define __NR_read				0
__SYSCALL(__NR_read, sys_read)
#define __NR_write				1
__SYSCALL(__NR_write, sys_write)
#define __NR_open				2
__SYSCALL(__NR_open, sys_open)
#define __NR_close				3
__SYSCALL(__NR_close, sys_close)
#define __NR_stat				4
__SYSCALL(__NR_stat, sys_newstat)
#define __NR_fstat				5

//-- 省略 --//

#define __NR_clock_gettime			228
__SYSCALL(__NR_clock_gettime, sys_clock_gettime)
```

说了这么多，怎么知道这些分析过程是正确的，能自己再写一次 Go 与汇编，实现系统调用吗？

<!-- 演示：自己进行系统调用 -->

其他操作系统
--------------------------------------------------------------------------------
对于 Darwin amd64，是通过 libc 进行系统调用 `gettimeofday`，见 Apple Libc
https://opensource.apple.com/source/Libc/

src/runtime/sys_darwin.go
```go
//go:nosplit
//go:cgo_unsafe_args
func walltime1() (int64, int32) {
	var t timeval
	libcCall(unsafe.Pointer(funcPC(walltime_trampoline)), unsafe.Pointer(&t))
	return int64(t.tv_sec), 1000 * t.tv_usec
}
func walltime_trampoline()
```

src/runtime/sys_darwin_amd64.s
```s
TEXT runtime·walltime_trampoline(SB),NOSPLIT,$0
	PUSHQ	BP			// make a frame; keep stack aligned
	MOVQ	SP, BP
	// DI already has *timeval
	XORL	SI, SI // no timezone needed
	CALL	libc_gettimeofday(SB)
	POPQ	BP
	RET
```

对 Windows amd64，系统调用为 `GetSystemTimeAsFileTime`，
见 https://docs.microsoft.com/zh-tw/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsystemtimeasfiletime

src/runtime/sys_windows_amd64.s
```s
TEXT time·now(SB),NOSPLIT,$0-24
	CMPB	runtime·useQPCTime(SB), $0
	JNE	useQPC
	MOVQ	$_INTERRUPT_TIME, DI
loop:
	MOVL	time_hi1(DI), AX
	MOVL	time_lo(DI), BX
	MOVL	time_hi2(DI), CX
	CMPL	AX, CX
	JNE	loop
	SHLQ	$32, AX
	ORQ	BX, AX
	IMULQ	$100, AX
	MOVQ	AX, mono+16(FP)

	MOVQ	$_SYSTEM_TIME, DI
wall:
	MOVL	time_hi1(DI), AX
	MOVL	time_lo(DI), BX
	MOVL	time_hi2(DI), CX
	CMPL	AX, CX
	JNE	wall
	SHLQ	$32, AX
	ORQ	BX, AX
	MOVQ	$116444736000000000, DI
	SUBQ	DI, AX
	IMULQ	$100, AX

	// generated code for
	//	func f(x uint64) (uint64, uint64) { return x/1000000000, x%100000000 }
	// adapted to reduce duplication
	MOVQ	AX, CX
	MOVQ	$1360296554856532783, AX
	MULQ	CX
	ADDQ	CX, DX
	RCRQ	$1, DX
	SHRQ	$29, DX
	MOVQ	DX, sec+0(FP)
	IMULQ	$1000000000, DX
	SUBQ	DX, CX
	MOVL	CX, nsec+8(FP)
	RET
useQPC:
	JMP	runtime·nowQPC(SB)
	RET
```

```go
//go:nosplit
func nowQPC() (sec int64, nsec int32, mono int64) {
	var ft int64
	stdcall1(_GetSystemTimeAsFileTime, uintptr(unsafe.Pointer(&ft)))

	t := (ft - 116444736000000000) * 100

	sec = t / 1000000000
	nsec = int32(t - sec*1000000000)

	mono = nanotimeQPC()
	return
}
```

总结
----------------------
Go 调用 time.Now() 时，会先根据不同操作系统、不同 CPU 架构，去查找不同的系统调用实现。对于 Linux amd64，
会通过汇编直接调用 `vdso_clock_gettime`，如果没有这个系统调用，会降级调用 `vdso_gettimeofday`，不论调用哪一个，
都会返回秒、纳秒数值。对于 Darwin amd64，会通过 libc 调用 `gettimeofday`，对于 Windows amd64，
会调用 `GetSystemTimeAsFileTime`，其他系统与架构，也分别能找到对应实现。最后进行转换并返回。

但我们还没明白几个问题。能解释清楚的大佬，欢迎留言联系我。
1. 操作系统中，系统调用是如何实现的？`clock_gettime` 怎样根据调用的传参，进行怎样的处理并返回？
2. 汇编进行系统调用时，将入参放入 DI 寄存器、最后到 SP 寄存器取结果，用哪个寄存器是在哪约定的？
3. 操作系统中，时间是如何自增的？设置时间时，怎样把时间同步到 BIOS 芯片中？开机时，又是如何读取时间的？
4. 石英钟计时的物理学原理是什么？

--------------------------------------------------------------------------------
下一期
1. Linux 源码中 clock_gettime 的实现
2. 如何实现一个简单的 Linux 系统调用？
3. 硬件时间与计时原理
--------------------------------------------------------------------------------


参考文档
1. Function Declarations https://golang.org/ref/spec#Function_declarations
2. Compiler Directives https://golang.org/pkg/cmd/compile/
3. Build Constraints https://golang.org/cmd/go/#hdr-Build_constraints
4. 《A Quick Guide to Go's Assembler》 https://golang.org/doc/asm
5. 《Go 语言高级编程》 https://cloud.tencent.com/edu/learning/course-2412-38523
    5.1. 《Go 汇编语言 - 函数基本语法》 https://cloud.tencent.com/edu/learning/course-2412-38523
    5.2. 《Go 汇编语言 - 伪寄存器》 https://cloud.tencent.com/edu/learning/course-2412-38485
    5.3. 《Go 汇编语言 - g 结构体》 https://cloud.tencent.com/edu/learning/course-2412-38569
6. 《Go ARM64 vDSO 优化之路》 https://mzh.io/golang-arm64-vdso/
7. 《vDSO - Wikipedia》 https://en.wikipedia.org/wiki/VDSO
8. Syscalls — Linux manual page https://man7.org/linux/man-pages/man2/syscalls.2.html
