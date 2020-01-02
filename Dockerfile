FROM debian:buster
MAINTAINER Matt Bentley <mbentley@mbentley.net>

RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher-ng cron logrotate supervisor rsyslog &&\
  mkdir /var/run/apt-cacher-ng &&\
  chown -R apt-cacher-ng:apt-cacher-ng /var/run/apt-cacher-ng

COPY supervisord.conf /etc/supervisord.conf

ENV TZ="US/Eastern"

VOLUME ["/var/cache/apt-cacher-ng"]
EXPOSE 3142
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
