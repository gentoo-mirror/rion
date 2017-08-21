# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools

DESCRIPTION="Opensource Implementation of WS-Management - Command line utility"
HOMEPAGE="http://sourceforge.net/projects/openwsman/"
SRC_URI="mirror://sourceforge/project/openwsman/${PN}/${PV}/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test examples static-libs"

CDEPEND="
	net-misc/curl[idn]
	sys-apps/openwsman
	"

RDEPEND="${CDEPEND}"
DEPEND="${CDEPEND}
	test? ( dev-util/cunit )
	"

src_prepare() {
	eautoreconf
	eapply_user
}

src_configure() {
	local myeconfargs=(
		$(use_with test)
		$(use_with examples)
		)
	econf "${myeconfargs[@]}"
}
# TODO patch vconfigure option to work exmaples=yes
