FROM debian:jessie
MAINTAINER Matt Bentley <mbentley@mbentley.net>

RUN (apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher-ng &&\
  ln -sf /dev/stdout /var/log/apt-cacher-ng/apt-cacher.log &&\
  ln -sf /dev/stderr /var/log/apt-cacher-ng/apt-cacher.err)

VOLUME ["/var/cache/apt-cacher-ng"]
EXPOSE 3142
CMD ["/usr/sbin/apt-cacher-ng","-c","/etc/apt-cacher-ng","pidfile=/var/run/apt-cacher-ng/pid","SocketPath=/var/run/apt-cacher-ng/socket","foreground=1"]
