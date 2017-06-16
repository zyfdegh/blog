+++
date = "2017-06-02"
title = "Evernote 笔记整理 - Linux 中一些小技巧与细节优化"
+++

# 一些小技巧

## vi 显示 / 取消行号
:set nu

:set nonu

## cat 显示行号
cat -b file

cat -n file （包括空行）

## grep 显示前后 5 行
grep -C 5 xxx

## 光标移动
移动到行首「CTRL + A」

移动单词 「CTRL + LEFT/RIGHT」

清空一行 「CTRL + U」 

## 统计行数
ps | wc -l

## 查看目录占用空间
du -sh folder

按大小排序

du -sh folder | sort -nr

## 命令历史设置

### 添加时间、用户名
echo 'export HISTTIMEFORMAT="%F %T `whoami` "'>> /etc/profile
source /etc/profile

### 设置记录最大条数
编辑 / etc/profile 设置 HISTSIZE 值为 10000

## top 使用
top -p 1234 查看某个进程

top -o %MEM 按内存排序

## 删除变量

unset MARATHON_ADDRESS

## 设置代理

export http_proxy=http://127.0.0.1:1080

export https_proxy=http://127.0.0.1:1080

## 创建 swap

创建并启用一个 2048M 的 SWAP 文件
```sh
dd if=/dev/zero of=/swapfile bs=1024k count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

## sleep 无限时间
sleep infinity

## 启动一个 File server
快速启动一个类似于 Nginx 的 server，并将当前目录共享到 Web

python -m SimpleHTTPServer 80

## 输出格式化的 JSON

echo '{"foo":"lorem","bar":"ipsum"}' | python -m json.tool

或者

yum install -y yajl

echo '{"foo":"lorem","bar":"ipsum"}' | json_reformat

或者

echo '{"foo":"lorem","bar":"ipsum"}' | jq


# 一些小工具
## 彩色的 diff
安装 colordiff

## 彩色的 cat
安装 ccat

直接安装
```sh
go get -u github.com/jingweno/ccat
```

源码见 GitHub： [jingweno/ccat][ccat]


## 彩色的 grep
grep --color=auto

[ccat]: https://github.com/jingweno/ccat
