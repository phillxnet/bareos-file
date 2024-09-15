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

## Environmental Variables

Directors contact File daemons with instructions on what files to:
- (Backup) send to an indicated Storage daemon.
- (Restore) request from an indicated Storage deamon.
This password must tally with that held by the Director for this image's resulting container hostname.

- BAREOS_DIR_NAME: Tally with Director's 'Name' in /etc/bareos/bareos-dir.d/director/bareos-dir.conf
- BAREOS_FD_PASSWORD: Tally with Director's local 'File/Client' default in /etc/bareos/bareos-dir.d/client/bareos-fd.conf

## Local Build
- -t tag <name>
- . indicates from-current directory

```
docker build -t bareos-file .
```

## Local Run

```
docker run --name bareos-file
# skip entrypoint and run shell
docker run -it --entrypoint sh bareos-file
```

## Interactive shell

```
docker exec -it bareos-file sh
```

## BareOS rpm package scriptlet actions

### bareos-filedaemon
```shell
Info: replacing 'XXX_REPLACE_WITH_LOCAL_HOSTNAME_XXX' with '5937ca0a35fc' in /etc/bareos/bareos-fd.d/client/myself.conf
Info: replacing 'XXX_REPLACE_WITH_CLIENT_PASSWORD_XXX' in /etc/bareos/bareos-fd.d/director/bareos-dir.conf
Info: replacing 'XXX_REPLACE_WITH_CLIENT_MONITOR_PASSWORD_XXX' in /etc/bareos/bareos-fd.d/director/bareos-mon.conf
Info: replacing 'XXX_REPLACE_WITH_CLIENT_MONITOR_PASSWORD_XXX' in /etc/bareos/tray-monitor.d/client/FileDaemon-local.conf
```
