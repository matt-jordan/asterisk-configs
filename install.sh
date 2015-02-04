#!/bin/bash

AST_VERSION=13
AST_TARBALL=asterisk-13.2.0-rc1
PJPROJECT_TARBALL=pjproject-2.3
CLEANUP=0

install_prereqs() {
	echo "*** Installing System Libraries ***"

	PACKAGES="build-essential python-pip vim apache2 ssh ccache"
	PACKAGES="${PACKAGES} libncurses-dev libssl-dev libxml2-dev libsqlite3-dev uuid-dev uuid"
	PACKAGES="${PACKAGES} libspandsp-dev binutils-dev libsrtp-dev libedit-dev libjansson-dev"
	PACKAGES="${PACKAGES} subversion git libxslt1-dev"

	aptitude install -y ${PACKAGES}
}

install_pjproject() {

	if [ ! -d pjproject-${PJPROJECT_TARBALL} ]; then
		echo "*** Grabbing PJPROJECT: ${PJPROJECT_TARBALL} ***"
		# Go ahead and use our github repo. Who knows, maybe
		# we fixed something.
		sudo -u ${USERNAME} wget https://github.com/asterisk/pjproject/archive/${PJPROJECT_TARBALL}.tar.gz
		sudo -u ${USERNAME} tar -zxvf ${PJPROJECT_TARBALL}.tar.gz
	fi

	pushd pjproject-${PJPROJECT_TARBALL}
	sudo -u ${USERNAME} ./aconfigure CFLAGS="-g" --enable-shared --with-external-srtp --prefix=/usr
	sudo -u ${USERNAME} make dep
	sudo -u ${USERNAME} make
	make install
	popd

	if [ ${CLEANUP} -eq 1 ]; then
		echo "    ==> Cleaning up PJPROJECT"
		rm -fr pjproject-${PJPROJECT_TARBALL}
		rm -f ${PJPROJECT_TARBALL}.tar.gz
	fi
}

build_asterisk() {
	if [ ! -d ${AST_TARBALL} ]; then
		echo "*** Grabbing Asterisk: ${AST_TARBALL} ***"
		sudo -u ${USERNAME} wget http://downloads.asterisk.org/pub/telephony/asterisk/${AST_TARBALL}.tar.gz
		sudo -u ${USERNAME} tar -zxvf ${AST_TARBALL}.tar.gz
	fi

	pushd ${AST_TARBALL}
	sudo -u ${USERNAME} ./configure --enable-dev-mode --with-pjproject
	sudo -u ${USERNAME} make menuselect.makeopts

	echo "    ==> Enabling extra sounds"
	sudo -u ${USERNAME} menuselect/menuselect --enable EXTRA-SOUNDS-EN-WAV menuselect.makeopts

	echo "    ==> Disabling app_voicemail; enabling external MWI"
	sudo -u ${USERNAME} menuselect/menuselect --disable app_voicemail menuselect.makeopts
	sudo -u ${USERNAME} menuselect/menuselect --enable res_mwi_external menuselect.makeopts
	sudo -u ${USERNAME} menuselect/menuselect --enable res_stasis_mailbox menuselect.makeopts
	sudo -u ${USERNAME} menuselect/menuselect --enable res_ari_mailboxes menuselect.makeopts

	echo "    ==> Enable debug build options (just in case!)"
	sudo -u ${USERNAME} menuselect/menuselect --enable DONT_OPTIMIZE menuselect.makeopts
	sudo -u ${USERNAME} menuselect/menuselect --enable BETTER_BACKTRACES menuselect.makeopts

	quick_build_asterisk
	popd

	if [ ${CLEANUP} -eq 1 ]; then
		echo "    ==> Cleaning up Asterisk"
		rm -fr ${AST_TARBALL}
		rm -f ${AST_TARBALL}.tar.gz
	fi
}

quick_build_asterisk() {
	sudo -u ${USERNAME} make
	if [ if /usr/sbin/asterisk ] ; then
		make uninstall
	fi

	make install

	chown -R ${USERNAME}:${GROUPNAME} /usr/lib/asterisk
	chown -R ${USERNAME}:${GROUPNAME} /var/lib/asterisk
	chown -R ${USERNAME}:${GROUPNAME} /var/spool/asterisk
	chown -R ${USERNAME}:${GROUPNAME} /var/log/asterisk
	chown -R ${USERNAME}:${GROUPNAME} /var/run/asterisk
	chown -R ${USERNAME}:${GROUPNAME} /etc/asterisk
	chown -R ${USERNAME}:${GROUPNAME} /usr/sbin/asterisk
}

wipe_asterisk_configs() {
	echo "*** Removing old Asterisk configs ***"

	rm -frv /etc/asterisk/*.conf
}

install_asterisk_configs() {
	echo "*** Installing Asterisk configs ***"

	sudo -u ${USERNAME} cp -v asterisk-${AST_VERSION}/*.conf /etc/asterisk/
}

# Option Flags
WIPE_ASTERISK_CONFIGS=0
INSTALL_ASTERISK_CONFIGS=1
INSTALL_ASTERISK=0
USERNAME=asterisk
GROUPNAME=asterisk


while [ "$#" -gt "0" ]; do
	case ${1} in
		-w|--wipe)	WIPE_ASTERISK_CONFIGS=1;;
		-i|--install)	INSTALL_ASTERISK=1;;
		-u|--user)
			case "$2" in
				"") USERNAME=asterisk; shift;;
				*) USERNAME=$2; shift;;
			esac ;;
		-g|--group)
			case "$2" in
				"") GROUPNAME=asterisk; shift;;
				*) GROUPNAME=$2; shift;;
			esac ;;
	esac
	shift
done

echo "Executing as:"
echo "    User: ${USERNAME}"
echo "    Group: ${GROUPNAME}"

if [ ${INSTALL_ASTERISK} -eq 1 ]; then
	install_prereqs
	install_pjproject
	build_asterisk
fi

if [ ${WIPE_ASTERISK_CONFIGS} -eq 1 ]; then
	wipe_asterisk_configs
fi

install_asterisk_configs

echo "*** Done ***"

exit 0
