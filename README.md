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

## Drop-in configuration

Instead of bind mounting individual config files, you can mount a directory of `*.conf` files (plus any files they reference, like `backends_*` lists) at `/etc/apt-cacher-ng/config.d`:

```
docker run -d \
  --name apt-cacher-ng \
  -p 3142:3142 \
  -v /data/apt-cacher-ng:/var/cache/apt-cacher-ng \
  -v /data/apt-cacher-ng-config.d:/etc/apt-cacher-ng/config.d:ro \
  mbentley/apt-cacher-ng
```

On startup, the files in the top level of `config.d` are symlinked into `/etc/apt-cacher-ng`:

* `*.conf` files are linked as `zzzz-dropin-<name>.conf` so they are loaded after the default config files and override them
* all other files (e.g. `backends_*`) are linked with their original name so relative `file:` references in your `*.conf` files resolve, since apt-cacher-ng looks them up in `/etc/apt-cacher-ng`

For example, with `config.d/backends_docker` containing `https://download.docker.com/linux/debian`, a `config.d/docker.conf` can reference it like any other backends file:

```
Remap-docker: /docker ; file:backends_docker
```

A drop-in is skipped with a warning if a file with the same name already exists in `/etc/apt-cacher-ng` (for example, `backends_debian` and `backends_ubuntu` ship with the image), so drop-ins can't replace the default files. To use a conflicting file anyway, give it a different name or reference it by absolute path (`file:/etc/apt-cacher-ng/config.d/backends_debian`). Add or remove files and restart the container to apply the changes.

### Drop-in permissions

Unlike the rest of `/etc/apt-cacher-ng`, the entrypoint does not change the ownership of anything in `config.d` because it is typically a read-only bind mount and changing ownership would modify the files on the host. Since apt-cacher-ng runs as `PUID`/`PGID` (`0`/`0` by default), the drop-in files must be readable by that user or group. If you set a non-root `PUID`/`PGID`, either make the files world-readable or have them owned by (or group-readable by) that UID/GID:

```
chmod 644 /data/apt-cacher-ng-config.d/*
```

If a drop-in isn't readable by that user, apt-cacher-ng won't be able to load its settings.
