#!/bin/bash

# look for a specific client version of kubectl
function locate_kubectl() {
  local client_version_regex=${1:-"Major:\"1\"\, Minor:\"1\""}

  local which_kubectl=$(which kubectl)
  local opt_kubectl=$(find /opt/kubernetes/platforms/darwin/amd64 -type f -name "kubectl" -print 2>/dev/null | egrep '.*')
  local result='notfound'

  for guess in ${opt_kubectl} ${which_kubectl}; do
    if ${guess} version --client 2>/dev/null | grep -q "${client_version_regex}"; then
      result=${guess}
    fi
  done

  if [ "${result}" = "notfound" ]; then
    echo "ERROR: Could not find kubectl with client version matching regex '${client_version_regex}'" >&2
    exit 1
  else
    echo "${result}"
  fi
}
