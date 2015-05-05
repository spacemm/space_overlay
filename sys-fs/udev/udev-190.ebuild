# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="https://bitbucket.org/braindamaged/udev.git"
	EGIT_HAS_SUBMODULES="0"
	
	inherit git-2 
else
	SRC_URI="https://bitbucket.org/braindamaged/udev/downloads/udev-${PV}.tar.gz"
fi

inherit autotools eutils linux-info toolchain-funcs

DESCRIPTION="Linux dynamic and persistent device naming support (aka userspace devfs)"
HOMEPAGE="https://bitbucket.org/braindamaged/udev"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="doc debug gudev hwdb introspection keymap floppy +openrc selinux static-libs"

RESTRICT="test"

# Required kernel version
KV_MIN="2.6.39"

COMMON_DEPEND="gudev? ( dev-libs/glib:2 )
	introspection? ( >=dev-libs/gobject-introspection-1.31.1 )
	selinux? ( sys-libs/libselinux )
	>=sys-apps/kmod-5
	>=sys-apps/util-linux-2.20
	!<sys-libs/glibc-2.12"

DEPEND="${COMMON_DEPEND}
	dev-util/gperf
	>=dev-util/intltool-0.40.0
	virtual/pkgconfig
	virtual/os-headers
	!<sys-kernel/linux-headers-${KV_MIN}
	doc? ( app-doc/doxygen )
	app-text/docbook-xsl-stylesheets
	dev-libs/libxslt"

RDEPEND="${COMMON_DEPEND}
	hwdb? ( sys-apps/hwids )
	openrc?
	(
		>=sys-fs/udev-init-scripts-16
		!<sys-apps/openrc-0.9.9
	)
	!sys-apps/coldplug
	!<sys-fs/lvm2-2.02.45
	!sys-fs/device-mapper
	!<sys-fs/udev-init-scripts-16
	!<sys-kernel/dracut-017-r1
	!<sys-kernel/genkernel-3.4.25"

# Required kernel options
CONFIG_CHECK="~DEVTMPFS ~HOTPLUG ~INOTIFY_USER ~NET ~PROC_FS ~SIGNALFD ~SYSFS
	~!SYSFS_DEPRECATED ~!SYSFS_DEPRECATED_V2 ~BLK_DEV_BSG"

## Checks current kernel version
#
# Return values:
#	0 -- Kernel is new enough
#	1 -- Kernel is too old
#
udev_check_kv() {
	kernel_is -ge ${KV_MIN//./ }
	return $?
}

pkg_setup() {
	echo
	get_version && udev_check_kv

	case $? in
		0)	einfo "Your current kernel version (${KV_FULL}) is new enough to run ${P}."
			;;
		1)	eerror "Your current kernel version (${KV_FULL}) is too old to run ${P}."
			eerror "You need at least ${KV_MIN}."
			;;
	esac

	KV_FULL_SRC=${KV_FULL}

	echo
	get_running_version && udev_check_kv

	case $? in
		0)	einfo "Your running kernel version (${KV_FULL}) is new enough to run ${P}."
			;;
		1)	eerror "Your running kernel version (${KV_FULL}) is too old!"
			eerror "You need at least ${KV_MIN}."
			;;
	esac
	
	echo
	check_extra_config
}

src_prepare() {
	# Change rules back to group uucp instead of dialout for now
	sed -e 's/GROUP="dialout"/GROUP="uucp"/g' \
		-i rules/*.rules \
		|| die "failed to change group dialout to uucp"
	
	if [[ ${PV} == "9999" ]]; then
		if [[ ! -e configure ]]; then
			eautoreconf
		else
			check_default_rules
			elibtoolize
		fi
	fi
}

src_configure() {
	econf \
		--prefix="${EPREFIX}" \
		--with-rootprefix="${EPREFIX}" \
		--bindir="${EPREFIX}"/sbin \
		--sysconfdir="${EPREFIX}"/etc \
		--libexecdir="${EPREFIX}"/"$(get_libdir)" \
		--libdir="${EPREFIX}"/usr/"$(get_libdir)" \
		--with-rootlibdir="${EPREFIX}"/"$(get_libdir)" \
		--includedir="${EPREFIX}"/usr/include \
		--datarootdir="${EPREFIX}"/usr/share \
		--docdir="${EPREFIX}"/usr/share/doc/"${PF}" \
		--with-pci-ids-path="${EPREFIX}"/usr/share/misc/pci.ids \
		--with-usb-ids-path="${EPREFIX}"/usr/share/misc/usb.ids \
		--enable-logging \
		$(use_with selinux) \
		$(use_enable debug) \
		$(use_enable doc) \
		$(use_enable static-libs static) \
		$(use_enable keymap) \
		$(use_enable floppy) \
		$(use_enable gudev) \
		$(use_enable introspection)
}

src_install() {
	emake DESTDIR="${D}" install
	
	# Install documentation
	dodoc COPYING README INSTALL 

	# Install gentoo-specific rules
	insinto /"$(get_libdir)"/udev/rules.d
	doins "${FILESDIR}"/40-gentoo.rules
}

pkg_postinst() {
	# Create rundir for udev
	mkdir -p "${ROOT}"/run

	ewarn "Libudev version may be updated, please consider running"
	ewarn "revdep-rebuild."
}
