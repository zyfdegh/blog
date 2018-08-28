+++
date = "2018-08-28"
title = "[译] 骇我呀：解构一个 ELF 文件"
+++

原文：《hackme: Deconstructing an ELF File》  
作者：Manohar Vanga  
地址：http://manoharvanga.com/hackme/

译者按：在网上搜索 ELF 反汇编资料时，无意中发现本文，浏览了一下，作者的有趣经历，
竟然揭开了困惑我很久的问题：编译在二进制文件中的密码安全吗？如果不，会被怎样破解。
稍复杂的运算逻辑，又如何被反汇编后破译？

于是翻译了这篇文章，与中文阅读者一同学习。

------

朋友最近让我从他写的一个有点难破解的程序中找到密码，我答应了他。几个小时的短暂破解
过程很有趣，最终我得到了密码，于是写下这篇文章记录这过程，同时也谈谈学到的相关新技术。

接受这个挑战的几分钟后，我在邮件收到了一个叫 “hackme” 的二进制文件，开始吧！如果你
有兴趣试试，可以下载这个[二进制文件][hackme-bin]然后回过头来看这篇文章。如果你发现
了我没想到或没留意到的东西，请务必联系我！评论可以发到 manohar.vanga@gmail.com，
标题带有 [hackme]。更新：你可以发送评论到 [Hacker News][hacker-news] 论坛了。

## 尝试运行
我试着运行这个二进制文件并输入一些随机密码。如我所料，都不行，而且打印了一些炒鸡有用的
信息：

```sh
$ ./hackme
Password, please? password
Oops..
```

搞笑的是，在我把这个文件放在 GDB 里运行时，又打了一些特意准备的信息：

```sh
$ $ gdb ./hackme 
Reading symbols from /tmp/hack/hackme...(no
debugging symbols found)...done.
(gdb) r
Starting program: ./hackme 
Fuck off! no debuggers!

Program exited with code 0364.
(gdb) 
```

使用 ptrace 也一样：

```sh
$ strace ./hackme 
execve("./hackme", ["./hackme"], [/* 41 vars */]) = 0
brk(0)                                  = 0x9016000
access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such
file or directory)
... snip ...
ptrace(PTRACE_TRACEME, 0, 0, 0)         = -1 EPERM (Operation
not permitted)
fstat64(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 3), ...})
= 0
mmap2(NULL, 4096, PROT_READ|PROT_WRITE,
MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb783e000
write(1, "Fuck off! no debuggers!\n", 24Fuck off! no debuggers!
) = 24
_exit(2543604)                          = ?
```

## 按套路来

尽管从明文能看到密码的概率几乎为零，我还是试了一下。首先，我检查了这个二进制文件是不是 stripped：
```sh
$ file hackme
hackme: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically
linked (uses shared libs), for GNU/Linux 2.6.27, stripped
```

是 stripped，似乎没办法了。GDB 对解构 stripped 二进制文件的执行逻辑已经没多大用处了。于是我又
试着找找二进制中的字符串，看看能不能万一找到密码：

```sh
$ strings hackme
/lib/ld-linux.so.2
libdl.so.2
__gmon_start__
_Jv_RegisterClasses
dlopen
dlsym
libc.so.6
_IO_stdin_used
__libc_start_main
random
GLIBC_2.1
GLIBC_2.0
PTRh 
QVhE
[^Ph
[^_]
8%':!06!
%!'460
&64;3
%'<;!3
UWVS
[^_]
Fuck off! no debuggers!
Password, please? 
Congratulations!
Oops..
```

我逐一试了上面字符串当作密码，但都不行。没什么太惊人的。不过输出的东西倒是给了成功时的
提示内容：“Congratulations!”。另外还似乎包含字符串 “libc.so.6”。hmm，有点迹象。
用 ltrace 快速看一下这个二进制文件在干什么：

