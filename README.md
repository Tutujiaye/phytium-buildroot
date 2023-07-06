# phytium-linux-buildroot
Buildroot是一种简单、高效且易于使用的工具，可以通过交叉编译生成嵌入式Linux系统。Buildroot的用户手册位于docs/manual/manual.pdf。  
phytium-linux-buildroot基于Buildroot，适配了飞腾e2000、d2000开发板，支持ubuntu文件系统、debian文件系统、initrd文件系统、buildroot最小文件系统的编译。

# 开发环境
## 系统要求
Buildroot被设计为在Linux系统上运行，我们只支持在ubuntu20.04、ubuntu22.04、debian11这三种主机系统上运行phytium-linux-buildroot，不支持其他系统。
首先，Buildroot需要主机系统上安装如下Linux程序，请检查是否已安装：
```
• Build tools:
– which
– sed
– make (version 3.81 or any later)
– binutils
– build-essential (only for Debian based systems)
– gcc (version 4.8 or any later)
– g++ (version 4.8 or any later)
– bash
– patch
– gzip
– bzip2
– perl (version 5.8.7 or any later)
– tar
– cpio
– unzip
– rsync
– file (must be in /usr/bin/file)
– bc
• Source fetching tools:
– wget
– git
```
除此之外，还需要安装如下软件包：  
`$ sudo apt install debootstrap qemu-user-static binfmt-support debian-archive-keyring`  
对于debian11系统，需要设置PATH环境变量：`PATH=$PATH:/usr/sbin`  

## 下载phytium-linux-buildroot
`$ git clone https://gitee.com/phytium_embedded/phytium-linux-buildroot.git`

# 查看支持的defconfig
为飞腾CPU平台构建的文件系统的配置文件位于configs目录。  
在phytium-linux-buildroot根目录下执行`$ make list-defconfigs`，返回configs目录中的defconfig配置文件。  
```
$ cd xxx/phytium-linux-buildroot
$ make list-defconfigs
```
其中以phytium开头的为飞腾相关的defconfig配置文件，包含：  
```
phytium_d2000_debian_defconfig      - Build for phytium_d2000_debian
phytium_d2000_debian_desktop_defconfig - Build for phytium_d2000_debian_desktop
phytium_d2000_defconfig             - Build for phytium_d2000
phytium_d2000_ubuntu_defconfig      - Build for phytium_d2000_ubuntu
phytium_e2000_debian_defconfig      - Build for phytium_e2000_debian
phytium_e2000_debian_desktop_defconfig - Build for phytium_e2000_debian_desktop
phytium_e2000_defconfig             - Build for phytium_e2000
phytium_e2000_ubuntu_defconfig      - Build for phytium_e2000_ubuntu
phytium_e2000_ubuntu_desktop_defconfig - Build for phytium_e2000_ubuntu_desktop
phytium_initrd_defconfig            - Build for phytium_initrd
```

# 编译文件系统
## 为e2000编译文件系统
### 编译默认配置的文件系统
（1）加载defconfig   
`$ make phytium_e2000_xxx_defconfig`  
其中`phytium_e2000_xxx_defconfig`为以下文件系统之一：
```
phytium_e2000_ubuntu_defconfig
phytium_e2000_ubuntu_desktop_defconfig
phytium_e2000_defconfig
phytium_e2000_debian_defconfig
phytium_e2000_debian_desktop_defconfig
```  
（2）编译  
`$ make`  
（3）镜像的输出位置  
生成的根文件系统、内核位于output/images目录。 

### 更换文件系统的linux内核版本
defconfig中的内核版本默认是linux 5.10。我们支持在编译文件系统时将内核版本更换为linux 4.19，linux 4.19 rt，linux 5.10 rt。
关于e2000 linux内核的信息请参考：`https://gitee.com/phytium_embedded/phytium-linux-kernel`  
更换内核版本的操作步骤为：  
（1）使用phytium_e2000_xxx_defconfig作为基础配置项，合并支持其他内核版本的配置：  
`$ ./support/kconfig/merge_config.sh configs/phytium_e2000_xxx_defconfig configs/phytium_e2000_linux_xxx.config`  
其中`configs/phytium_e2000_linux_xxx.config`为以下配置片段文件之一：
```
configs/phytium_e2000_linux_4.19.config
configs/phytium_e2000_linux_4.19_rt.config
configs/phytium_e2000_linux_5.10_rt.config
```
这三个文件分别对应于linux 4.19，linux 4.19 rt，linux 5.10 rt内核。  
（2）编译  
`$ make`  
（3）镜像的输出位置  
生成的根文件系统、内核位于output/images目录。

