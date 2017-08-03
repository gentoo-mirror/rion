# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils autotools

DESCRIPTION="Belledonne Communications' language recognition library"
HOMEPAGE="https://savannah.nongnu.org/projects/linphone/"
SRC_URI="http://www.linphone.org/releases/sources/${PN}/${P}.tar.gz"

KEYWORDS="~amd64 ~x86"
SLOT="0"
LICENSE="GPL-3"
IUSE=""

DEPEND="net-libs/bctoolbox"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${P}-0"

src_prepare() {
	default
	eautoreconf
}
