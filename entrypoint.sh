#!/bin/bash

set -euo pipefail

# set TZ
export TZ
TZ="${TZ:-US/Eastern}"

# set default UID/GID
PUID="${PUID:-0}"
PGID="${PGID:-0}"

# set user and group names
export PUSERNAME="apt-cacher-ng"
export PGROUP="apt-cacher-ng"

# check if root or not
if [ "${PUID}" = 0 ] && [ "${PGID}" = 0 ]
then
  # root
  echo "INFO: user requested to run as root:root (${PUID}:${PGID}), skipping UID/GID management"
else
  # Script to handle user and group creation/modification with conflict resolution
  # Expects environment variables: PUID, PGID, PUSERNAME, PGROUP

  # Function to check if a user exists by UID
  user_exists_by_uid() {
    getent passwd "${1}" >/dev/null 2>&1
  }

  # Function to check if a user exists by username
  user_exists_by_name() {
    getent passwd "${1}" >/dev/null 2>&1
  }

  # Function to check if a group exists by GID
  group_exists_by_gid() {
    getent group "${1}" >/dev/null 2>&1
  }

  # Function to check if a group exists by group name
  group_exists_by_name() {
    getent group "${1}" >/dev/null 2>&1
  }

  # Function to get username by UID
  get_username_by_uid() {
    getent passwd "${1}" | cut -d: -f1
  }

  # Function to get UID by username
  get_uid_by_username() {
    getent passwd "${1}" | cut -d: -f3
  }

  # Function to get group name by GID
  get_groupname_by_gid() {
    getent group "${1}" | cut -d: -f1
  }

  # Function to get GID by group name
  get_gid_by_groupname() {
    getent group "${1}" | cut -d: -f3
  }

  # Validate input parameters
  if [[ -z "${PUID:-}" || -z "${PGID:-}" || -z "${PUSERNAME:-}" || -z "${PGROUP:-}" ]]
  then
    echo "ERROR: Missing required environment variables. Need PUID, PGID, PUSERNAME, and PGROUP"
    exit 1
  fi

  # Validate that PUID and PGID are numeric
  if ! [[ "${PUID}" =~ ^[0-9]+$ ]] || ! [[ "${PGID}" =~ ^[0-9]+$ ]]
  then
    echo "ERROR: PUID and PGID must be numeric values"
    exit 1
  fi

  echo "INFO: Starting user/group management with PUID=${PUID}, PGID=${PGID}, PUSERNAME=${PUSERNAME}, PGROUP=${PGROUP}"

  # Handle group first (since user creation depends on group)
  echo "INFO: Processing group: ${PGROUP} (GID: ${PGID})"

  # Check for group GID conflict
  if group_exists_by_gid "${PGID}"
  then
    EXISTING_GROUP_BY_GID=$(get_groupname_by_gid "${PGID}")
    if [[ "${EXISTING_GROUP_BY_GID}" != "${PGROUP}" ]]
    then
      echo "INFO: GID ${PGID} is used by group '${EXISTING_GROUP_BY_GID}', replacing it"
      groupmod -n "${PGROUP}" "${EXISTING_GROUP_BY_GID}"
    fi
  fi

  # Check for group name conflict or create group
  if group_exists_by_name "${PGROUP}"
  then
    EXISTING_GID_BY_NAME=$(get_gid_by_groupname "${PGROUP}")
    if [[ "${EXISTING_GID_BY_NAME}" != "${PGID}" ]]
    then
      echo "INFO: Group name '${PGROUP}' exists with GID ${EXISTING_GID_BY_NAME}, changing to GID ${PGID}"
      groupmod -g "${PGID}" "${PGROUP}"
    else
      echo "INFO: Group '${PGROUP}' already exists with correct GID ${PGID}"
    fi
  elif ! group_exists_by_gid "${PGID}"
  then
    # Group doesn't exist at all, create it
    echo "INFO: Creating group '${PGROUP}' with GID ${PGID}"
    groupadd -g "${PGID}" "${PGROUP}"
  fi

  # Handle user
  echo "INFO: Processing user: ${PUSERNAME} (UID: ${PUID})"

  # Check for user UID conflict
  if user_exists_by_uid "${PUID}"
  then
    EXISTING_USER_BY_UID=$(get_username_by_uid "${PUID}")
    if [[ "${EXISTING_USER_BY_UID}" != "${PUSERNAME}" ]]
    then
      echo "INFO: UID ${PUID} is used by user '${EXISTING_USER_BY_UID}', replacing it"
      usermod -l "${PUSERNAME}" -g "${PGROUP}" -d "/var/cache/apt-cacher-ng" -s "/usr/sbin/nologin" "${EXISTING_USER_BY_UID}"
    fi
  fi

  # Check for username conflict or create user
  if user_exists_by_name "${PUSERNAME}"
  then
    EXISTING_UID_BY_NAME=$(get_uid_by_username "${PUSERNAME}")
    if [[ "${EXISTING_UID_BY_NAME}" != "${PUID}" ]]
    then
      echo "INFO: Username '${PUSERNAME}' exists with UID ${EXISTING_UID_BY_NAME}, changing to UID ${PUID}"
      usermod -u "${PUID}" -g "${PGROUP}" -d "/var/cache/apt-cacher-ng" -s "/usr/sbin/nologin" "${PUSERNAME}"
    else
      # User exists with correct UID, check if other settings need updating
      USER_INFO=$(getent passwd "${PUSERNAME}")
      CURRENT_GID=$(echo "${USER_INFO}" | cut -d: -f4)
      CURRENT_HOME=$(echo "${USER_INFO}" | cut -d: -f6)
      CURRENT_SHELL=$(echo "${USER_INFO}" | cut -d: -f7)

      if [[ "${CURRENT_GID}" != "${PGID}" ]] || [[ "${CURRENT_HOME}" != "/var/cache/apt-cacher-ng" ]] || [[ "${CURRENT_SHELL}" != "/usr/sbin/nologin" ]]
      then
        echo "INFO: User '${PUSERNAME}' exists with correct UID ${PUID}, updating settings"
        usermod -g "${PGROUP}" -d "/var/cache/apt-cacher-ng" -s "/usr/sbin/nologin" "${PUSERNAME}"
      else
        echo "INFO: User '${PUSERNAME}' exists with correct UID ${PUID} and all settings are correct"
      fi
    fi
  elif ! user_exists_by_uid "${PUID}"
  then
    # User doesn't exist at all, create it
    echo "INFO: Creating user '${PUSERNAME}' with UID ${PUID}"
    useradd -u "${PUID}" -g "${PGROUP}" -d "/var/cache/apt-cacher-ng" -s "/usr/sbin/nologin" "${PUSERNAME}"
  fi

  # Final verification - check actual lines in /etc/passwd and /etc/group
  echo "INFO: Verifying final configuration"

  EXPECTED_PASSWD_LINE="${PUSERNAME}:x:${PUID}:${PGID}::/var/cache/apt-cacher-ng:/usr/sbin/nologin"
  ACTUAL_PASSWD_LINE=$(getent passwd "${PUSERNAME}")

  if [[ "${ACTUAL_PASSWD_LINE}" == "${EXPECTED_PASSWD_LINE}" ]]
  then
    echo "INFO: /etc/passwd entry is correct: ${ACTUAL_PASSWD_LINE}"
  else
    echo "ERROR: /etc/passwd entry mismatch"
    echo "  Expected: ${EXPECTED_PASSWD_LINE}"
    echo "  Actual: ${ACTUAL_PASSWD_LINE}"
    exit 1
  fi

  EXPECTED_GROUP_LINE="${PGROUP}:x:${PGID}:"
  ACTUAL_GROUP_LINE=$(getent group "${PGROUP}")

  if [[ "${ACTUAL_GROUP_LINE}" == "${EXPECTED_GROUP_LINE}" ]]
  then
    echo "INFO: /etc/group entry is correct: ${ACTUAL_GROUP_LINE}"
  else
    echo "ERROR: /etc/group entry mismatch"
    echo "  Expected: ${EXPECTED_GROUP_LINE}"
    echo "  Actual: ${ACTUAL_GROUP_LINE}"
    exit 1
  fi

  echo "INFO: User and group management completed successfully"
fi

# setting permissions on /var/cache/apt-cacher-ng, /var/log/apt-cacher-ng, and /var/run/apt-cacher-ng
echo -n "INFO: Setting permissions on /etc/apt-cacher-ng /var/cache/apt-cacher-ng, /var/log/apt-cacher-ng, and /var/run/apt-cacher-ng..."
chown -R apt-cacher-ng:apt-cacher-ng /etc/apt-cacher-ng /var/cache/apt-cacher-ng /var/log/apt-cacher-ng /var/run/apt-cacher-ng || true
echo -e "done"

# run CMD
echo "INFO: entrypoint complete; executing CMD '${*}'"
exec "${@}"