### 支持Phytium-optee
本项目还支持编译Phytium-optee，关于Phytium-optee的信息请参考：`https://gitee.com/phytium_embedded/phytium-optee`  
defconfig默认不编译Phytium-optee，如果需要编译Phytium-optee请执行：  
（1）使用phytium_e2000_xxx_defconfig作为基础配置项，合并支持optee的配置：  
`$ ./support/kconfig/merge_config.sh configs/phytium_e2000_xxx_defconfig configs/phytium_e2000_optee.config`  
目前Phytium-optee支持的开发板有e2000d demo、e2000q demo，默认配置为e2000d demo。如果需要更改，请将
`configs/phytium_e2000_optee.config`中`BR2_PACKAGE_PHYTIUM_OPTEE_BOARD`变量的值修改为`"e2000qdemo"`。  
注意：phytium-linux-buildroot的最新代码已包含了Phytium-optee的依赖，如果您使用的phytium-linux-buildroot不是最新版本，
在执行编译之前需要额外安装依赖：  
```
sudo apt install python3-pip
pip install pycryptodome
pip install pyelftools
pip install cryptography
```
（2）编译  
`$ make`  
（3）镜像的输出位置  
生成的根文件系统、内核、TEE OS位于output/images目录。  
后续部署及使用方法，请参考`https://gitee.com/phytium_embedded/phytium-embedded-docs/tree/master/optee`

## 清理编译结果
（1）`$ make clean`  
删除所有编译结果，包括output目录下的所有内容。当编译完一个文件系统后，编译另一个文件系统前，需要执行此命令。  
（2）`$ make distclean`  
重置buildroot，删除所有编译结果、下载目录以及配置。  

## 为d2000编译文件系统
（1）在phytium-linux-buildroot的根目录下创建files目录，将内核源码拷贝到files目录并重命名为linux-4.19.tar.gz  
`$ mkdir files`  
`$ cp xxx/linux-4.19-master.tar.gz files/linux-4.19.tar.gz`  
（2）计算内核源码的哈希值  
```
$ sha256sum files/linux-4.19.tar.gz
22a2345f656b0624790dcbb4b5884827c915aef00986052fd8d9677b9ee6b50e  files/linux-4.19.tar.gz
```
编辑linux/linux.hash文件，将linux-4.19.tar.gz对应行的哈希值修改为刚刚计算的哈希值，如下所示：  
`sha256  22a2345f656b0624790dcbb4b5884827c915aef00986052fd8d9677b9ee6b50e  linux-4.19.tar.gz`  
注意：每次更新files目录里面的内核源码，都需要同时修改linux/linux.hash里面内核源码对应的哈希值，这是为了验证files目录中的文件与dl目录中的文件一致。  
（3）配置及编译initrd  
```
$ make phytium_initrd_defconfig 
$ make 
```
（4）将编译好的initrd备份保存  
`$ cp xxx/phytium-linux-buildroot/output/images/rootfs.cpio.gz ~/initrd`  
（5）清理编译结果  
`$ make clean`  
（6）配置以下文件系统之一：  
`$ make phytium_d2000_ubuntu_defconfig`  
`$ make phytium_d2000_defconfig`  
`$ make phytium_d2000_debian_defconfig`  
`$ make phytium_d2000_debian_desktop_defconfig`  
（7）编译文件系统  
`$ make`  
（8）镜像的输出位置  
生成的根文件系统、内核位于output/images目录。

