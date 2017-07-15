FROM debian:stretch
MAINTAINER Alexander Shevchenko <kudato@me.com>

ENV DEBIAN_VERSION stretch
ENV DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Moscow

ENV USERNAME www-data
ENV PASSWORD password

ENV FTP_A_PORT 21
ENV FTP_B_PORT 30000:30009

ENV SERVICES ftp

ENV APT_CONFIG_SOURCES /etc/apt/sources.list
ENV SUPERVISORD_CONFIG /etc/supervisor/conf.d/supervisord.conf
ENV USER_DIR /srv

ADD /*.sh /
RUN chmod +x /*.sh && \
#	build & install pure-ftp
	ln -sf /magic.sh /usr/bin/magic && \
	magic setup

HEALTHCHECK --retries=3 --interval=15s --timeout=5s CMD magic healthcheck
ENTRYPOINT ["magic"]
# ->
CMD ["run"]
