+++
date = "2017-06-09"
title = "Evernote 笔记整理 - Linux 多种格式压缩与解压"
+++

Linux 中文件打包、与解包，压缩与解压，多种压缩类型。

# ZIP

**压缩**

zip -r archive_name.zip directory_to_compress

**解压**

unzip archive_name.zip

# TAR
**打包**

tar -cvf archive_name.tar directory_to_compress

**解包**

tar -xvf archive_name.tar.gz

解压到指定路径

tar -xvf archive_name.tar -C /tmp/extract_here/


# TAR.GZ

**压缩**

tar -czvf archive_name.tar.gz directory_to_compress

**查看内容**

tar -tzvf archive_name.tar.gz

**解压**

tar -xzvf archive_name.tar.gz

**提取单个文件**

tar -zxf archive_name.tar.gz path/to/file

**解压到指定路径**

tar -xzvf archive_name.tar.gz -C /tmp/extract_here

# TAR.BZ2
**压缩**

tar -jcvf archive_name.tar.bz2 directory_to_compress

**解压**

tar -jxvf archive_name.tar.bz2 -C /tmp/extract_here/

# TAR.XZ
**压缩**

tar -cJf archive_name.tar.xz directory_to_compress

**解压**

tar -xpvf archive_name.tar.xz

# GZ
**压缩**

gzip –c filename > filename.gz 

**解压**

gunzip –c filename.gz > filename

# 7z
安装 p7zip, p7zip-plugins

**压缩**

7za a archive_name.7z files/

**解压**

7za e archive_name.7z 

# CPIO
适用于 ASCII cpio archive 文件

cpio -ivdum < /boot/initramfs-3.10.0-327.4.4.el7.x86_64.img

# RAR
安装 unrar

**压缩**

unrar e file.rar

**解压**

unrar x file.rar

# TGZ
同 TAR.GZ 文件