# 在开发板上启动文件系统
## 在e2000开发板上启动文件系统
### 使用U-Boot启动文件系统
（1）主机端将SATA盘或U盘分成两个分区（以主机识别设备名为/dev/sdb 为例，请按实际识别设备名更改）  
`$ sudo fdisk /dev/sdb`  

（2）主机端将内核和设备树拷贝到第一个分区，将根文件系统拷贝到第二个分区
```
$ sudo mkfs.ext4 /dev/sdb1
$ sudo mkfs.ext4 /dev/sdb2
$ sudo mount /dev/sdb1 /mnt
$ sudo cp xxx/phytium-linux-buildroot/output/images/Image /mnt
$ sudo cp xxx/phytium-linux-buildroot/output/images/e2000q-demo-board.dtb /mnt
$ sync
$ sudo umount /dev/sdb1
$ sudo mount /dev/sdb2 /mnt
$ sudo cp xxx/phytium-linux-buildroot/output/images/rootfs.tar /mnt
$ cd /mnt
$ sudo tar xvf rootfs.tar
$ sync
$ cd ~
$ sudo umount /dev/sdb2
```

（3）SATA盘或U盘接到开发板，启动开发板电源，串口输出U-Boot命令行，设置U-Boot环境变量，启动文件系统  
SATA盘：  
```
=>setenv bootargs console=ttyAMA1,115200  audit=0 earlycon=pl011,0x2800d000 root=/dev/sda2 rw; 
=>ext4load scsi 0:1 0x90100000 Image;
=>ext4load scsi 0:1 0x90000000 e2000q-demo-board.dtb;
=>booti 0x90100000 - 0x90000000
```
U盘：
```
=>setenv bootargs console=ttyAMA1,115200  audit=0 earlycon=pl011,0x2800d000 root=/dev/sda2 rootdelay=5 rw;
=>usb start
=>ext4load usb 0:1 0x90100000 Image;
=>ext4load usb 0:1 0x90000000 e2000q-demo-board.dtb;
=>booti 0x90100000 - 0x90000000
```

## 在d2000开发板上启动文件系统
### 使用U-Boot启动文件系统
（1）主机端将SATA盘或U盘分成两个分区（以主机识别设备名为/dev/sdb 为例，请按实际识别设备名更改）  
`$ sudo fdisk /dev/sdb`  

（2）主机端将内核、设备树和initrd拷贝到第一个分区，将根文件系统拷贝到第二个分区
```
$ sudo mkfs.ext4 /dev/sdb1
$ sudo mkfs.ext4 /dev/sdb2
$ sudo mount /dev/sdb1 /mnt
$ sudo cp xxx/phytium-linux-buildroot/output/images/Image /mnt
$ sudo cp xxx/phytium-linux-buildroot/output/images/d2000-devboard-dsk.dtb /mnt
$ sudo cp ~/initrd /mnt
$ sync
$ sudo umount /dev/sdb1
$ sudo mount /dev/sdb2 /mnt
$ sudo cp xxx/phytium-linux-buildroot/output/images/rootfs.tar /mnt
$ cd /mnt
$ sudo tar xvf rootfs.tar
$ sync
$ cd ~
$ sudo umount /dev/sdb2
```

（3）SATA盘或U盘接到开发板，启动开发板电源，串口输出U-Boot命令行，设置U-Boot环境变量，启动文件系统  
SATA盘：  
```
=>setenv bootargs console=ttyAMA1,115200 earlycon=pl011,0x28001000 root=/dev/sda2 rootdelay=5 rw initrd=0x93000000,85M
=>ext4load scsi 0:1 0x90100000 d2000-devboard-dsk.dtb
=>ext4load scsi 0:1 0x90200000 Image
=>ext4load scsi 0:1 0x93000000 initrd
=>booti 0x90200000 - 0x90100000
```
U盘：
```
=>setenv bootargs console=ttyAMA1,115200 earlycon=pl011,0x28001000 root=/dev/sda2 rootdelay=5 rw initrd=0x93000000,85M
=>usb start
=>ext4load usb 0:1 0x90100000 d2000-devboard-dsk.dtb
=>ext4load usb 0:1 0x90200000 Image
=>ext4load usb 0:1 0x93000000 initrd
=>booti 0x90200000 - 0x90100000
```