```sh
$ ltrace ./hackme 
__libc_start_main(0x8048645, 1, 0xbfb48a04, 0x80486b0, 0x8048720
<unfinished ...>
dlopen("/lib/libc.so.6", 2)
= 0xb7757ae0
dlsym(0xb7757ae0, "ptrace")
= 0x00eddf40
dlsym(0xb7757ae0, "scanf")
= 0x00e621a0
dlsym(0xb7757ae0, "printf")
= 0x00e5baa0
Fuck off! no debuggers!
+++ exited (status 244) +++
```

给了相同的提示信息，我们能看出这里发生了什么。共享库 libc 被动态加载了，ptrace、scanf 和
printf 的地址也是通过 dlsym 获取的！可恶的玩意！

更麻烦的是，strings 的输出显示了这个二进制文件在使用 random() 函数。不过由于这是个可重现的
程序，也就是说正确密码每次都能解开，那么随机数是没有带种子的。我们下面再考虑这问题。

strings 的输出还解释了二进制文件是如何识别调试环境的。在 ptrace 环境中（比如 strace，ltrace 或 gdb），
调用 ptrace 会返回 -1。

跳过这个调试障碍其实很简单，使用 LD_PRELOAD 环境变量就行了。LD_PRELOAD 变量可以提供一组自定义的
共享库文件，在运行可执行文件时，这比其他共享库都优先执行。这是一条防止进程调用不想要的函数的捷径。
于是我快速写了个新文件，假的 ptrace 函数：

```c
/* fake ptrace() */
#include <stdio.h>

long ptrace(int x, int y, int z)
{
	printf("B-)\n");
	return 0;
}
```

编译它：

```sh
gcc -shared -fPIC -o fake.so fake.c
```

接着在 strace 中运行，设置 LD_PRELOAD 为我们的假库文件。看一下发生了什么：

```sh
$ strace -E LD_PRELOAD=./fake.so ./hackme
execve("./hackme", ["./hackme"], [/* 24 vars */]) = 0
brk(0)                                  = 0x9727000
access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such
file or directory)
mmap2(NULL, 8192, PROT_READ|PROT_WRITE,
MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb78a6000
open("./fake", O_RDONLY)                = 3
read(3,
"\177ELF\1\1\1\0\0\0\0\0\0\0\0\0\3\0\3\0\1\0\0\0\240\3\0\0004\0\0\0"...,
512) = 512
... snip ...
MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb78a1000
write(1, "Password, please? ", 18Password, please? )      = 18
read(0, password
"password\n", 1024)             = 9
write(1, "Oops..\n", 7Oops..
)                 = 7
exit_group(7)                           = ?
```

看起来密码缓冲区大小是 1024 字节长。我可以试着让缓冲溢出，但由于栈的随机性，需要增大到两倍（如果
我没有记错的话，可以关掉）。对于慵懒的周五来说，并不是容易事。更重要的是，我的任务不是破外这程序，
而是找到密码。

看起来我剩余的选择就只有坐下来逆向破解二进制文件了，这并不是周五下午我所想要的。但极客精神战胜了懒惰，
我还是开始反汇编这个二进制文件。

## 反汇编
我从 objdump 的输出开始（继续读，最好开一个新的浏览器标签）：

```sh
$ objdump -D ./hackme > out.asm
```
[out.asm][out-asm]

由于是 stripped 二进制，编译的内容一团糟。我需要快速找到密码加密的逻辑。从前面运行来看，这个逻辑在
打印 “Password, please?” 和 “Oops..” 语句之间。于是我开始在汇编代码中定位这些字符串，然后找到
被使用的地方。字串 “Pa” 是 “Password, please?” 开头的两个字母，它们的十六进制数分别为 50、61。
搜索了汇编文件，快速找到了这两个单词位置：

```sh
$ grep "50 61" objdumpout.txt
 8048798:	00 50 61             	add    %dl,0x61(%eax)
```

