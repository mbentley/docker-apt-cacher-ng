# mbentley/apt-cacher-ng

docker image for apt-cacher-ng
based off of debian:trixie / debian:bookworm / debian:bullseye

To pull this image:
`docker pull mbentley/apt-cacher-ng`

## Image Tags

### Multi-arch Tags

The following tags have multi-arch support for `amd64` and `arm64` and will automatically pull the correct tag based on your system's architecture:

* `latest`
* `trixie`
* `bookworm`
* `bullseye`

There are also architecture specific tags if you wish to use an explicit architecture tag:

* `latest-amd64`, `trixie-amd64`
* `latest-arm64`, `trixie-amd64`
* `bookworm-amd64`
* `bookworm-arm64`
* `bullseye-amd64`
* `bullseye-arm64`

### Date Specific Tags

The `latest`, `trixie`, `bookworm`, and `bullseye` tags also have unique manifests that are generated daily.  These are in the format `<tag>-YYYYMMDD` (e.g. - `latest-20220215`) and can be viewed on [Docker Hub](https://hub.docker.com/repository/docker/mbentley/apt-cacher-ng/tags?page=1&ordering=last_updated&name=latest-20).  Each one of these tags will be generated daily and is essentially a point in time snapshot of the `latest` tag's manifest that you can pin to if you wish.  Please note that these tags will remain available on Docker Hub for __6 months__ and will not receive security fixes.  You will need to update to newer tags as they are published in order to get updated images.  If you do not care about specific image digests to pin to, I would suggest just using the `latest`, `trixie`, `bookworm`, or `bullseye` tags.

## Example usage

```
docker run -d \
  --name apt-cacher-ng \
  -p 3142:3142 \
  -e TZ="US/Eastern" \
  -e PUID=0 \
  -e PGID=0 \
  -v /data/apt-cacher-ng:/var/cache/apt-cacher-ng \
  mbentley/apt-cacher-ng
```

To change the UID/GID that apt-cacher-ng itself runs as, set `PUID` and `PGID` to whatever numerical values you wish.

This image runs `apt-cacher-ng`, `cron`, and `rsyslogd` to ensure that apt-cacher-ng functions properly with scheduled jobs and appropriate logging.

In order to configure a host to make use of apt-cacher-ng on a box, you should create a file on the host `/etc/apt/apt.conf` with the following lines:

```
Acquire::http::Proxy "http://<docker-host>:3142";
```

You can also bypass the apt caching server on a per client basis by using the following syntax in your `/etc/apt/apt.conf` file:

```
Acquire::HTTP::Proxy::<repo-url> "DIRECT";
```

For example:

```
Acquire::HTTP::Proxy::get.docker.com "DIRECT";
Acquire::HTTP::Proxy::download.virtualbox.org "DIRECT";
```

Note:  The above assumes that you are mapping port 3142 on the docker host and 3142 is accessible from all machines.

You can also update the /etc/apt-cacher-ng/acng.conf and add one or more `PassThroughPattern` lines to force clients to bypass a repository:

```
PassThroughPattern: get\.docker\.com
PassThroughPattern: download\.virtualbox\.org
```

By default, I've enabled a passthrough pattern for anything using port 443.
