# Bareos File

Follows Bareos's own install instructions as closely as possible: given container limitations.
Initially uses only Bareos distributed community packages [Bareos Community Repository](https://download.bareos.org/current) `Current` variant.

Intended future capability, upon instantiation, is to use the [Official Bareos Subscription Repository](https://download.bareos.com/bareos/release/),
if non-empty subscription credentials are passed by environmental variables.

See: [Decide about the Bareos release to use](https://docs.bareos.org/IntroductionAndTutorial/InstallingBareos.html#decide-about-the-bareos-release-to-use)

Based on opensuse/leap:15.6 as per BareOS instructions:
[SUSE Linux Enterprise Server (SLES), openSUSE](https://docs.bareos.org/IntroductionAndTutorial/InstallingBareos.html#install-on-suse-based-linux-distributions)

Inspired & informed by the many years of Bareos container maintenance done by Marc Benslahdine https://github.com/barcus/bareos, and contributors.

This images' resulting container's /etc/bareos & /var/lib/bareos is intended to be inherited from the same-author bareos-director container.
When used in this way, it provides a Director-local FILE daemon, used to run the default MyCatalog backup job,
which also includes backing up the entirety of /etc/bareos: hence also backing-up all associated daemons config similarly sharing /etc/bareos.

The image is also compatible with independent instantiation: i.e. to create a stand-along Bareos File instance;
non-local/no-shares to/with associated Bareos Directors.

The intention here is to simplifying/containerise a Bareos server set deployment:
i.e. Director/Catalog/Storage/File/WebUI server set

### Host User configuration

This image uses the dockerfile [USER](https://docs.docker.com/reference/dockerfile/#user) directive.
A matching host user:group (by UID & GID) of 105:105 is required on the container host system.

As container to host mapping is via UID:GID only,
it is required to be explicit: enabling mapped volumes' permissions.
In the case of the file daemon only,
the root:bareos user:group is used, but bareos:bareos files are also created,
requiring also a matched host user of bareos.

To create a container matching 'bareos' group (gid=105) execute:
```shell
groupadd --system --gid 105 bareos
```
And to create the matching 'bareos' user (uid=105) in this group, with supplementary groups disk,tape:
```shell
useradd --system --uid 105 --comment "bareos" --home-dir /var/lib/bareos -g bareos --shell /bin/false bareos
```
N.B. in the above, /var/lib/bareos is not required or created on the host.
Note also that the additional secondary group memberships of `-G disk,tape` is only required by the Storage daemon.

## Environmental Variables

Directors contact File daemons with instructions on what files to:
- (Backup) send to an indicated Storage daemon.
- (Restore) request from an indicated Storage deamon.
This password must tally with that held by the Director for this image's resulting container hostname.

- BAREOS_DIR_NAME: If unset defaults to "bareos-dir".
 Tally with Director's 'Name' in /etc/bareos/bareos-dir.d/director/bareos-dir.conf

The following must match with an associated Director's config in /etc/bareos/bareos-dir.d/client/
- BAREOS_FD_NAME:  Defaults to "bareos-fd" if not set; i.e. the default Director-local FILE daemon.
- BAREOS_FD_PASSWORD: Must be set.

## Local Build
- -t tag <name>
- . indicates from-current directory

```
docker build -t bareos-fd .
```

## Run File container

The following assumes:
- We are inheriting /etc/bareos & /var/lib/bareos from an existing same-author Bareos 'Director' container.
- That the Director (named "bareos-dir") is accessible via docker network `bareosnet`.
Assumes local volumes have at least 105:105 host user:group permissions:
- e.g.: `chown 105:105 storage`.
```shell
docker run --name bareos-fd\
 -e BAREOS_FD_NAME='bareos-fd' -e BAREOS_FD_PASSWORD='bareos-fd-pass'\
 -e BAREOS_DIR_NAME='bareos-dir'\
 --volumes-from='bareos-dir'\
 --network=bareosnet bareos-fd
# and to remove
docker remove bareos-fd
```

A stand-alone invocation, without `--volumes-from` or `--network=bareosnet` bareos-dir Director.
```shell
docker run --name bareos-fd\
 -e BAREOS_FD_NAME='bareos-fd' -e BAREOS_FD_PASSWORD='bareos-fd-pass'\
 -e BAREOS_DIR_NAME='bareos-dir'\
 -v ./config:/etc/bareos -v ./data:/var/lib/bareos\
 bareos-fd
```

## Interactive shell

```
docker exec -it bareos-fd sh
```

## BareOS rpm package scriptlet actions

### bareos-filedaemon
```shell
Info: replacing 'XXX_REPLACE_WITH_LOCAL_HOSTNAME_XXX' with '5937ca0a35fc' in /etc/bareos/bareos-fd.d/client/myself.conf
Info: replacing 'XXX_REPLACE_WITH_CLIENT_PASSWORD_XXX' in /etc/bareos/bareos-fd.d/director/bareos-dir.conf
Info: replacing 'XXX_REPLACE_WITH_CLIENT_MONITOR_PASSWORD_XXX' in /etc/bareos/bareos-fd.d/director/bareos-mon.conf
Info: replacing 'XXX_REPLACE_WITH_CLIENT_MONITOR_PASSWORD_XXX' in /etc/bareos/tray-monitor.d/client/FileDaemon-local.conf
```

### bareos-common
This shared package dependency with bareos-directory creates (if non-existent) the following:
(see `rpm -ql bareos-common`)
- bareos:bareos /etc/bareos/bareos-dir.d/{catalog, client, console, counter, director, fileset, job, jobdefs, messages,
 pool, profiloe, schedule, storage, user}  (N.B. all are empty)
- bareos:bareos /etc/bareos/tray-monitor.d (empty)
Along with rpm install (scriptlet) config involving: 
-- /etc/bareos/tray-monitor.d/client/FileDaemon-local.conf
-- password paired with /etc/bareos/bareos-fd.d/director/bareos-mon.conf
- there are also a number of binaries and libraries.

**N.B. this docker images does not currently restore/instantiate:
- the /etc/bareos/bareos-dir.d directories (all empty)
- the /etc/bareos/tray-monitor.d directory (associated with a desktop client install)
For a Bareos client desktop install, it is advised to use a native package from upstream. 