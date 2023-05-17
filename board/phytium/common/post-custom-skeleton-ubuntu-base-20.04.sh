#!/usr/bin/env bash

distro=focal

trap recover_from_ctrl_c INT

recover_from_ctrl_c()
{
	do_recover_from_error "Interrupt caught ... exiting"
	exit 1
}

do_recover_from_error()
{
	sudo chroot $RFSDIR /bin/umount /proc > /dev/null 2>&1;
	sudo chroot $RFSDIR /bin/umount /sys > /dev/null 2>&1;
	USER=$(id -u); GROUPS=${GROUPS}; \
	sudo chroot $RFSDIR  /bin/chown -R ${USER}:${GROUPS} / > /dev/null 2>&1;
	echo -e "\n************"
    echo $1
	echo -e "  Please running the below commands before re-compiling:"
	echo -e "    rm -rf $RFSDIR"
	echo -e "    make skeleton-custom-dirclean"
	echo -e "  Or\n    make skeleton-custom-dirclean O=<output dir>"
}

do_distrorfs_first_stage() {
# $1: platform architecture, arm64
# $2: rootfs directory, output/build/skeleton-custom
# $3: board/common/ubuntu-additional_packages_list
# $4: focal
# $5: ubuntu

    DISTROTYPE=$5
    [ -z "$RFSDIR" ] && RFSDIR=$2
    [ -z $RFSDIR ] && echo No RootFS exist! && return
    [ -f $RFSDIR/etc/.firststagedone ] && echo $RFSDIR firststage exist! && return
    [ -f /etc/.firststagedone -a ! -f /proc/uptime ] && return

    if [ $1 = arm64 ]; then
	tgtarch=aarch64
    elif [ $1 = armhf ]; then
	tgtarch=arm
    fi

    qemu-${tgtarch}-static -version > /dev/null 2>&1
    if [ "x$?" != "x0" ]; then
        echo qemu-${tgtarch}-static not found
        exit 1
    fi

    debootstrap --version > /dev/null 2>&1
    if [ "x$?" != "x0" ]; then
        echo debootstrap not found
        exit 1
    fi

    mkdir -p $2/usr/local/bin
    cp -f board/phytium/common/ubuntu-package-installer $RFSDIR/usr/local/bin/
    packages_list=board/phytium/common/$3
    [ ! -f $packages_list ] && echo $packages_list not found! && exit 1

    echo additional packages list: $packages_list
    if [ ! -d $RFSDIR/usr/aptpkg ]; then
	mkdir -p $RFSDIR/usr/aptpkg
	cp -f $packages_list $RFSDIR/usr/aptpkg
    fi

    mkdir -p $RFSDIR/etc
    cp -f /etc/resolv.conf $RFSDIR/etc/resolv.conf

    if [ ! -d $RFSDIR/debootstrap ]; then
        echo "testdeboot"
	export LANG=en_US.UTF-8
	sudo debootstrap --arch=$1 --foreign focal $RFSDIR  https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports

	[ $1 != amd64 -a ! -f $RFSDIR/usr/bin/qemu-${tgtarch}-static ] && sudo cp $(which qemu-${tgtarch}-static) $RFSDIR/usr/bin
	echo "installing for second-stage ..."
	DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C \
	sudo chroot $RFSDIR /debootstrap/debootstrap  --second-stage  
	if [ "x$?" != "x0" ]; then
		do_recover_from_error "debootstrap failed in second-stage"
		exit 1
	fi

	echo "configure ... "
	DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C \
	sudo chroot $RFSDIR dpkg --configure -a
    fi

    sudo chroot $RFSDIR ubuntu-package-installer $1 $distro $5 $3 $6 $7
	if [ "x$?" != "x0" ]; then
		 do_recover_from_error "ubuntu-package-installer failed"
		exit 1
	fi

   # sudo chroot $RFSDIR systemctl enable systemd-rootfs-resize
    file_s=$(sudo find $RFSDIR -perm -4000)
    sudo chown -R $USER:$GROUPS $RFSDIR
    for f in $file_s; do
        sudo chmod u+s $f
    done
    sudo chmod u+s $RFSDIR/sbin/unix_chkpwd

    if dpkg-query -l snapd | grep ii 1>/dev/null; then
    	chmod +rw -R $RFSDIR/var/lib/snapd/
    fi

    if [ $distro = focal ]; then
	echo Ubuntu,20.04.1 | tee $RFSDIR/etc/.firststagedone 1>/dev/null
    elif [ $distro = bionic ]; then
	echo Ubuntu,18.04.5 | tee $RFSDIR/etc/.firststagedone 1>/dev/null
    fi
    setup_distribution_info $5 $2 $1

    #rm $RFSDIR/etc/apt/apt.conf
    rm $RFSDIR/dev/* -rf
}

setup_distribution_info () {
    DISTROTYPE=$1
    RFSDIR=$2
    tarch=$3
    distroname=`head -1 $RFSDIR/etc/.firststagedone | cut -d, -f1`
    distroversion=`head -1 $RFSDIR/etc/.firststagedone | cut -d, -f2`
    releaseversion="$distroname (based on $DISTROTYPE-$distroversion-base) ${tarch}"
    releasestamp="Build: `date +'%Y-%m-%d %H:%M:%S'`"
    echo $releaseversion > $RFSDIR/etc/buildinfo
    sed -i "1 a\\$releasestamp" $RFSDIR/etc/buildinfo
    if grep U-Boot $RFSDIR/etc/.firststagedone 1>$RFSDIR/dev/null 2>&1; then
        tail -1 $RFSDIR/etc/.firststagedone >> $RFSDIR/etc/buildinfo
    fi

    if [ $DISTROTYPE = ubuntu ]; then
        echo $distroname $1-$distroversion > $RFSDIR/etc/issue
        echo $distroname $1-$distroversion > $RFSDIR/etc/issue.net

        tgtfile=$RFSDIR/etc/lsb-release
        echo DISTRIB_ID=Phytium > $tgtfile
        echo DISTRIB_RELEASE=$distroversion >> $tgtfile
        echo DISTRIB_CODENAME=$distro >> $tgtfile
        echo DISTRIB_DESCRIPTION=\"$distroname $1-$distroversion\" >> $tgtfile

        tgtfile=$RFSDIR/etc/update-motd.d/00-header
        echo '#!/bin/sh' > $tgtfile
        echo '[ -r /etc/lsb-release ] && . /etc/lsb-release' >> $tgtfile
        echo 'printf "Welcome to %s (%s %s %s)\n" "$DISTRIB_DESCRIPTION" "$(uname -o)" "$(uname -r)" "$(uname -m)"' >> $tgtfile

        tgtfile=$RFSDIR/etc/update-motd.d/10-help-text
        echo '#!/bin/sh' > $tgtfile
        echo 'printf "\n"' >> $tgtfile
        echo 'printf " * Support:        https://www.phytium.com.cn\n"' >> $tgtfile

        tgtfile=$RFSDIR/usr/lib/os-release
        echo NAME=\"$distroname\" > $tgtfile
        echo VERSION=${DISTROTYPE}-$distroversion >> $tgtfile
        echo ID=Ubuntu >> $tgtfile
        echo VERSION_ID=$distroversion >> $tgtfile
	echo PRETTY_NAME=\" Ubuntu Built with Buildroot, based on Ubuntu $distroversion LTS\" >> $tgtfile
	echo VERSION_CODENAME=$distro >> $tgtfile

        rm -f $RFSDIR/etc/default/motd-news
        rm -f $RFSDIR/etc/update-motd.d/50-motd-news
    fi
}

plat_name()
{
	if grep -Eq "^BR2_TARGET_GENERIC_HOSTNAME=\"D2000\"$" ${BR2_CONFIG}; then
		echo "D2000"
	elif grep -Eq "^BR2_TARGET_GENERIC_HOSTNAME=\"E2000\"$" ${BR2_CONFIG}; then
		echo "E2000"
	fi
}

arch_type()
{
	if grep -Eq "^BR2_aarch64=y$" ${BR2_CONFIG}; then
		echo "arm64"
	elif grep -Eq "^BR2_arm=y$" ${BR2_CONFIG}; then
		echo "armhf"
	fi
}

full_rtf()
{
	if grep -Eq "^BR2_PACKAGE_ROOTFS_DESKTOP=y$" ${BR2_CONFIG}; then
		echo "desktop"
	else
		echo "base"
	fi
}

deploy_kernel_headers_510 () {
	pdir=$1
	version=$2
	srctree=$pdir/lib/modules/$version/source
	objtree=$pdir/lib/modules/$version/build
	cd $objtree
	mkdir debian

	(
		cd $srctree
		find . arch/arm64 -maxdepth 1 -name Makefile\*
		find include scripts -type f -o -type l
		find arch/arm64 -name Kbuild.platforms -o -name Platform
		find $(find arch/arm64 -name include -o -name scripts -type d) -type f
	) > debian/hdrsrcfiles

	{
		if grep -q "^CONFIG_STACK_VALIDATION=y" include/config/auto.conf; then
			echo tools/objtool/objtool
		fi

		find arch/arm64/include Module.symvers include scripts -type f

		if grep -q "^CONFIG_GCC_PLUGINS=y" include/config/auto.conf; then
			find scripts/gcc-plugins -name \*.so
		fi
	} > debian/hdrobjfiles

	destdir=$pdir/usr/src/linux-headers-$version
	mkdir -p $destdir
	tar -c -f - -C $srctree -T debian/hdrsrcfiles | tar -xf - -C $destdir
	tar -c -f - -T debian/hdrobjfiles | tar -xf - -C $destdir
	rm -rf debian

	# copy .config manually to be where it's expected to be
	cp .config $destdir/.config
	find $destdir -name "*.o" -type f -exec rm -rf {} \;
	cd $pdir
	cd ../..
	# cp -r board/phytium/common/linux-5.10/scripts $destdir

	rm -rf $srctree
	rm -rf $objtree
	ln -s /usr/src/linux-headers-$version $pdir/lib/modules/$version/build
}

deploy_kernel_headers_419 () {
	pdir=$1
	version=$2
	srctree=$pdir/lib/modules/$version/source
	objtree=$pdir/lib/modules/$version/build
	cd $objtree
	mkdir debian

	(cd $srctree; find . -name Makefile\* -o -name Kconfig\* -o -name \*.pl) > "$objtree/debian/hdrsrcfiles"
	(cd $srctree; find arch/*/include include scripts -type f -o -type l) >> "$objtree/debian/hdrsrcfiles"
	(cd $srctree; find arch/arm64 -name module.lds -o -name Kbuild.platforms -o -name Platform) >> "$objtree/debian/hdrsrcfiles"
	(cd $srctree; find $(find arch/arm64 -name include -o -name scripts -type d) -type f) >> "$objtree/debian/hdrsrcfiles"
	if grep -q '^CONFIG_STACK_VALIDATION=y' .config ; then
		(cd $objtree; find tools/objtool -type f -executable) >> "$objtree/debian/hdrobjfiles"
	fi
	(cd $objtree; find arch/arm64/include Module.symvers include scripts -type f) >> "$objtree/debian/hdrobjfiles"
	if grep -q '^CONFIG_GCC_PLUGINS=y' .config ; then
		(cd $objtree; find scripts/gcc-plugins -name \*.so -o -name gcc-common.h) >> "$objtree/debian/hdrobjfiles"
	fi
	destdir=$pdir/usr/src/linux-headers-$version
	mkdir -p "$destdir"
	(cd $srctree; tar -c -f - -T -) < "$objtree/debian/hdrsrcfiles" | (cd $destdir; tar -xf -)
	(cd $objtree; tar -c -f - -T -) < "$objtree/debian/hdrobjfiles" | (cd $destdir; tar -xf -)
	(cd $objtree; cp .config $destdir/.config) # copy .config manually to be where it's expected to be
	(cd $srctree; cp --parents tools/include/tools/be_byteshift.h $destdir)
	(cd $srctree; cp --parents tools/include/tools/le_byteshift.h $destdir)
	find $destdir -name "*.o" -type f -exec rm -rf {} \;
	cd $pdir
	cd ../..
	# cp -r board/phytium/common/linux-4.19/scripts $destdir
	rm -rf "$objtree/debian"

	rm -rf $srctree
	rm -rf $objtree
	ln -sf "/usr/src/linux-headers-$version" "$pdir/lib/modules/$version/build"
}

