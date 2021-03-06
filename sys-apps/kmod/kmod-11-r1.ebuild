# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/kmod/kmod-11.ebuild,v 1.1 2012/11/08 06:41:10 williamh Exp $

EAPI=4

inherit autotools eutils toolchain-funcs libtool

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="git://git.kernel.org/pub/scm/utils/kernel/${PN}/${PN}.git"
	inherit git-2
else
	SRC_URI="mirror://kernel/linux/utils/kernel/kmod/${P}.tar.xz"
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
fi

DESCRIPTION="library and tools for managing linux kernel modules"
HOMEPAGE="http://git.kernel.org/?p=utils/kernel/kmod/kmod.git"

LICENSE="LGPL-2"
SLOT="0"
IUSE="debug doc lzma man static-libs +tools zlib"

# Upstream does not support running the test suite with custom configure flags.
# I was also told that the test suite is intended for kmod developers.
# So we have to restrict it.
# See bug #408915.
RESTRICT="test"

RDEPEND="!sys-apps/module-init-tools
	!sys-apps/modutils
	lzma? ( app-arch/xz-utils )
	zlib? ( >=sys-libs/zlib-1.2.6 )" #427130
DEPEND="${RDEPEND}
	doc? ( dev-util/gtk-doc )
	lzma? ( virtual/pkgconfig )
	man? ( dev-libs/libxslt )
	zlib? ( virtual/pkgconfig )"

src_prepare()
{
	if [ ! -e configure ]; then
		if use doc; then
			gtkdocize --copy --docdir libkmod/docs || die
		else
			touch libkmod/docs/gtk-doc.make
		fi
		eautoreconf
	else
		elibtoolize
	fi
}

src_configure()
{
	econf \
		--bindir=${EPREFIX}/sbin \
		--libdir=${EPREFIX}/usr/$(get_libdir) \
		--with-rootlibdir=${EPREFIX}/$(get_libdir) \
		$(use_enable static-libs static) \
		$(use_enable tools) \
		$(use_enable debug) \
		$(use_enable man manpages) \
		$(use_enable doc gtk-doc) \
		$(use_with lzma xz) \
		$(use_with zlib)
}

src_install()
{
	default
	prune_libtool_files

	if use tools; then
		local cmd
		for cmd in depmod insmod lsmod modinfo modprobe rmmod; do
			dosym /sbin/kmod /sbin/${cmd}
		done
		# Compability symlink(s):
		# These are both hardcoded in the Linux kernel source tree wrt #426698
		dosym /sbin/kmod /sbin/depmod
		dosym /sbin/kmod /sbin/modprobe
	fi

	cat <<-EOF > "${T}"/usb-load-ehci-first.conf
	softdep uhci_hcd pre: ehci_hcd
	softdep ohci_hcd pre: ehci_hcd
	EOF

	insinto /etc/modprobe.d
	doins "${T}"/usb-load-ehci-first.conf #260139
}
