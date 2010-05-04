# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2

inherit eutils multilib pam

JABBER_ETC="/etc/jabber"
JABBER_RUN="/var/run/jabber"
JABBER_SPOOL="/var/spool/jabber"
JABBER_LOG="/var/log/jabber"
JABBER_DOC="/usr/share/doc/${PF}"

DESCRIPTION="The Erlang Jabber Daemon"
HOMEPAGE="http://www.ejabberd.im/"
SRC_URI="http://www.process-one.net/downloads/${PN}/${PV}/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
EJABBERD_MODULES="mod_irc mod_muc mod_proxy65 mod_pubsub"
IUSE="captcha debug ldap odbc pam ssl web zlib ${EJABBERD_MODULES}"

DEPEND=">=net-im/jabber-base-0.01
	>=dev-libs/expat-1.95
	>=dev-lang/erlang-11.2.5[ssl?]
	odbc? ( dev-db/unixODBC )
	ldap? ( =net-nds/openldap-2* )
	ssl? ( >=dev-libs/openssl-0.9.8e )
	captcha? ( media-gfx/imagemagick[truetype,png] )
	zlib? ( sys-libs/zlib )"
RDEPEND="${DEPEND}"

PROVIDE="virtual/jabber-server"

S=${WORKDIR}/${P}/src

src_configure() {
	econf \
		--docdir=/usr/share/doc/"${PF}"/html \
		$(use_enable mod_irc) \
		$(use_enable ldap eldap) \
		$(use_enable mod_muc) \
		$(use_enable mod_proxy65) \
		$(use_enable mod_pubsub) \
		$(use_enable ssl tls) \
		$(use_enable web) \
		$(use_enable odbc) \
		$(use_enable zlib ejabberd_zlib) \
		$(use_enable pam) \
		--enable-user=jabber \
	|| die "econf failed"
}

src_compile() {
	emake $(use debug && echo debug=true ejabberd_debug=true) \
		|| die "compiling ejabberd core failed"
}

src_install() {
	emake \
		DESTDIR="${D}" \
		EJABBERDDIR="${D}/usr/$(get_libdir)/erlang/lib/${P}" \
		ETCDIR="${D}${JABBER_ETC}" \
		LOGDIR="${D}${JABBER_LOG}" \
		SPOOLDIR="${D}${JABBER_SPOOL}" \
		install || die "install failed"

	if use ssl; then
		insinto "/etc/ssl"

		newins "${FILESDIR}"/ssl.cnf ejabberd.cnf \
										|| die "Installing ssl.conf failed"

		exeinto "${JABBER_DOC}/ssl"

		cat "${FILESDIR}"/self-cert-v3.sh | \
			sed -e "s:@SSL_CERT@:${JABBER_ETC}/ssl.pem:" \
				-e "s:@SSL_CONFIG@:/etc/ssl/ejabberd.cnf:" \
					> "${T}"/ssl-cert.sh || die "sed for self-cert.sh failed"

		doexe "${T}/ssl-cert.sh" || die "installing self-cert.sh failed"
	fi

	# Pam helper module permissions
	# http://www.process-one.net/docs/ejabberd/guide_en.html
	if use pam; then
		pamd_mimic_system xmpp auth account || die "Cannot create pam.d file"
		fperms 4750 "/usr/$(get_libdir)/erlang/lib/${P}/priv/bin/epam" \
								|| die "Cannot adjust epam permissions"
	fi

	cd "${WORKDIR}/${P}/doc"
	dodoc "release_notes_${PV%%_rc*}.txt" || die "Installing release_notes failed"
	rm "${D}"/usr/share/doc/"${PF}"/html/*.txt
	chmod -x "${D}"/usr/share/doc/"${PF}"/html/* \
						|| die "Removing executable bit from htmls failed"

	exeinto /usr/sbin

	# set up /usr/sbin/ejabberd wrapper
	cat "${FILESDIR}/ejabberd-wrapper-3.template" \
		| sed	-e "s/\@libdir\@/$(get_libdir)/g" \
				-e "s/\@version\@/${PV}/g" \
				-e "s/\@doc\@/${PF}/g" \
					> "${T}/ejabberd"

	doexe "${T}/ejabberd" || die "Installing ejabberd runscript failed"

	# set up /usr/sbin/ejabberdctl wrapper
	cat "${FILESDIR}/ejabberdctl-wrapper-3.template" \
		| sed	-e "s:\@libdir\@:$(get_libdir):g" \
				-e "s:\@version\@:${PV}:g" \
					> "${T}/ejabberdctl"

	doexe "${T}/ejabberdctl" || die "Installing ejabberctl failed"

	dodir /var/lib/ejabberd
	newinitd "${FILESDIR}/${PN}-2.initd" ${PN} \
								|| die "Cannot install init.d script"
	newconfd "${FILESDIR}/${PN}-2.confd" ${PN} \
								|| die "Cannot install conf.d file"

	# fix up the ssl cert paths in /etc/jabber/ejabberd.cfg to use the cert
	# that would be generated by /etc/jabber/self-cert.sh
	sed -e "s/\/path\/to\/ssl.pem/\/etc\/jabber\/ssl.pem/g" \
				-i "${D}${JABBER_ETC}/ejabberd.cfg" \
					|| die "Cannot set default cert path into ejabberd.cfg"

	# correct path to captcha script in default ejabberd.cfg
	local captcha_path="/usr/$(get_libdir)/erlang/lib/${P}/priv/bin/captcha.sh"
	local captcha_search='\{captcha_cmd,[[:space:]]*".+"\}'
	local captcha_replace="{captcha_cmd, ${captcha_path}}"

	sed -r "s|${captcha_search}|${captcha_replace}|" -i \
				"${D}${JABBER_ETC}/ejabberd.cfg" \
					|| die "Cannot set correct captcha path into ejabberd.cfg"

	# if mod_irc is not enabled, comment out the mod_irc in the default
	# ejabberd.cfg
	if ! use mod_irc; then
		sed -e "s/{mod_irc,/%{mod_irc,/" \
			-i "${D}${JABBER_ETC}/ejabberd.cfg" \
				|| die "Cannot comment out mod_irc module into ejabberd.cfg"
	fi
}

pkg_postinst() {
	elog "For configuration instructions, please see"
	elog "/usr/share/doc/${PF}/html/guide.html, or the online version at"
	elog "http://www.process-one.net/en/projects/ejabberd/docs/guide_en.html"

	if use ssl ; then
		if [ ! -e /etc/jabber/ssl.pem ]; then
			elog "Please edit ${JABBER_DOC}/ssl/ssl.cnf"
			elog "and run ${JABBER_DOC}/ssl/self-cert.sh."
			elog "Ejabberd may refuse to start without an SSL certificate"
		fi
	fi

	if ! use web ; then
		elog "The web USE flag is off, this has disabled the web admin interface."
	fi

	elog '===================================================================='
	elog 'Quick Start Guide:'
	elog '1) Add output of `hostname -f` to /etc/jabber/ejabberd.cfg line 89'
	elog '   {hosts, ["localhost", "thehost"]}.'
	elog '2) Add an admin user to /etc/jabber/ejabberd.cfg line 324'
	elog '   {acl, admin, {user, "theadmin", "thehost"}}.'
	elog '3) Start the server'
	elog '   # /etc/init.d/ejabberd start'
	elog '4) Register the admin user'
	elog '   # /usr/sbin/ejabberdctl register theadmin thehost thepassword'
	elog '5) Log in with your favourite jabber client or using the web admin'
}
