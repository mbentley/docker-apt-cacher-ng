# rebased/repackaged base image that only updates existing packages
FROM mbentley/debian:bullseye
LABEL maintainer="Matt Bentley <mbentley@mbentley.net>"

RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y apt-cacher-ng ca-certificates cron logrotate s6 rsyslog &&\
  chown -R apt-cacher-ng:apt-cacher-ng /var/run/apt-cacher-ng &&\
  echo 'PassThroughPattern: ^(.*):443$' >> /etc/apt-cacher-ng/acng.conf &&\
  sed -i "s/# ReuseConnections: 1/ReuseConnections: 1/g" /etc/apt-cacher-ng/acng.conf &&\
  sed -i "s#size 10M#size 25M#g" /etc/logrotate.d/apt-cacher-ng &&\
  sed -i '/imklog/s/^/#/' /etc/rsyslog.conf &&\
  rm -rf /var/lib/apt/lists/*

# add image to use for a lazy health check via image
COPY cache.png /usr/share/doc/apt-cacher-ng/cache.png

COPY s6 /etc/s6
COPY entrypoint.sh /entrypoint.sh

VOLUME ["/var/cache/apt-cacher-ng"]
EXPOSE 3142

ENTRYPOINT ["/entrypoint.sh"]
CMD ["s6-svscan","/etc/s6"]
