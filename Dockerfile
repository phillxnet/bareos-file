# Rockstor Bareos server set
FROM opensuse/leap:15.6

# For our setup we explicitly use container's root user at '/':
USER root
WORKDIR /

# https://specs.opencontainers.org/image-spec/annotations/
LABEL maintainer="The Rockstor Project <https://rockstor.com>"
LABEL org.opencontainers.image.authors="The Rockstor Project <https://rockstor.com>"
LABEL org.opencontainers.image.description="Bareos File - deploys packages from https://download.bareos.org/"

# We only know if we are COMMUNIT or SUBSCRIPTION at run-time via env vars.
RUN zypper --non-interactive install tar gzip wget iputils strace

# Create bareos group & user within container with set gid & uid.
# Docker host and docker container share uid & gid.
# Pre-empting the bareos packages' installer doing the same, as we need to known gid & uid for host volume permissions.
# We leave bareos home-dir to be created by the package install scriptlets.
RUN groupadd --system --gid 105 bareos
RUN useradd --system --uid 105 --comment "bareos" --home-dir /var/lib/bareos -g bareos --shell /bin/false bareos

RUN <<EOF
# https://docs.bareos.org/IntroductionAndTutorial/InstallingBareos.html#install-on-suse-based-linux-distributions

# ADD REPOS (COMMUNITY OR SUBSCRIPTION)
# https://docs.bareos.org/IntroductionAndTutorial/WhatIsBareos.html#bareos-binary-release-policy
# - Empty/Undefined BAREOS_SUB_USER & BAREOS_SUB_PASS = COMMUNITY 'current' repo.
# -- Community current repo: https://download.bareos.org/current
# -- wget https://download.bareos.org/current/SUSE_15/add_bareos_repositories.sh
# - BAREOS_SUB_USER & BAREOS_SUB_PASS = Subscription rep credentials
# -- Subscription repo: https://download.bareos.com/bareos/release/
# User + Pass entered in the following retrieves the script pre-edited:
# wget https://download.bareos.com/bareos/release/23/SUSE_15/add_bareos_repositories.sh
# or
# wget https://download.bareos.com/bareos/release/23/SUSE_15/add_bareos_repositories_template.sh
# sed edit using BAREOS_SUB_USER & BAREOS_SUB_PASS
if [ ! -f  /etc/bareos/bareos-file-install.control ]; then
  # Retrieve and Run Bareos's official repository config script
  wget https://download.bareos.org/current/SUSE_15/add_bareos_repositories.sh
  sh ./add_bareos_repositories.sh
  zypper --non-interactive --gpg-auto-import-keys refresh
  # File daemon
  zypper --non-interactive install bareos-filedaemon
  # Control file
  touch /etc/bareos/bareos-file-install.control
fi
EOF

# Stash default package config: ready to populare host volume mapping
# https://docs.bareos.org/Configuration/CustomizingTheConfiguration.html#subdirectory-configuration-scheme
RUN ls -la /etc/bareos/bareos-fd.d > /etc/bareos/bareos-fd.d/file-daemon-default-permissions.txt
RUN tar czf bareos-fd-d.tgz /etc/bareos/bareos-fd.d

# For dir-local-file daemon use, i.e. to facilitate the default MyCatalog & bareos config backup job,
# the firt two VOLUME entries must be inherited from the intended local Director, e.g. via `--volumes-from bareos-dir`.
# Volume sharing is not requried for non-local Client instantiations of the Bareos File daemon this image instantiates.
# Config
VOLUME /etc/bareos
# Data/status (working directory)
# Also default Director DB dump/backup file (bareos.sql) location (see FileSet 'Catalog')
VOLUME /var/lib/bareos

# 'Client/File' communications port.
EXPOSE 9102

COPY docker-entrypoint.sh /usr/local/sbin/docker-entrypoint.sh
RUN chmod u+x /usr/local/sbin/docker-entrypoint.sh

# See README.md 'Host User configuration' section.
# The Bareos file daemon differes from all other bareos services by not running bareos:bareos.
# Established from package defaults as per /usr/lib/bareos/scripts/bareos-config-lib.sh
USER root:bareos

# BareOS services have WorkingDirectory=/var/lib/bareos
# https://docs.docker.com/reference/dockerfile/#workdir
# See: /usr/lib/systemd/system/bareos-fd.service
WORKDIR /var/lib/bareos

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/usr/sbin/bareos-fd", "--foreground", "--debug-level", "1" ]
