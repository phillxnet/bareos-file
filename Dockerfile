# Rockstor Bareos server set
FROM opensuse/leap:15.6

# https://specs.opencontainers.org/image-spec/annotations/
LABEL maintainer="The Rockstor Project <https://rockstor.com>"
LABEL org.opencontainers.image.authors="The Rockstor Project <https://rockstor.com>"
LABEL org.opencontainers.image.description="Bareos File - deploys packages from https://download.bareos.org/"

# We only know if we are COMMUNIT or SUBSCRIPTION at run-time via env vars.
RUN zypper --non-interactive install wget iputils

# For dir-local-file daemon use, i.e. to facilitate the default MyCatalog & bareos config backup job,
# the firt two VOLUME entries must be inherited from the intended local Director, e.g. via `--volumes-from bareos-director`.
# Volume sharing is not requried for non-local Client instantiations of the Bareos File daemon this image instantiates.
# Config
VOLUME /etc/bareos
# Data/status (working directory)
# Also default Director DB dump/backup file (bareos.sql) location (see FileSet 'Catalog')
VOLUME /var/lib/bareos

# 'Client/File' communications port.
EXPOSE 9102

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod u+x /docker-entrypoint.sh

# BareOS services have WorkingDirectory=/var/lib/bareos
# /etc/systemd/system/bareos-filedaemon.service

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/bareos-fd -f"]
