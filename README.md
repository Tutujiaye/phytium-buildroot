# phytium-linux-buildroot
Buildroot是一种简单、高效且易于使用的工具，可以通过交叉编译生成嵌入式Linux系统。Buildroot的用户手册位于docs/manual/manual.pdf。  
phytium-linux-buildroot基于Buildroot，适配了飞腾e2000开发板，支持ubuntu文件系统、debian文件系统、initrd文件系统、buildroot最小文件系统的编译。

# 开发环境
## 系统要求
Buildroot被设计为在Linux系统上运行，我们在ubuntu20.04系统上运行phytium-linux-buildroot。  
需要安装如下软件包：  
`$ sudo apt-get install debootstrap qemu-system-common qemu-user-static binfmt-support`

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
### 编译linux 5.10内核的文件系统
（1）配置defconfig  
配置以下文件系统之一：  
`$ make phytium_e2000_ubuntu_defconfig`  
`$ make phytium_e2000_ubuntu_desktop_defconfig`  
`$ make phytium_e2000_defconfig`  
`$ make phytium_e2000_debian_defconfig`  
`$ make phytium_e2000_debian_desktop_defconfig`  
（2）编译  
`$ make`  
（3）镜像的输出位置  
生成的根文件系统、内核、bootloader位于output/images目录。 

### 编译linux 4.19内核的文件系统
（1）将defconfig和支持linux 4.19内核的config fragment合并：  
`$ ./support/kconfig/merge_config.sh configs/phytium_e2000_xxx_defconfig configs/phytium_e2000_4.19kernel.config`  
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
生成的根文件系统、内核、bootloader位于output/images目录。

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
生成的根文件系统、内核、bootloader位于output/images目录。

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
$ sudo cp xxx/phytium-linux-buildroot/output/images/e2000q-demo-ddr4.dtb /mnt
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
=>ext4load scsi 0:1 0x90000000 e2000q-demo-ddr4.dtb; 
=>booti 0x90100000 - 0x90000000
```
U盘：
```
=>setenv bootargs console=ttyAMA1,115200  audit=0 earlycon=pl011,0x2800d000 root=/dev/sda2 rootdelay=5 rw;
=>usb start
=>ext4load usb 0:1 0x90100000 Image;
=>ext4load usb 0:1 0x90000000 e2000q-demo-ddr4.dtb; 
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
`phytium_e2000_ubuntu_desktop_defconfig`默认安装了kde桌面，配置并编译它就可以获得带kde桌面的
ubuntu系统。如果需要在开发板上安装其他桌面，重新配置并编译`phytium_e2000_ubuntu_defconfig`，
然后在开发板启动这个不带桌面的ubuntu系统：  
### 登录  
ubuntu系统包含了超级用户root，和一个普通用户user，密码和用户名相同。  
如果普通用户下不能使用sudo，需要在root用户下执行`$ chmod u+s /usr/bin/sudo`   
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
linux-headers位于根系统的/usr/src目录，用于在开发板上编译内核模块。  
由于linux-headers是在x86_64主机交叉编译的，直接在开发板使用它来编译内核模块会报错：`/bin/sh: 1: scripts/basic/fixdep: Exec format error`。
因此需要在开发板上本地重新编译scripts：
```
$ cd /usr/src/linux-headers
$ make scripts
```
关于如何编译内核模块，可参考https://www.kernel.org/doc/html/latest/kbuild/modules.html

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
