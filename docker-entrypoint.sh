#!/usr/bin/sh

# https://docs.bareos.org/IntroductionAndTutorial/InstallingBareos.html#install-on-suse-based-linux-distributions
# https://docs.bareos.org/IntroductionAndTutorial/WhatIsBareos.html#bareos-binary-release-policy

# ADD REPOS (COMMUNITY OR SUBSCRIPTION)
# Later pick according to variables entered at Rock-on
# - empty = community
# - BareOS subscription credentials = Subscription repository

# Official Bareos Subscription Repository
# - https://download.bareos.com/bareos/release/
# User + Pass entered in the following retrieves the script pre-edited:
# wget https://download.bareos.com/bareos/release/23/SUSE_15/add_bareos_repositories.sh
# or
# wget https://download.bareos.com/bareos/release/23/SUSE_15/add_bareos_repositories_template.sh
# sed edit with BareOS subscription credentials and execute it.

# Community current: https://download.bareos.org/current
# - wget https://download.bareos.org/current/SUSE_15/add_bareos_repositories.sh

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

if [ ! -f /etc/bareos/bareos-file-config.control ]; then
  # if BAREOS_FD_PASSWORD is unset, set from directors bareos-fd.conf via shared /etc/bareos, if found.
  if [ -z "${BAREOS_FD_PASSWORD}" ] && [ -f /etc/bareos/bareos-dir.d/client/bareos-fd.conf ]; then
    # Use Director's local/default 'File/Client': "Password = " found in:
    # /etc/bareos/bareos-dir.d/client/bareos-fd.conf
    # TODO set BAREOS_FD_PASSWORD from directors default bareos-fd.conf for this local File daemon
    echo
  fi
  # if BAREOS_DIR_NAME is unset, set from directors bareos-dir.conf via shared /etc/bareos, if found.
  # Otherwise default to "bareos-dir"
  if [ -z "${BAREOS_DIR_NAME}" ]; then
    if [ -f /etc/bareos/bareos-dir.d/director/bareos-dir.conf ]; then
      # Use Director's config "Name = bareos-dir" found in:
      # /etc/bareos/bareos-dir.d/director/bareos-dir.conf
      # TODO set BAREOS_DIR_NAME from directors default bareos-dir.conf config if possible
      echo
    else
      BAREOS_DIR_NAME="bareos-dir"
    fi
    echo
  fi
  # Set File deamon's associated director credentials (Name/Password)
  sed -i 's#Name = .*#Name = '\""${BAREOS_DIR_NAME}"\"'#' \
    /etc/bareos/bareos-fd.d/director/bareos-dir.conf
  sed -i 's#Password = .*#Password = '\""${BAREOS_FD_PASSWORD}"\"'#' \
    /etc/bareos/bareos-fd.d/director/bareos-dir.conf
  # Control file
  touch /etc/bareos/bareos-file-config.control
fi

# Run Dockerfile CMD
exec "$@"
