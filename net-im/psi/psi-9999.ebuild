# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PLOCALES="be bg ca cs de el en eo es et fa fi fr he hu it ja kk mk nl pl pt_BR pt ru sk sl sr@latin sv sw uk ur_PK vi zh_CN zh_TW"
PLOCALE_BACKUP="en"

inherit git-r3 cmake plocale xdg

DESCRIPTION="Qt XMPP client"
HOMEPAGE="https://psi-im.org"

PSI_URI="https://github.com/psi-im"
PSI_PLUS_URI="https://github.com/psi-plus"
EGIT_REPO_URI="${PSI_URI}/${PN}.git"
PSI_LANGS_URI="${PSI_URI}/psi-l10n.git"
PSI_PLUS_LANGS_URI="${PSI_PLUS_URI}/psi-plus-l10n.git"
EGIT_MIN_CLONE_TYPE="single"
LICENSE="GPL-2 iconsets? ( all-rights-reserved )"
SLOT="0"
#KEYWORDS=""
IUSE="aspell dbus debug doc enchant extras +hunspell iconsets keyring qt6 webengine X"

REQUIRED_USE="
	?? ( aspell enchant hunspell )
	iconsets? ( extras )
"

BDEPEND="
	!qt6? ( dev-qt/linguist-tools:5 )
	qt6? ( dev-qt/qttools:6[linguist] )
	virtual/pkgconfig
	doc? ( app-text/doxygen )
"
DEPEND="
	net-libs/http-parser:=
	net-libs/usrsctp
	sys-libs/zlib[minizip]
	aspell? ( app-text/aspell )
	enchant? ( app-text/enchant:2 )
	hunspell? ( app-text/hunspell:= )
	!qt6? (
		dev-qt/qtconcurrent:5
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtmultimedia:5
		dev-qt/qtnetwork:5
		dev-qt/qtsql:5[sqlite]
		dev-qt/qtsvg:5
		dev-qt/qtwidgets:5
		dev-qt/qtx11extras:5
		dev-qt/qtxml:5
		dbus? ( dev-qt/qtdbus:5 )
		keyring? ( dev-libs/qtkeychain:=[qt5] )
		webengine? (
			dev-qt/qtwebchannel:5
			dev-qt/qtwebengine:5[widgets]
		)
	)
	qt6? (
		>=dev-qt/qtbase-6.6:6[concurrent,dbus?,gui,icu,network,sqlite,widgets,X?,xml]
		>=dev-qt/qtsvg-6.6:6
		>=dev-qt/qtimageformats-6.6:6
		keyring? ( dev-libs/qtkeychain:=[qt6] )
		webengine? (
			>=dev-qt/qtwebchannel-6.6:6
			>=dev-qt/qtwebengine-6.6:6[widgets]
		)

	)
	X? (
		x11-libs/libX11
		x11-libs/libxcb
		x11-libs/libXScrnSaver
	)
"
RDEPEND="${DEPEND}
	!qt6? ( dev-qt/qtimageformats:5 )
	qt6? ( dev-qt/qtimageformats:6 )
"

RESTRICT="test iconsets? ( bindist )"

pkg_setup() {
	MY_PN=psi
	if use extras; then
		MY_PN=psi-plus
		einfo "You're about to build a branded version of Psi called Psi+."
		einfo "Psi+ patches were fully merged to Psi."
		einfo "The only difference is the name and some artwork."

		if use iconsets; then
			ewarn
			ewarn "Some artwork is from open source projects, but some is provided 'as-is'"
			ewarn "and has not clear licensing."
			ewarn "Possibly this build is not redistributable in some countries."
		fi

		EGIT_REPO_URI="${PSI_PLUS_URI}/${MY_PN}-snapshots.git"
	fi
}

src_unpack() {
	git-r3_src_unpack

	unset EGIT_BRANCH EGIT_COMMIT
	EGIT_CHECKOUT_DIR="${S}/iris/3rdparty/qca" \
	EGIT_REPO_URI="${PSI_URI}/qca.git" \
	git-r3_src_unpack

	# fetch translations
	unset EGIT_BRANCH EGIT_COMMIT
	EGIT_REPO_URI=$(usex extras "${PSI_PLUS_LANGS_URI}" "${PSI_LANGS_URI}")
	EGIT_CHECKOUT_DIR="${WORKDIR}/psi-l10n"
	git-r3_src_unpack

	if use iconsets; then
		unset EGIT_BRANCH EGIT_COMMIT
		EGIT_CHECKOUT_DIR="${WORKDIR}/resources" \
		EGIT_REPO_URI="${PSI_URI}/resources.git" \
		git-r3_src_unpack
	fi
}

src_prepare() {
	cmake_src_prepare
	if use iconsets; then
		cp -a "${WORKDIR}/resources/iconsets" "${S}" || die "failed to copy additional iconsets"
	fi
}

src_configure() {
	local mycmakeargs=(
		-DPRODUCTION=OFF
		-DUSE_ASPELL=$(usex aspell)
		-DUSE_ENCHANT=$(usex enchant)
		-DUSE_HUNSPELL=$(usex hunspell)
		-DUSE_DBUS=$(usex dbus)
		-DINSTALL_PLUGINS_SDK=1
		-DUSE_KEYCHAIN=$(usex keyring)
		-DCHAT_TYPE=$(usex webengine webengine basic)
		-DUSE_XSS=$(usex X)
		-DUSE_X11=$(usex X)
		-DPSI_PLUS=$(usex extras)
		-DVERBOSE_PROGRAM_NAME=ON
		-DIRIS_BUNDLED_QCA=ON
		-DQT_DEFAULT_MAJOR_VERSION=$(usex qt6 6 5)
	)
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
	use doc && emake -C doc api_public
}

src_install() {
	cmake_src_install

	# this way the docs will be installed in the standard gentoo dir
	rm "${ED}"/usr/share/${MY_PN}/{COPYING,README.html} || die "doc files set seems to have changed"
	newdoc iconsets/roster/README README.roster
	newdoc iconsets/system/README README.system
	newdoc certs/README README.certs
	dodoc README.html

	use doc && HTML_DOCS=( doc/api/. )
	einstalldocs

	# install translations
	local qtbin=${EPREFIX}/usr/$(get_libdir)/qt$(usex qt6 6 5)/bin
	local mylrelease="$qtbin"/lrelease
	cd "${WORKDIR}/psi-l10n" || die
	insinto /usr/share/${MY_PN}
	install_locale() {
		"${mylrelease}" "translations/${PN}_${1}.ts" || die "lrelease ${1} failed"
		doins "translations/${PN}_${1}.qm"
	}
	plocale_for_each_locale install_locale
}