main()
{
	# $1 - the current rootfs directory, skeleton-custom or target
	rm -rf $1/*

	# run first stage do_distrorfs_first_stage arm64 ${1} ubuntu-additional_packages_list focal ubuntu
	do_distrorfs_first_stage $(arch_type) ${1} ubuntu-additional_packages_list focal ubuntu $(plat_name) $(full_rtf)

	# change the hostname to "platforms-Ubuntu"
	echo $(plat_name)-Ubuntu > ${1}/etc/hostname

	if [ $distro = focal ]; then
		sed -i "s/float(n\[0\])/float(n[0].split()[0])/" ${1}/usr/share/pyshared/lsb_release.py
	fi

	if [ ! -d $1/lib/modules ]; then
		make linux-rebuild ${O:+O=$O}
	fi

	KERNELVERSION=`ls $1/lib/modules`
	if grep -Eq "^BR2_ROOTFS_LINUX_HEADERS=y$" ${BR2_CONFIG}; then
		if [[ ${KERNELVERSION} = 5.10* ]];then
			deploy_kernel_headers_510 $1 ${KERNELVERSION}
		elif [[ ${KERNELVERSION} = 4.19* ]];then
			deploy_kernel_headers_419 $1 ${KERNELVERSION}
		else
			echo "error: linux kernel version is neither 4.19 nor 5.10."
		fi
	fi

        if grep -Eq "^BR2_PACKAGE_XORG_ROGUE_UMLIBS=y$" ${BR2_CONFIG}; then
                make xorg-rogue-umlibs-rebuild ${O:+O=$O}
        fi

	if grep -Eq "^BR2_ROOTFS_CHOWN=y$" ${BR2_CONFIG}; then
                make rootfs-chown-rebuild ${O:+O=$O}
		sudo chroot ${1} systemctl enable systemd-rootfs-chown.service
        fi

	if grep -Eq "^BR2_PACKAGE_VPU_LIB=y$" ${BR2_CONFIG}; then
                make vpu-lib-rebuild ${O:+O=$O}
        fi

	if grep -Eq "^BR2_PACKAGE_FFMPEG=y$" ${BR2_CONFIG}; then
                make ffmpeg-rebuild ${O:+O=$O}
        fi

	if grep -Eq "^BR2_PACKAGE_PHYTIUM_OPTEE=y$" ${BR2_CONFIG}; then
		make phytium-optee-rebuild ${O:+O=$O}
		# add tee-supplicant systemd service
		cp -dpf package/phytium-optee/phytium-tee-supplicant.service $RFSDIR/lib/systemd/system/phytium-tee-supplicant.service
		# default set start tee-supplicant
		ln -sf /lib/systemd/system/phytium-tee-supplicant.service $RFSDIR/etc/systemd/system/sysinit.target.wants/phytium-tee-supplicant.service
	fi

	exit $?
}

main $@
