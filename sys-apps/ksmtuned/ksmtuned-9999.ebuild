# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit mercurial

DESCRIPTION="Simple script to tune whether and with what vigor ksm searches for dup pages"
HOMEPAGE="https://gitorious.org/ksm-control-scripts"
EHG_REPO_URI="https://andreis.vinogradovs@code.google.com/p/slepnoga.ksmtuned"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_install() {
	dosbin ksmtuned

	newinitd ksm.initd ksm
	newinitd ksmtuned.initd ksmtuned

	newconfd ksm.sysconfig ksm

	insinto /etc
	doins ksmtuned.conf

	dodoc TODO
}
