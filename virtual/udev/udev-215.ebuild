# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2

DESCRIPTION="Virtual for udev implementation"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="acl gudev hwdb introspection keymap selinux static-libs"

DEPEND=""
RDEPEND="|| (
		sys-fs/udev[gudev?,hwdb?,keymap?,selinux?,static-libs?]
		sys-fs/eudev[gudev?,hwdb?,keymap?,selinux?,static-libs?]
		)"
