#!/bin/sh

healtcheck () {
	EXITCODE="0"
	for i in ${SERVICES}
	do
		if ps -ef | grep -v grep | grep ${i} >/dev/null 2>&1
			then
			echo "${i} is running"
		else
			echo "${i} is NOT running"
			EXITCODE="1"
			fi
	done
	exit ${EXITCODE}
}

usercheck () {
	grep "${USERNAME}" /etc/passwd >/dev/null
	if [ $? -ne 0 ]; then
		useradd -m -s /bin/bash -U ${USERNAME}
	fi
	usermod -d ${USER_DIR} ${USERNAME}
}

setup () {
	echo "deb http://http.debian.net/debian ${DEBIAN_VERSION} main non-free contrib" > ${APT_CONFIG_SOURCES} && \
	echo "deb-src http://http.debian.net/debian ${DEBIAN_VERSION} main non-free contrib" >> ${APT_CONFIG_SOURCES} && \
	echo "deb http://security.debian.org/ ${DEBIAN_VERSION}/updates main non-free contrib" >> ${APT_CONFIG_SOURCES} && \
	echo "deb-src http://security.debian.org/ ${DEBIAN_VERSION}/updates main non-free contrib" >> ${APT_CONFIG_SOURCES} && \
	apt-get update && apt-get -y upgrade && \
#
	apt-get install -y openbsd-inetd locales \
	procps gnupg gnupg2 supervisor nano && \
	apt-get -y --force-yes --fix-missing install dpkg-dev debhelper && \
#
	apt-get -y build-dep pure-ftpd && mkdir /tmp/pure-ftpd/ && \
	cd /tmp/pure-ftpd/ && apt-get source pure-ftpd && cd pure-ftpd-* && \
#
	./configure --with-tls --with-ftpwho --with-language=russian && \
	sed -i '/^optflags=/ s/$/ --without-capabilities/g' ./debian/rules && \
#
	dpkg-buildpackage -b -uc && dpkg -i /tmp/pure-ftpd/pure-ftpd-common*.deb && \
#
	dpkg -i /tmp/pure-ftpd/pure-ftpd_*.deb && apt-mark hold pure-ftpd pure-ftpd-common && cd /etc/pure-ftpd/conf/ && \
#
	echo "yes" | tee AntiWarez ChrootEveryone CreateHomeDir CustomerProof Daemonize DontResolve IPV4Only NoAnonymous NoChmod NoRename ProhibitDotFilesRead ProhibitDotFilesWrite && \
	echo "no" | tee AllowAnonymousFXP AllowDotFiles AllowUserFXP AnonymousCanCreateDirs AnonymousCantUpload AnonymousOnly AutoRename BrokenClientsCompatibility CallUploadScript DisplayDotFiles IPV6Only KeepAllFiles LogPID NATmode PAMAuthentication UnixAuthentication VerboseLog && \
	rm -rf /var/lib/apt/lists/* && \
#
	usercheck
}

run () {
	mv /etc/localtime /etc/localtime-old && \
	ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
#
	echo "[supervisord]" >> ${SUPERVISORD_CONFIG} && \
    echo "nodaemon=true" >> ${SUPERVISORD_CONFIG} && \
#
	echo "[program:ftp]" >> ${SUPERVISORD_CONFIG} && \
	echo "command=/usr/sbin/pure-ftpd -c 50 -C 10 -l unix -E -A -j -R -p ${FTP_B_PORT} -S ${FTP_A_PORT}" >> ${SUPERVISORD_CONFIG} && \
	echo "autorestart = true" >> ${SUPERVISORD_CONFIG} && \
#
	usercheck
	echo ${USERNAME}:${PASSWORD} | chpasswd
#
	/usr/bin/supervisord -n
}

for PARAM; do
    $PARAM
done