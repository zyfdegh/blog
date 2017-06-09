+++
date = "2017-06-09"
title = "Evernote 笔记整理 - Linux 中安全设置"
+++


# 禁止密码登录
**禁用前先添加公钥**

```sh
vi /etc/ssh/sshd_config

# 查找并修改下面两项
PasswordAuthentication no  # 禁止使用基于口令认证的方式登陆
PubkeyAuthentication yes  # 允许使用基于密钥认证的方式登陆

systemctl restart sshd
```

# 禁止ping
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all

恢复
echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_all
