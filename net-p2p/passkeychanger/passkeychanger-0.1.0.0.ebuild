# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit cmake-utils

DESCRIPTION="Qt4 torrent passkey changer"
HOMEPAGE="http://panter-dsd.github.com/PasskeyChanger"
SRC_URI="https://github.com/panter-dsd/PasskeyChanger/tarball/${PV} -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug"

RDEPEND="dev-qt/qtgui:4"
DEPEND="${RDEPEND}"

src_unpack() {
	default
	mv "${WORKDIR}"/panter-dsd-PasskeyChanger-* "${S}"
}

src_install() {
	dobin "${CMAKE_BUILD_DIR}"/${PN}
}