# ubuntu系统安装桌面
## e2000 ubuntu系统安装桌面
`phytium_e2000_ubuntu_desktop_defconfig`默认安装了xfce桌面，配置并编译它就可以获得带xfce桌面的
ubuntu系统。如果需要在开发板上安装其他桌面，重新配置并编译`phytium_e2000_ubuntu_defconfig`，
然后在开发板启动这个不带桌面的ubuntu系统：  
### 登录  
ubuntu系统包含了超级用户root，和一个普通用户user，密码和用户名相同。   
### 动态获取 IP 地址 
```
$ sudo dhclient
$ ping www.baidu.com
```
### 安装桌面
#### 安装GNOME桌面
```
$ sudo apt update
$ sudo apt -y install ubuntu-gnome-desktop
```
#### 安装KDE桌面
```
$ sudo apt update
$ sudo apt -y install kubuntu-desktop
```

#### 安装XFCE桌面
```
$ sudo apt update
$ sudo apt -y install xfce4 xfce4-terminal
在安装过程中，它会要求你选择显示管理器是gdm3还是lightdm，这里选择的是lightdm。  
安装完成后重启系统，在图形登录界面点击用户名右边的ubuntu logo按钮，选择桌面环境为“Xfce Session”，输入密码登录。
```

## d2000 ubuntu系统安装桌面
`phytium_d2000_ubuntu_defconfig`默认不安装桌面，如果需要安装桌面：  
（1）编辑`phytium_d2000_ubuntu_defconfig`，将`#BR2_PACKAGE_ROOTFS_DESKTOP=y`取消注释  
（2）重新配置并编译`phytium_d2000_ubuntu_defconfig`  
```
$ make phytium_d2000_ubuntu_defconfig
$ make
```

# ubuntu及debian系统支持linux-headers
linux-headers包含构建内核外部模块所需的头文件，编译ubuntu和debian的defconfig会生成linux-headers。  
关于如何编译内核外部模块，可参考https://www.kernel.org/doc/html/latest/kbuild/modules.html  

## 交叉编译内核模块
编译ubuntu和debian的defconfig，会在`output/target/usr/src`目录中安装linux-headers-version。   
使用buildroot的工具链来交叉编译内核模块，buildroot工具链位于`output/host/bin`，工具链的sysroot为
`output/host/aarch64-buildroot-linux-gnu/sysroot`。  

交叉编译内核外部模块的命令为：
```
$ make ARCH=arm64 \
CROSS_COMPILE=/home/xxx/phytium-linux-buildroot/output/host/bin/aarch64-none-linux-gnu- \
-C /home/xxx/phytium-linux-buildroot/output/target/usr/src/linux-headers-5.10.153-phytium-embeded \
M=$PWD \
modules
```

## 开发板上编译内核模块
buildroot将linux-headers-version安装在根文件系统的`/usr/src`目录下，
并为它创建了一个软链接`/lib/modules/version/build`。  
注意，由于linux-headers是在x86-64主机交叉编译生成的，在开发板上直接使用它编译内核模块会报错：  
`/bin/sh: 1: scripts/basic/fixdep: Exec format error`。  
因此，需要将x86-64格式的fixdep等文件替换为ARM aarch64格式的（以linux 5.10内核为例）：  
（1）`scp -r username@host:/home/xxx/phytium-linux-buildroot/board/phytium/common/linux-5.10/scripts /usr/src/linux-headers-5.10.153-phytium-embeded`  
（2）或者在编译ubuntu和debian的defconfig之前，将board/phytium/common/post-custom-skeleton-ubuntu-base-20.04.sh和
board/phytium/common/post-custom-skeleton-debian-base-11.sh中的如下两行取消注释，再执行编译。  
`# cp -r board/phytium/common/linux-5.10/scripts $destdir`  
`# cp -r board/phytium/common/linux-4.19/scripts $destdir`  

在开发板上编译内核外部模块的命令为：  
`make -C /lib/modules/5.10.153-phytium-embeded/build M=$PWD modules`

