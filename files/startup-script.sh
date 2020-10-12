#! /bin/bash
#
# Copyright 2020 Open Infrastructure Services, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##
# This script configures a Debian 10 instance as a Github actions-runner.

set -u

error() {
  if [[ -n "${STARTUP_SCRIPT_STDLIB_INITIALIZED:-}" ]]; then
    stdlib::error "$@"
  else
    echo "$@" >&2
  fi
}

info() {
  if [[ -n "${STARTUP_SCRIPT_STDLIB_INITIALIZED:-}" ]]; then
    stdlib::info "$@"
  else
    echo "$@"
  fi
}

debug() {
  if [[ -n "${STARTUP_SCRIPT_STDLIB_INITIALIZED:-}" ]]; then
    stdlib::debug "$@"
  else
    echo "$@"
  fi
}

cmd() {
  if [[ -n "${STARTUP_SCRIPT_STDLIB_INITIALIZED:-}" ]]; then
    DEBUG=1 stdlib::cmd "$@"
  else
    "$@"
  fi
}

# Start the auto-healing process by stopping hc-health
setup_status_api() {
  # Install status API
  local status_file status_unit1 status_unit2
  status_file="$(mktemp)"
  echo '{status: "OK", host: "'"${HOSTNAME}"'"}' > "${status_file}"
  install -v -o 0 -g 0 -m 0755 -d /var/lib/google/status
  install -v -o 0 -g 0 -m 0644 "${status_file}" /var/lib/google/status/status.json

  status_unit1="$(mktemp)"
  cat <<EOF>"${status_unit1}"
[Unit]
Description=health-check
After=network.target

[Service]
Type=simple
User=nobody
Group=nobody
Restart=always
WorkingDirectory=/var/lib/google/status
ExecStart=@/usr/bin/python3 "/usr/bin/python3" "-m" "http.server" "9000"
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
  install -m 0644 -o 0 -g 0 "${status_unit1}" /etc/systemd/system/health-check.service

  systemctl daemon-reload
  systemctl restart health-check.service
  systemctl enable health-check.service
}

# Install a oneshot systemd service to trigger a kernel panic.
# Intended for gcloud compute ssh <instance> -- sudo systemctl start kpanic --no-block
install_kpanic_service() {
  local tmpfile
  tmpfile="$(mktemp)"
  cat <<EOF>"${tmpfile}"
[Unit]
Description=Triggers a kernel panic 1 second after being started

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 1; echo c > /proc/sysrq-trigger'
RemainAfterExit=true
EOF
  install -m 0644 -o 0 -g 0 "${tmpfile}" /etc/systemd/system/kpanic.service
  systemctl daemon-reload
}

# Workaround https://github.com/GoogleCloudPlatform/guest-agent/issues/76 to
# prevent `systemctl restart google-guest-agent` from breaking policy routing.
workaround_guest_agent() {
  local tmpfile
  tmpfile="$(mktemp)"
  cat <<"EOF" >"$tmpfile"
#! /bin/bash
# Avoid the call to remove_old_addr, which calls ip addr del, which causes policy routes to be deleted.
# See https://github.com/GoogleCloudPlatform/guest-agent/issues/76
logmessage "/etc/dhcp/dhclient-down-hooks - Workaround for https://github.com/GoogleCloudPlatform/guest-agent/issues/76"
exit_with_hooks 0
EOF
  install -o 0 -g 0 -m 0755 "$tmpfile" /etc/dhcp/dhclient-down-hooks
  rval=$?
  rm -f "$tmpfile"
  return $rval
}

main() {
  local jobs

  info "BEGIN: Policy Routing Startup for ${HOSTNAME}"

  if ! setup_status_api; then
    error "Failed to configure status API endpoints, aborting."
    exit 2
  fi

  if ! workaround_guest_agent; then
    error "Failed to work around https://github.com/GoogleCloudPlatform/guest-agent/issues/76"
    exit 4
  fi

  # Nice to have packages
  yum -y install docker

  return 0
}

# To make this easier to execute interactively during development, load stdlib
# from the metadata server.  When the instance boots normally stdlib will load
# this script via startup-script-custom.  As a result, only use this function
# outside of the normal startup-script behavior, e.g. when developing and
# testing interactively.
load_stdlib() {
  local tmpfile
  tmpfile="$(mktemp)"
  if ! curl --silent --fail -H 'Metadata-Flavor: Google' -o "${tmpfile}" \
    http://metadata/computeMetadata/v1/instance/attributes/startup-script; then
    error "Could not load stdlib from metadata instance/attributes/startup-script"
    return 1
  fi

  # shellcheck disable=1090
  source "${tmpfile}"
}

# If the script is being executed directly, e.g. when running interactively,
# initialize stdlib.  Note, when running via the google_metadata_script_runner,
# this condition will be false because the stdlib sources this script via
# startup-script-custom.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  TMPDIR="/tmp/startup"
  [[ -d "${TMPDIR}" ]] || mkdir -p "${TMPDIR}"
  load_stdlib
  stdlib::init
  stdlib::load_config_values
fi

main "$@"

# vim:sw=2