这个字符串的地址是 0x8048799（注意第一个字节要被略过），在文件中定位这个地址，找到了下面代码：

```sh
 804859d:       68 99 87 04 08          push   $0x8048799
 80485a2:       ff 15 94 99 04 08       call   *0x8049994
```

棒！意思是 PUSH 字符串的地址到栈（当作文本）再使用这个指针。我可以假定这就是 dlsym 存储的地址，用来
给 printf 打印的变量。

现在我需要找到 “Oops..” 信息，重复上面过程，也找到了这个字符串对应的代码：

```sh
 8048633:       68 c1 87 04 08          push   $0x80487c1
 8048638:       ff d0                   call   *%eax
```

同样我也找到了 “Congratulations!” 对应位置的代码。最终，代码看起来更容易理解了：

```sh
 # The "Password, please?" message is being printed here
 804859d:	68 99 87 04 08       	push   $0x8048799
 80485a2:	ff 15 94 99 04 08    	call   *0x8049994
 80485a8:	8d 45 84             	lea    -0x7c(%ebp),%eax
 ... snip ...
 8048626:	83 ec 0c             	sub    $0xc,%esp
 # The "Congratulations!" message is being printed here
 8048629:	68 af 87 04 08       	push   $0x80487af
 804862e:	eb 08                	jmp    8048638 <dlopen@plt+0x268>
 8048630:	83 ec 0c             	sub    $0xc,%esp
 # The "Oops.." message is being printed here
 8048633:	68 c1 87 04 08       	push   $0x80487c1
 8048638:	ff d0                	call   *%eax
```

然后我快速给汇编文件加了注释（在下方），这样我能记得我的发现：