# buildroot编译新的应用软件
本节简单介绍如何通过buildroot交叉编译能运行在开发板上的应用软件，完整的教程请参考buildroot用户手册manual.pdf。  
## buildroot软件包介绍
buildroot中所有用户态的软件包都在package目录，每个软件包有自己的目录`package/<pkg>`，其中`<pkg>`是小写的软件包名。这个目录包含：  
（1）`Config.in`文件，用Kconfig语言编写，描述了包的配置选项。  
（2）`<pkg>.mk`文件，用make编写，描述了包如何构建，即从哪里获取源码，如何编译和安装等。  
（3）`<pkg>.hash`文件，提供hash值，检查下载文件的完整性，如检查下载的软件包源码是否完整，这个文件是可选的。  
（4）`*.patch`文件，在编译之前应用于源码的补丁文件，这个文件是可选的。  
（5）可能对包有用的其他文件。
## 编写buildroot软件包
首先创建软件包的目录`package/<pkg>`，然后编写该软件包中的文件。  
buildroot中的软件包基本上由`Config.in`和`<pkg>.mk`两个文件组成。关于如何编写这两个文件，大家可以参考`package/<vpu-lib>`和
buildroot用户手册，这里简单概括一下。  
（1）`Config.in`文件中必须包含启用或禁用该包的选项，而且必须命名为`BR2_PACKAGE_<PKG>`，其中`<PKG>`是大写的软件包名，这个选项的值是布尔类型。
也可以定义其他功能选项来进一步配置该软件包。然后还必须在`package/Config.in`文件中包含该文件：  
`source "package/<pkg>/Config.in"`  
（2）`<pkg>.mk`文件看起来不像普通的Makefile文件，而是一连串的变量定义，而且必须以大写的包名作为变量的前缀。最后以调用软件包的基础结构（package
infrastructure）结束。变量告诉软件包的基础结构要做什么。  
对于使用手写Makefile来编译的软件源码，在`<pkg>.mk`中调用generic-package基础结构。generic-package基础结构实现了包的下载、提取、打补丁。
而配置、编译和安装由`<pkg>.mk`文件描述。`<pkg>.mk`文件中可以设置的变量及其含义，请参考buildroot用户手册。  
## 编译软件包 
（1）单独编译软件包
```
$ cd xxx/phytium-linux-buildroot
$ make <pkg>
```
编译结果在`output/build/<pkg>-<version>`  

（2）将软件包编译进根文件系统
```
在phytium_xxx_defconfig中添加一行BR2_PACKAGE_<PKG>=y
$ make phytium_xxx_defconfig
$ make
```

# FAQ
1. Ubuntu文件系统桌面无法登陆问题?
```
文件系统启动后控制台下apt install kubuntu-desktop    
检查/home/user权限是否为user  
chown -R user:user /home/user
重新启动开发板子
```

2. 播放音频没有声音？  
```
将user用户加入audio组，可解决user用户下没声音的问题
gpasswd -a user audio
```

3. 下载ubuntu及debian太慢或报错？  
目前下载ubuntu及debian的源为清华大学镜像，如果遇到下载很慢，或者下载报错：
`E: Unable to fetch some archives, maybe run apt-get update or try with --fix-missing?`
从而导致编译的phytium_e2000_debian_desktop_defconfig或phytium_e2000_ubuntu_desktop_defconfig没有桌面问题，
请将清华源更换为中科大源，即将以下文件
```
board/phytium/common/post-custom-skeleton-ubuntu-base-20.04.sh
board/phytium/common/ubuntu-package-installer
board/phytium/common/post-custom-skeleton-debian-base-11.sh
board/phytium/common/debian-package-installer
```
中的`mirrors.tuna.tsinghua.edu.cn`改为`mirrors.ustc.edu.cn`

4. 编译内核时报错`Can't find default configuration "arch/arm64/configs/phytium_defconfig"!`  
需要删除dl目录中的内核源码，再重新编译：  
```
rm -rf dl/linux/
make linux-dirclean
make
```
