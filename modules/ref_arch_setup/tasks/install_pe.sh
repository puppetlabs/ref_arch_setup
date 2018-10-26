#!/usr/bin/env bash

# Install PE:
# First, copy the PE installer tarball and pe_conf file to the node
# Then, execute the task as per the following example:
# bolt task --modulepath modules run 'ref_arch_setup::install_pe pe_tarball_path=puppet-enterprise-2018.1.1-el-7-x86_64.tar.gz pe_conf_path=pe.conf' --nodes bdjshmr8bx75q2a.delivery.puppetlabs.net

execute_command() {
    cmd=$1
    echo "Executing: $cmd"
    eval $cmd
    cmd_exit_code=$?

    # if number of args is 1, check for exit code = 0, otherwise check for exit code = value of second arg
    if [ $# -eq 1 ]
    then
        expected_exit_code=0
    else
        expected_exit_code=$2
    fi
    if [ $cmd_exit_code -ne $expected_exit_code ]
    then
        echo "Command '$1' failed - expected_exit_code: $expected_exit_code, actual_exit_code: $cmd_exit_code"
        exit 1
    fi
}

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
    # exec 5>&1
    # puppet_command_output=$($puppet_command | tee /dev/fd/5; exit ${PIPESTATUS[0]})

    puppet_command_output=$($puppet_command)
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

#check that pe.conf is present
if [ ! -f $PT_pe_conf_path ]; then
  echo "ERROR: Specified pe.conf file not found: $PT_pe_conf_path"
  exit 1
fi

#check that pe tarball is present
if [ ! -f $PT_pe_tarball_path ]; then
  echo "ERROR: Specified pe tarball not found: $PT_pe_tarball_path"
  exit 1
fi

# Install tar using existing package manager if it is not already installed
if [ "" == "`which tar`" ]
then
    echo "Tar Not Found"
    if [ -n "`which apt-get`" ]
    then
        execute_command "apt-get -y install tar"
    elif [ -n "`which yum`" ]
    then
        execute_command "yum -y install tar"
    else
        echo "OS does not have apt-get or yum package manager"
        exit 1
    fi
fi

execute_command "tar -xvf $PT_pe_tarball_path -C /tmp/ref_arch_setup"
# Using -* so we don't have to know the specific version, or parse it from the install path
execute_command "sh /tmp/ref_arch_setup/puppet-enterprise-*/puppet-enterprise-installer -c $PT_pe_conf_path"
# Must run puppet agent twice, see https://puppet.com/docs/pe/2017.3/installing/installing_pe.html#text-mode-installation-options-for-monolithic-installations
execute_puppet_until_idempotent
exit 0
