#!/usr/bin/env bash

# Requires PE with PE-25431, or set $tune_command to pe_tune/lib/puppet_x/puppetlabs/tune.rb version 1.5.0.

# Tune PE (query the local system to define a monolithic infrastructure master node) :
#
# bolt task --modulepath modules run 'ref_arch_setup::tune_pe force=true local=true hiera=/etc/puppetlabs/code/environments/production/data --nodes master.delivery.puppetlabs.net

# Tune PE (use a YAML file to define infrastructure nodes) :
#
# bolt task --modulepath modules run 'ref_arch_setup::tune_pe force=true inventory=/tmp/inventory.yaml hiera=/etc/puppetlabs/code/environments/production/data --nodes master.delivery.puppetlabs.net

execute_command() {
  command=$1
  expected_exit_code=0

  # Optional second parameter: expected_exit_code
  if [ $# -eq 2 ]; then
    expected_exit_code=$2
  fi

  echo "Executing: '$command'"
  eval "$command"
  command_exit_code=$?

  if [ "$command_exit_code" -ne "$expected_exit_code" ]; then
    echo "Command '$command' failed - expected_exit_code: $expected_exit_code, actual_exit_code: $command_exit_code"
    exit 1
  fi
}

# TODO: Move execute_puppet_until_idempotent to its own task?

# Sometimes it takes more than one run ...

execute_puppet_until_idempotent() {
  puppet_command="puppet agent -t"

  # The following could be converted into parameters with defaults ...

  maximum_number_of_puppet_runs=8
  sleep_seconds_when_puppet_run_in_progress=16
  retry_when_success_with_failures=false

  for run in $(seq 1 $maximum_number_of_puppet_runs); do
    echo "Executing: '$puppet_command'"

    # To both capture and output command output ...
    exec 5>&1
    puppet_command_output=$($puppet_command | tee /dev/fd/5; exit "${PIPESTATUS[0]}")
    puppet_exit_code=$?

    if echo "$puppet_command_output" | grep -q "Run of Puppet configuration client already in progress"; then
      puppet_run_in_progress=true
    else
      puppet_run_in_progress=false
    fi

    # 0: The run succeeded with no changes or failures; the system was already in the desired state
    if [ $puppet_exit_code -eq 0 ]; then
      break
    fi

    # 1: The run failed, or wasn't attempted due to another run already in progress.
    if [ $puppet_exit_code -eq 1 ]; then
      if [ "$puppet_run_in_progress" = true ]; then
        echo "Sleeping $sleep_seconds_when_puppet_run_in_progress seconds while waiting for another run already in progress"
        sleep $sleep_seconds_when_puppet_run_in_progress
        continue
      else
        echo "ERROR: '$puppet_command' failed with exit code: $puppet_exit_code"
        exit 1
      fi
    fi

    # 2: The run succeeded, and some resources were changed.
    if [ $puppet_exit_code -eq 2 ]; then
      continue
    fi

    # 4: The run succeeded, and some resources failed.
    if [ $puppet_exit_code -eq 4 ]; then
      if [ "$retry_when_success_with_failures" = true ]; then
        continue
      else
        echo "ERROR: '$puppet_command' failed with exit code: $puppet_exit_code"
        exit 1
      fi
    fi

    # 6: The run succeeded, and included both changes and failures.
    if [ $puppet_exit_code -eq 6 ]; then
      if [ "$retry_when_success_with_failures" = true ] ; then
        continue
      else
        echo "ERROR: '$puppet_command' failed with exit code: $puppet_exit_code"
        exit 1
      fi
    fi
  done
}

# The 'puppet infra' command requires '/opt/puppetlabs/bin' to be in the PATH.
# That is not true immediately after installation: it happens at (next) login.

tune_command="/opt/puppetlabs/bin/puppet-infra tune"
tune_options=""

# Do not enforce minimum system requirements (4 Cores, 8096 MB RAM) for infrastructure hosts.
# Specifying '--force' is required during acceptance testing when using 2 CPU/5 GB RAM systems.

if [ "$PT_force" == "true" ]; then
  tune_options+="--force "
fi

# Use a YAML file to define infrastructure nodes.

if [ ! -z "$PT_inventory" ]; then
  if [ -f "$PT_inventory" ]; then
    tune_options+="--inventory=$PT_inventory "
  else
    echo "ERROR: Specified path to inventory YAML file does not exist: $PT_inventory"
    exit 1
  fi
fi

# Query the local system to define a monolithic infrastructure master node.

if [ "$PT_local" == "true" ]; then
  tune_options+="--local "
fi

# Output optimized settings as Hiera YAML files to the specified directory.

if [ ! -z "$PT_hiera" ]; then
  hiera_parent_directory="$(basename "$(dirname "$PT_hiera")")"
  if [ -d "$hiera_parent_directory" ]; then
    tune_options+="--hiera=$PT_hiera"
  else
    echo "ERROR: Specified path to output Hiera YAML files does not exist: $PT_hiera"
    exit 1
  fi
fi

execute_command "$tune_command $tune_options"

# TODO: Move execute_puppet_until_idempotent to its own task?

execute_puppet_until_idempotent

exit 0
