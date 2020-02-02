FROM debian:buster
MAINTAINER Matt Bentley <mbentley@mbentley.net>

RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher-ng cron logrotate s6 rsyslog &&\
  mkdir /var/run/apt-cacher-ng &&\
  chown -R apt-cacher-ng:apt-cacher-ng /var/run/apt-cacher-ng &&\
  echo "PassThroughPattern: .*" >> /etc/apt-cacher-ng/acng.conf &&\
  rm -rf /var/lib/apt/lists/*

COPY s6 /etc/s6
COPY entrypoint.sh /entrypoint.sh

VOLUME ["/var/cache/apt-cacher-ng"]
EXPOSE 3142

ENTRYPOINT ["/entrypoint.sh"]
CMD ["s6-svscan","/etc/s6"]