```sh
 804859d:	68 99 87 04 08       	push   $0x8048799
 80485a2:	ff 15 94 99 04 08    	call   *0x8049994
 # “Password, please?” 信息是在这儿被打印的

 80485a8:	8d 45 84             	lea    -0x7c(%ebp),%eax
 # 这儿可能是密码缓冲区的地址

 80485ab:	5b                   	pop    %ebx
 80485ac:	5e                   	pop    %esi

 80485ad:	50                   	push   %eax
 80485ae:	68 ac 87 04 08       	push   $0x80487ac
 80485b3:	ff 15 90 99 04 08    	call   *0x8049990
 80485b9:	83 c4 10             	add    $0x10,%esp
 # 将密码缓冲区和字符串 "%s" 推到栈上，然后调用 scanf

  80485bc:	31 c0                	xor    %eax,%eax
 # 清空 EAX.

 80485be:	eb 01                	jmp    80485c1 <dlopen@plt+0x1f1>
 80485c0:	40                   	inc    %eax
 80485c1:	80 7c 05 84 00       	cmpb   $0x0,-0x7c(%ebp,%eax,1)
 80485c6:	75 f8                	jne    80485c0 <dlopen@plt+0x1f0>
 # 算出我们输入的密码字符串长度。返回这个值到 EAX。

 80485c8:	31 db                	xor    %ebx,%ebx

 80485ca:	83 f8 13             	cmp    $0x13,%eax
 80485cd:	0f 94 c3             	sete   %bl
 # Hmm！如果 strlen(buf) != 0x13，BL 会被设置为 1！找到了第一个提示！

 80485d0:	be 0a 00 00 00       	mov    $0xa,%esi
 # 移动数字 10 到 ESI。这是循坏的开始，会进行 10 次。

 80485d5:	e8 b6 fd ff ff       	call   8048390 <random@plt>
 # 调用 random()。返回的值存到 EAX

 80485da:	b9 13 00 00 00       	mov    $0x13,%ecx
 80485df:	99                   	cltd
 80485e0:	f7 f9                	idiv   %ecx
 # 将 EAX 中存储的随机数除以 19。EAX 是商，EDX 是余数。

 80485e2:	31 c0                	xor    %eax,%eax
 # 丢掉商

 80485e4:	8a 8a 9c 86 04 08    	mov    0x804869c(%edx),%cl
 # Hmm，这地址看起来像某种查找表。
 # 这个操作大概是 “CL = table[余数]”
 # 既然余数不会大于 19，我将这个地址的前 19 个字节 dump 出来：
 #     0xfb, 0x4c, 0x8d, 0x58, 0x0f, 0xd4, 0xe8, 0x94, 0x98, 0xee,
 #     0x6b, 0x18, 0x30, 0xe0, 0x55, 0xc5, 0x28, 0x0e

 80485ea:	0f b6 7c 15 84       	movzbl -0x7c(%ebp,%edx,1),%edi
 # 这行在做 EDI = password[余数]

 80485ef:	42                   	inc    %edx
 80485f0:	89 95 74 ff ff ff    	mov    %edx,-0x8c(%ebp)
 # 增加余数，并存储到另一个变量

 80485f6:	31 d2                	xor    %edx,%edx
 80485f8:	eb 0c                	jmp    8048606 <dlopen@plt+0x236>
 80485fa:	69 c0 8d 78 01 6d    	imul   $0x6d01788d,%eax,%eax
 8048600:	42                   	inc    %edx
 8048601:	05 39 30 00 00       	add    $0x3039,%eax
 8048606:	3b 95 74 ff ff ff    	cmp    -0x8c(%ebp),%edx
 804860c:	7c ec                	jl     80485fa <dlopen@plt+0x22a>
 # 这是个怪异的循环。看起来像伪随机数生成器。
 # 只要循环计数器小于上面增加过的余数，循环就在跑。
 # 循环体里，执行下面内容（记住上面把 eax 重置为 0）
 #     eax = eax * 0x6d01788d // 按照 Wolfram Alpha，这是个素数
 #     eax += 0x3039 // 12345 的十进制形式
 # 这是个无种子（或种子被设为 0）的伪随机数生成器！不错呀，但并没有意义，因为没设种。

 804860e:	31 f8                	xor    %edi,%eax
 # 用伪随机值和上面存的密码（余数）进行 XOR 指令

 8048610:	38 c1                	cmp    %al,%cl
 # 拿 XOR 后的值的低位字节与 CL 中存的查找表条目比较

 8048612:	b8 00 00 00 00       	mov    $0x0,%eax
 8048617:	0f 45 d8             	cmovne %eax,%ebx
 # 如果 XOR 后的低位字节不等于查找表条目，设置 EBX=0

 804861a:	4e                   	dec    %esi
 804861b:	75 b8                	jne    80485d5 <dlopen@plt+0x205>
 # 减小主循环计数器（那个跑 10 次的），如果还需要迭代就 JUMP

 804861d:	85 db                	test   %ebx,%ebx
 804861f:	a1 94 99 04 08       	mov    0x8049994,%eax
 8048624:	74 0a                	je     8048630 <dlopen@plt+0x260>
 # 最后！如果 EBX 是 0 则跳转到失败信息（略过 congratulations）！
 # 如果 EBX 非零则打印 congratulations 信息！

 8048626:	83 ec 0c             	sub    $0xc,%esp

 # “Congratulations!” 信息在这儿被打印
 8048629:	68 af 87 04 08       	push   $0x80487af
 804862e:	eb 08                	jmp    8048638 <dlopen@plt+0x268>
 8048630:	83 ec 0c             	sub    $0xc,%esp

 # “Oops..” 信息在这儿被打印
 8048633:	68 c1 87 04 08       	push   $0x80487c1
 8048638:	ff d0                	call   *%eax
```

靠！不像我想象的那么糟！将这个逻辑转换为 C 代码，还有测试，耗费了我一阵子，最终结果像
是下面这样：

