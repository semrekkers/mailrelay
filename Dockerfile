FROM debian:buster-slim
LABEL maintainer="Sem Rekkers <rekkers.sem@gmail.com>"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
    rsyslog=8.1901.0-1 \
    postfix=3.4.5-1 \
    postfix-pgsql=3.4.5-1 \
    dovecot-core=1:2.3.4.1-5+deb10u1 \
    dovecot-pgsql=1:2.3.4.1-5+deb10u1 \
    dovecot-lmtpd=1:2.3.4.1-5+deb10u1 \
    dovecot-pop3d=1:2.3.4.1-5+deb10u1 \
    opendkim=2.11.0~alpha-12 \
    opendkim-tools=2.11.0~alpha-12 \
    libopendbx1-pgsql=1.4.6-13+b1 \
    && rm -rf /var/lib/apt/lists/*

COPY mailrelay.sh /usr/local/bin/
ENTRYPOINT [ "mailrelay.sh" ]
EXPOSE 25 465 587 995
