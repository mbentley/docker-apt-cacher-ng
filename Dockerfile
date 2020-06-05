FROM debian:buster
MAINTAINER Matt Bentley <mbentley@mbentley.net>

RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher-ng cron logrotate s6 rsyslog &&\
  mkdir /var/run/apt-cacher-ng &&\
  chown -R apt-cacher-ng:apt-cacher-ng /var/run/apt-cacher-ng &&\
  echo "PassThroughPattern: .*" >> /etc/apt-cacher-ng/acng.conf &&\
  sed -i "s#size 10M#size 100M#g" /etc/logrotate.d/apt-cacher-ng &&\
  rm -rf /var/lib/apt/lists/*

# add image to use for a lazy health check via image
COPY cache.png /usr/share/doc/apt-cacher-ng/cache.png

COPY s6 /etc/s6
COPY entrypoint.sh /entrypoint.sh

VOLUME ["/var/cache/apt-cacher-ng"]
EXPOSE 3142

ENTRYPOINT ["/entrypoint.sh"]
CMD ["s6-svscan","/etc/s6"]