```c
#include <stdio.h>
#include <string.h>

int main()
{
	int i, j, edi;
	char buf[50], ch;
	char out[50];
	unsigned char check;
	int ret = 0, val, len, rem;
	int magic;
	int k;
	unsigned char arr[] = {0x6a, 0xfb, 0x4c, 0x8d, 0x58, 0x0f, 0xd4, 0xe8,
		0x94, 0x98, 0xee, 0x6b, 0x18, 0x30, 0xe0, 0x55, 0xc5, 0x28,
		0x0e};

	for (i = 0; i < 19; i++)
		out[i] = 'x';
	out[i] = '\0';

	for (i = 10; i > 0; i--) {
		int m2;

		val = random();
		rem = val%19;
		check = arr[rem] & 0xff;
		ch = buf[rem++];

		j = 0;
		magic = 0;
		printf("rem = %d\n", rem);
		while (j < rem) {
			magic *= 1828812941;
			magic += 12345;
			j++;
		}
		m2 = magic;

		magic ^= ch;
		out[rem - 1] = (m2 & 0xff) ^ (check & 0xff));
	}
	printf("Password: %s\n", out);
}
```

来看看编译执行后的输出：

```sh
$ ./decompiled
rem = 3
rem = 16
rem = 4
rem = 4
rem = 11
rem = 9
rem = 11
rem = 12
rem = 3
rem = 8
Password: xxsaxxxpexYoxxxexxx
```

二进制中的循环只跑了 10 次，反复地检查密码中的偏移。密码中重要的字符是那些输出中
**没有**被标记 ‘x’ 的字符（我让我的程序跑的时候设置了这些）。

现在是喜人的时刻！我再次运行最初的程序，并输入这个密码：

```sh
$ ./hackme
Password, please? xxsaxxxpexYoxxxexxx
Congratulations!
```

嘿嘿，有意思。

## 结论
我学到了什么？

### 知汝之器
根据以往的知识和经验，我知道如何用各种各样工具去面对和解决难题。你越是清楚你的工具，
就越能想着解决手头的问题（本例中，是如何逆向找到程序逻辑）。

### 测测水深
我知道破译程序可能不会有什么捷径，但不论怎样，我还是试了所有简单的办法。尽管这些没有给我
很多信息，但在我排除一些选项后，我增加了自信，也清空了后面的障碍。

### 汇编法术
机器指令不太容易反编译，我发现我时而参照 Intel 手册，想搞明白怎么回事。不仅仅是汇编语言
本身，我还真心建议学习 GNU 汇编器的语法。我比较熟悉 Intel 语法（如 NASM），但对 GAS 语法
（AT&T 语法）还不够精通。我找到了[这篇文章][ref-1]和[这一篇][ref-2]，对于快速上手有很大帮助。

对这个程序的一些感谢：

* 检查密码中的少量内容没什么作用，尽管比起检查每个字符要省心一些。（注：原作者告诉我，他将循环次数
设置为 10 试为了调试，然后忘了更改）

* 使用随机数是个很好的方式，让我略微害怕，但到最后，没设种子的随机数是确定的、不变的，这样也不太有用。
加入我写一个 libc 的不同版本，有个不一样的 random() 函数，那程序用真实密码也不能通过了。

* 实际密码是 “SesameOpenYourself!” ！我用了一些无意义的字符去替换，也能正常通过。比如 “NasaJeeperYouShelby”。

总之，一个不错的周五下午～再说一遍哦，评论可以发到 manohar.vanga@gmail.com 并带有 [hackme] 标题。

下载：[所有文件][dl-all]

[hackme-bin]: http://manoharvanga.com/hackme/hackme
[hacker-news]: http://news.ycombinator.com/item?id=2963332
[out-asm]: http://manoharvanga.com/hackme/objdumpout.txt
[ref-1]: http://www.imada.sdu.dk/Courses/DM18/Litteratur/IntelnATT.htm
[ref-2]: http://sig9.com/articles/att-syntax
[dl-all]: http://manoharvanga.com/hackme/hackme_files.tgz