#!/usr/bin/sh

if [ ! -f /etc/bareos/bareos-file-config.control ]; then
  # Populate host volume map with package defaults from docker build steps:
  tar xfz /bareos-fd-d.tgz --backup=simple --suffix=.before-file-config --strip 2 --directory /etc/bareos
  # if BAREOS_FD_PASSWORD is unset, set from directors bareos-fd.conf via shared /etc/bareos, if found.
  if [ -z "${BAREOS_FD_PASSWORD}" ] && [ -f /etc/bareos/bareos-dir.d/client/bareos-fd.conf ]; then
    # Use Director's local/default 'File/Client': "Password = " found in:
    # /etc/bareos/bareos-dir.d/client/bareos-fd.conf
    # TODO set BAREOS_FD_PASSWORD from directors default bareos-fd.conf for this local File daemon
    echo
  fi
  # if BAREOS_DIR_NAME is unset, set from directors bareos-dir.conf via shared /etc/bareos, if found.
  # Otherwise default to "bareos-dir"
  if [ -z "${BAREOS_DIR_NAME}" ] && [ -f /etc/bareos/bareos-dir.d/director/bareos-dir.conf ]; then
    # Use Director's config "Name = bareos-dir" found in:
    # /etc/bareos/bareos-dir.d/director/bareos-dir.conf
    # TODO set BAREOS_DIR_NAME from directors default bareos-dir.conf config if possible
    echo
  fi

  if [ -z "${BAREOS_DIR_NAME}" ]; then
    BAREOS_DIR_NAME="bareos-dir"
  fi

  if [ -z "${BAREOS_FD_NAME}" ]; then
    BAREOS_FD_NAME="bareos-fd"
  fi

  # Set this File daemon's Name:
  sed -i 's#Name = .*#Name = '\""${BAREOS_FD_NAME}"\"'#' \
    /etc/bareos/bareos-fd.d/client/myself.conf
  # Set this File daemon's authorized director credentials (Name/Password)
  sed -i 's#Name = .*#Name = '\""${BAREOS_DIR_NAME}"\"'#' \
    /etc/bareos/bareos-fd.d/director/bareos-dir.conf
  sed -i 's#Password = .*#Password = '\""${BAREOS_FD_PASSWORD}"\"'#' \
    /etc/bareos/bareos-fd.d/director/bareos-dir.conf
  # Control file
  touch /etc/bareos/bareos-file-config.control
fi

# Run Dockerfile CMD
exec "$@"
