+++
date = "2017-06-09"
title = "Evernote 笔记整理 - CentOS 中 yum 的使用"
+++

# 安装软件
yum -y install package_name

# 更改源
修改 / etc/yum.repos.d/ 下面的 CentOS-Base.repo

## 更改 CentOS 源为 163 的

```sh
# 进入存放源配置的文件夹
cd /etc/yum.repos.d

# 备份默认源
mv ./CentOS-Base.repo ./CentOS-Base.repo.bak

# 使用 wget 下载 163 的源
# http://mirrors.163.com/.help/centos.html
wget http://mirrors.163.com/.help/CentOS6-Base-163.repo

# 把下载下来的文件 CentOS-Base-163.repo 设置为默认源
mv CentOS6-Base-163.repo CentOS-Base.repo

# 运行 yum makecache 生成缓存
yum makecache
```

# 更新缓存
yum makecache fast

# 查看 yum 日志
cat /var/log/yum.log

# 删除包
yum remove pkg_name

或者

yum erase pkg_name

# 添加源
 rpm -vih http://rpm.livna.org/livna-release-5.rpm 

# 列出已安装
rpm -qa

或者
yum list installed（较慢）

# 显示一个包详细信息
yum info pkg_name

# 搜索一个提供某命令的包
yum provides jq

# 安装一个 rpm 文件及其依赖
yum install *.rpm

# 删除多余 kernels
yum install yum-utils

只保留 3 个较新的

package-cleanup --oldkernels --count=3
